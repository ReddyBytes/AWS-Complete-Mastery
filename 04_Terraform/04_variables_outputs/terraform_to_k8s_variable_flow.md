# Variable Flow: Terraform → Kubernetes Pod

Imagine a chef preparing a meal in a restaurant kitchen. The manager (Terraform) writes the recipe card specifying ingredients and quantities, hands it to the kitchen dispatcher (Kubernetes), who pins portions of the card on boards visible to every cook station (ConfigMap), locks away sensitive spice blends in a locked cabinet only certain cooks can access (Secret), and tells each cook their station number when they start their shift (environment variable in the pod spec). The cooks — your running containers — never see the full recipe card. They only get exactly what they need to do their job.

That entire chain — from manager to container — is what this guide explains.

---

## The Full Variable Journey

```
┌─────────────────────────────────────────────────────────────────────┐
│                    VARIABLE FLOW: END TO END                        │
│                                                                     │
│  terraform.tfvars / env vars / Vault                                │
│         │                                                           │
│         ▼                                                           │
│  Terraform variables.tf                                             │
│  (var.db_password, var.app_env, var.replica_count)                  │
│         │                                                           │
│         ▼                                                           │
│  Terraform resources: kubernetes_config_map, kubernetes_secret,     │
│  kubernetes_deployment  (via Kubernetes provider or helm_release)   │
│         │                                                           │
│         ▼                                                           │
│  Kubernetes API → etcd                                              │
│  ConfigMap (plaintext)   Secret (base64-encoded at rest)            │
│         │                         │                                 │
│         ▼                         ▼                                 │
│  Pod Spec ─── env[].valueFrom.configMapKeyRef                       │
│           ─── env[].valueFrom.secretKeyRef                          │
│           ─── volumeMounts → /etc/config/db_host                    │
│                                                                     │
│         ▼                                                           │
│  Container process: reads os.environ["DB_HOST"]                     │
│                     reads /etc/secrets/db_password                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Stage 1 — Terraform Variables: The Source of Truth

Terraform is where you declare what the infrastructure needs. Variables are the contract between your configuration and the outside world.

```hcl
# variables.tf
variable "app_environment" {
  type        = string
  description = "dev, staging, or prod"
}

variable "db_password" {
  type      = string
  sensitive = true   # ← Terraform will not print this in plan output
}

variable "replica_count" {
  type    = number
  default = 2
}

variable "app_config" {
  type = map(string)
  default = {
    log_level    = "info"
    feature_flag = "enabled"
    timeout_ms   = "5000"
  }
}
```

**Where do the actual values come from?**

```
Priority (highest wins):
  1. Command line:         terraform apply -var="app_environment=prod"
  2. .auto.tfvars file:    prod.auto.tfvars (auto-loaded)
  3. terraform.tfvars:     terraform.tfvars in working directory
  4. TF_VAR_ env vars:     export TF_VAR_db_password="secret123"
  5. default in variable:  default = "dev"
```

Industry practice: `terraform.tfvars` is gitignored. CI/CD pipelines inject values via `TF_VAR_*` environment variables from a secrets manager (AWS Secrets Manager, HashiCorp Vault, GitHub Actions secrets).

```
# In CI/CD pipeline (GitHub Actions example):
env:
  TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
  TF_VAR_app_environment: prod
```

---

## Stage 2 — Terraform Outputs: Passing Values Between Modules

Outputs are how one Terraform module hands values to another — or to an external system.

```hcl
# outputs.tf (from an EKS or RDS module)
output "db_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "RDS endpoint for application config"
}

output "redis_host" {
  value = aws_elasticache_cluster.main.cache_nodes[0].address
}
```

The consuming module reads these as data:

```hcl
# In a kubernetes-manifests module that runs after the infra module:
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "my-tf-state"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  db_host = data.terraform_remote_state.infra.outputs.db_endpoint
}
```

**This is how infra-generated values (RDS endpoint, Redis host, ELB DNS) flow into your Kubernetes configuration.** You never hardcode these — they are outputs from one Terraform run consumed as inputs to the next.

---

## Stage 3 — ConfigMaps: Non-Sensitive Configuration

A **ConfigMap** stores key-value pairs of plaintext configuration. Think of it as an `/etc/config` folder, versioned and managed by Kubernetes.

```hcl
# Terraform creates the ConfigMap
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = "production"
  }

  data = {
    # Non-sensitive values — fine to store as plaintext
    APP_ENV      = var.app_environment             # "prod"
    LOG_LEVEL    = var.app_config["log_level"]     # "info"
    DB_HOST      = local.db_host                   # from RDS output
    REDIS_HOST   = local.redis_host
    TIMEOUT_MS   = var.app_config["timeout_ms"]    # "5000"
    FEATURE_FLAG = var.app_config["feature_flag"]  # "enabled"
  }
}
```

The equivalent Kubernetes YAML (what Terraform generates and applies):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  APP_ENV: prod
  LOG_LEVEL: info
  DB_HOST: mydb.cluster-xxxxx.us-east-1.rds.amazonaws.com:5432
  REDIS_HOST: redis.xxxxx.cache.amazonaws.com
  TIMEOUT_MS: "5000"
  FEATURE_FLAG: enabled
```

**Rule: ConfigMaps are for anything you'd put in a `.env.prod` file that you could check into git without concern.**

---

## Stage 4 — Secrets: Sensitive Configuration

A **Secret** stores base64-encoded values. Important: base64 is encoding, not encryption. Kubernetes Secrets at rest are only as secure as your etcd encryption configuration and RBAC rules.

```hcl
# Terraform creates the Secret
resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "app-secrets"
    namespace = "production"
  }

  # Terraform auto-encodes values to base64
  data = {
    DB_PASSWORD   = var.db_password          # ← marked sensitive in variables.tf
    API_KEY       = var.external_api_key
    JWT_SECRET    = var.jwt_secret
  }

  type = "Opaque"
}
```

**Where does the actual secret value come from in production?**

```
Option A: Vault + Terraform Vault Provider
  - Vault stores the secret
  - Terraform reads it: data "vault_generic_secret" "db" { path = "secret/prod/db" }
  - Passes to kubernetes_secret.data

Option B: AWS Secrets Manager + External Secrets Operator
  - Secret lives in AWS Secrets Manager
  - ExternalSecret CRD syncs it to a Kubernetes Secret automatically
  - Terraform creates the ExternalSecret manifest

Option C: Sealed Secrets (Bitnami)
  - Encrypted YAML is safe to commit to git
  - Controller decrypts it in-cluster
  - Terraform applies the SealedSecret manifest
```

In practice, **Option B (External Secrets Operator)** is the industry standard for AWS-based Kubernetes clusters. The secret never passes through Terraform state.

---

## Stage 5 — Pod Spec: Getting Values Into Containers

The pod spec is where Kubernetes injects the values from ConfigMaps and Secrets into the container's environment.

```hcl
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "web-app"
    namespace = "production"
  }

  spec {
    replicas = var.replica_count

    template {
      spec {
        container {
          name  = "web-app"
          image = "my-app:${var.image_tag}"

          # ── Method 1: Individual env vars from ConfigMap ──────────
          env {
            name = "APP_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "APP_ENV"
              }
            }
          }

          # ── Method 2: Load ALL keys from ConfigMap as env vars ────
          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          # ── Method 3: Secret value as env var ────────────────────
          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "DB_PASSWORD"
              }
            }
          }

          # ── Method 4: Secret mounted as a file ───────────────────
          volume_mount {
            name       = "secrets-vol"
            mount_path = "/etc/secrets"
            read_only  = true
          }
        }

        # Secret volume definition
        volume {
          name = "secrets-vol"
          secret {
            secret_name = kubernetes_secret.app_secrets.metadata[0].name
          }
        }
      }
    }
  }
}
```

---

## Stage 6 — Inside the Container: Reading the Values

The container sees configuration through two interfaces — environment variables and the filesystem.

**Reading environment variables** (works for all languages):

```python
# Python
import os

db_host     = os.environ["DB_HOST"]          # from ConfigMap
db_password = os.environ["DB_PASSWORD"]       # from Secret
app_env     = os.environ.get("APP_ENV", "dev")  # with fallback
timeout_ms  = int(os.environ["TIMEOUT_MS"])   # parse type explicitly
```

```go
// Go
import "os"

dbHost    := os.Getenv("DB_HOST")
dbPassword := os.Getenv("DB_PASSWORD")
```

```javascript
// Node.js
const dbHost     = process.env.DB_HOST;
const dbPassword = process.env.DB_PASSWORD;
```

**Reading mounted files** (preferred for secrets — avoids env var exposure):

```python
# Python — reading secret from mounted file
with open("/etc/secrets/DB_PASSWORD") as f:
    db_password = f.read().strip()   # ← .strip() removes trailing newline
```

```
/etc/secrets/
├── DB_PASSWORD      ← each key in the Secret becomes a file
├── API_KEY
└── JWT_SECRET
```

**Reading structured config files** (for complex configuration):

```hcl
# In Terraform — store a full config file in a ConfigMap
resource "kubernetes_config_map" "app_config" {
  data = {
    "config.yaml" = yamlencode({
      database = {
        host    = local.db_host
        port    = 5432
        name    = var.db_name
        pool    = { min = 2, max = 10 }
      }
      cache = {
        host = local.redis_host
        ttl  = 300
      }
    })
  }
}
```

```python
# In the container — parse the mounted config file
import yaml

with open("/etc/config/config.yaml") as f:
    config = yaml.safe_load(f)

db_host = config["database"]["host"]
db_pool_max = config["database"]["pool"]["max"]
```

---

## The Four Injection Methods Compared

```
┌─────────────────────┬──────────────────┬─────────────────┬─────────────────┐
│ Method              │ Source           │ How container   │ Best for        │
│                     │                  │ reads it        │                 │
├─────────────────────┼──────────────────┼─────────────────┼─────────────────┤
│ env from ConfigMap  │ ConfigMap key    │ os.environ[]    │ Simple string   │
│                     │                  │                 │ settings        │
├─────────────────────┼──────────────────┼─────────────────┼─────────────────┤
│ envFrom ConfigMap   │ All ConfigMap    │ os.environ[]    │ Bulk load many  │
│                     │ keys             │                 │ settings        │
├─────────────────────┼──────────────────┼─────────────────┼─────────────────┤
│ env from Secret     │ Secret key       │ os.environ[]    │ Passwords (risk:│
│                     │                  │                 │ visible in `ps`)│
├─────────────────────┼──────────────────┼─────────────────┼─────────────────┤
│ volume-mounted      │ Secret or        │ file I/O        │ Passwords, TLS  │
│ file                │ ConfigMap        │ /etc/secrets/   │ certs, SSH keys │
└─────────────────────┴──────────────────┴─────────────────┴─────────────────┘
```

**Security note:** Environment variables are visible via `kubectl exec -- env` and `/proc/1/environ` inside the container. For high-sensitivity secrets, always prefer volume-mounted files.

---

## Helm: The Abstraction Layer

In most production teams, you do not write raw Kubernetes manifests. You use **Helm charts** — parameterized templates. Terraform drives Helm via the `helm_release` resource.

```
Terraform vars → helm_release.set values → Helm chart templates → Kubernetes manifests
```

```hcl
resource "helm_release" "app" {
  name       = "web-app"
  chart      = "./charts/web-app"
  namespace  = "production"

  # Helm values — these map to chart templates
  set {
    name  = "replicaCount"
    value = var.replica_count
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  set_sensitive {
    name  = "config.dbPassword"   # ← set_sensitive keeps it out of plan output
    value = var.db_password
  }

  # Or pass a whole values file rendered from a template
  values = [
    templatefile("${path.module}/values.yaml.tpl", {
      environment = var.app_environment
      db_host     = local.db_host
      replica_count = var.replica_count
    })
  ]
}
```

The Helm chart template then maps these values into the Kubernetes resources:

```yaml
# chart/templates/deployment.yaml
env:
  - name: APP_ENV
    value: {{ .Values.config.appEnv }}
  - name: DB_HOST
    value: {{ .Values.config.dbHost }}
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: app-secrets
        key: DB_PASSWORD
```

---

## Industry Patterns

**Pattern 1 — Infra state → App config (two-tier Terraform)**

```
Tier 1: infra/ module
  - Creates RDS, ElastiCache, EKS
  - Writes outputs to S3 state

Tier 2: k8s-config/ module
  - Reads infra outputs via terraform_remote_state
  - Creates ConfigMaps and helm_releases with those values
  - Never re-computes infra — only reads its outputs
```

**Pattern 2 — External Secrets Operator (recommended for secrets)**

```
AWS Secrets Manager ←→ ExternalSecret CRD ←→ Kubernetes Secret
                                ↑
                        Terraform creates
                        the ExternalSecret
                        manifest

Benefits:
- Secrets never touch Terraform state file
- Auto-rotation: Secret syncs when AWS secret changes
- Audit trail in AWS CloudTrail
```

**Pattern 3 — Vault Agent Injector**

```
Pod starts → Init container runs vault agent
           → Vault agent authenticates with Vault
           → Writes secrets to shared volume /vault/secrets/
           → Main container reads from /vault/secrets/db_password
```

Terraform manages the Vault policies and roles; the pod handles its own secret retrieval at startup.

---

## Common Mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Hardcoding db_host in ConfigMap | Breaks when RDS is recreated | Use `terraform_remote_state` output |
| Storing passwords in ConfigMap | Secret visible in `kubectl get cm -o yaml` | Always use Secret or External Secrets |
| Forgetting `.strip()` when reading file | Trailing newline breaks connection strings | Always `f.read().strip()` |
| Base64-encoding value before passing to `kubernetes_secret` | Double-encoded — Terraform auto-encodes | Pass raw string to `kubernetes_secret.data` |
| Large binary config in env var | Env var size limit (~32KB in Linux) | Mount as file via ConfigMap volume |
| Using `envFrom` with two ConfigMaps that have the same key | Second one silently wins | Always use individual `env.valueFrom` when key names may collide |
| Committing `terraform.tfvars` with secrets | Secret in git history forever | Add to `.gitignore`, use `TF_VAR_*` in CI |

---

## The Full Picture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│  AWS Secrets Manager / Vault                                            │
│       │                                                                 │
│       ▼                                                                 │
│  TF_VAR_db_password (CI env var)                                        │
│       │                                                                 │
│       ▼                                                                 │
│  Terraform Plan/Apply                                                   │
│   ├── var.db_password (sensitive)                                       │
│   ├── local.db_host = remote_state.outputs.db_endpoint                 │
│   └── var.app_environment = "prod"                                      │
│       │                                                                 │
│       ├─→ kubernetes_config_map "app-config"                           │
│       │      DB_HOST=xxx.rds.amazonaws.com                             │
│       │      APP_ENV=prod                                               │
│       │      LOG_LEVEL=info                                             │
│       │                                                                 │
│       ├─→ kubernetes_secret "app-secrets"           OR ExternalSecret  │
│       │      DB_PASSWORD=<base64>                      syncs from AWS  │
│       │      API_KEY=<base64>                                           │
│       │                                                                 │
│       └─→ kubernetes_deployment "web-app"                              │
│              envFrom: app-config                                        │
│              env[DB_PASSWORD].secretKeyRef: app-secrets                 │
│              volumeMount: /etc/secrets → app-secrets                   │
│                                                                         │
│  Container runtime                                                      │
│   os.environ["DB_HOST"]      → "xxx.rds.amazonaws.com"                 │
│   os.environ["APP_ENV"]      → "prod"                                  │
│   os.environ["DB_PASSWORD"]  → "secret123"  (or read from file)        │
│   open("/etc/secrets/API_KEY").read() → "sk-..."                        │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Navigation

**Related:**
- [Variables and Outputs](./variables.md) — Terraform variable basics
- [Outputs](./outputs.md) — Cross-module output passing
- [Locals](./locals.md) — Computed intermediate values
- [EKS on AWS](../../03_AWS/10_containers/eks.md) — Cluster provisioning
