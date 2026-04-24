# Helm Deep Dive — The Package Manager for Kubernetes

Deploying a real application to Kubernetes without Helm means writing and maintaining ten or more separate YAML files — a Deployment, a Service, an Ingress, a ConfigMap, a Secret, a ServiceAccount, maybe a HorizontalPodAutoscaler, and more. Every time you deploy to a new environment, you copy those files, search-and-replace the namespace, the image tag, the replica count, and the resource limits. You do this by hand. You get it wrong. You forget to update one file. Two environments drift apart silently.

Helm exists because this pattern is unsustainable at scale.

---

## 1. What Helm Is and Why It Exists

Think of Helm as a cookie cutter. The cutter itself is the **chart** — a reusable template with slots for every value that changes between environments. The dough is your Kubernetes cluster. Each time you stamp the cutter down, you get the same shape, but you can vary the size, the thickness, the ingredients. You don't redraw the cutter every time. You just change the parameters.

Before Helm, teams managed "raw YAML" releases: dozens of files duplicated per environment, no rollback story, no install/upgrade lifecycle. Helm introduced three ideas that solved this:

1. **Templating** — write your YAML once, use Go template syntax to inject values
2. **Release management** — Helm tracks every install as a named release, with version history
3. **Packaging** — bundle all your YAML into a single tarball (`.tgz`) that can be versioned and distributed

**Helm 3** (current major version) removed the server-side component (Tiller) that was the security nightmare of Helm 2. Helm 3 is purely client-side, storing release state as Kubernetes Secrets in the same namespace as the release.

```
WITHOUT HELM                          WITH HELM
─────────────────────────────         ─────────────────────────────────
deployment-dev.yaml                   my-app/
deployment-staging.yaml                 ├── Chart.yaml
deployment-prod.yaml                    ├── values.yaml
service-dev.yaml                        ├── values-staging.yaml
service-staging.yaml                    ├── values-prod.yaml
service-prod.yaml                       └── templates/
ingress-dev.yaml                              ├── deployment.yaml
ingress-staging.yaml                          ├── service.yaml
ingress-prod.yaml                             └── ingress.yaml
configmap-dev.yaml
...18 more files                      helm install myapp ./my-app -f values-prod.yaml
```

---

## 2. Chart Structure

A Helm **chart** is a directory with a specific layout. Every file has a defined purpose. Nothing is arbitrary.

```
my-app/
├── Chart.yaml           ← chart identity and metadata
├── values.yaml          ← default values (the "base" config)
├── values-prod.yaml     ← environment-specific overrides (not standard, by convention)
├── templates/
│   ├── deployment.yaml  ← Kubernetes Deployment manifest (templated)
│   ├── service.yaml     ← Kubernetes Service manifest (templated)
│   ├── ingress.yaml     ← Kubernetes Ingress manifest (templated)
│   ├── configmap.yaml   ← ConfigMap manifest (templated)
│   ├── _helpers.tpl     ← named templates (partials, reused across manifests)
│   └── NOTES.txt        ← post-install message printed to terminal
├── charts/              ← subcharts / dependencies (downloaded by helm dep update)
└── .helmignore          ← files to exclude from the chart package (like .gitignore)
```

**templates/** is where your Kubernetes manifests live. They are Go template files — valid YAML when rendered, but with `{{ }}` substitution markers before rendering.

**_helpers.tpl** starts with an underscore. Helm ignores underscore-prefixed files as direct Kubernetes manifests but makes their named templates available to all other templates in the chart. This is where shared logic lives.

**NOTES.txt** is also a Go template. After `helm install`, Helm renders this file and prints it to stdout. Use it to print access instructions, URLs, or next steps.

**charts/** starts empty. When you run `helm dependency update`, Helm downloads the declared dependency charts as `.tgz` files into this directory. You typically `.gitignore` this folder and regenerate it in CI.

**.helmignore** follows the same syntax as `.gitignore`. Useful for excluding `README.md`, test fixtures, or editor files from the packaged chart.

---

## 3. Chart.yaml

`Chart.yaml` is the identity card of your chart. Helm reads it first and uses it for version tracking, dependency resolution, and display.

```yaml
apiVersion: v2                    # ← always v2 for Helm 3 charts
name: my-app                      # ← chart name (lowercase, no spaces)
version: 1.4.2                    # ← chart version (SemVer — this is the CHART version, not the app)
appVersion: "2.1.0"               # ← the version of the APPLICATION being packaged (informational)
description: "Payment service for the checkout platform"
type: application                 # ← "application" (deployable) or "library" (templates only, not installable)

dependencies:
  - name: postgresql               # ← the chart name in the repo
    version: "12.x.x"             # ← version constraint
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled  # ← only include if values.postgresql.enabled == true
  - name: redis
    version: "17.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

Key distinctions:

- **version** is the chart version. Bump this when you change anything in the chart (templates, defaults, structure). Follows SemVer strictly.
- **appVersion** is informational. It records the version of the software the chart deploys. It is just a string — Helm does not use it for logic, but it appears in `helm list` output.
- **type: library** charts contain only `_helpers.tpl`-style named templates and cannot be installed directly. They exist to be depended on by other charts as a shared template library.

---

## 4. values.yaml — The Configuration Contract

`values.yaml` is the contract between the chart author and the chart user. Every knob that can be turned goes here with a sane default. The user overrides only what differs from the default.

Think of `values.yaml` as the spec sheet for a car. The factory sets defaults — silver paint, manual windows, no sunroof. You walk in and say "I want red paint and a sunroof." You don't rewrite the entire spec; you override the two things you care about.

```yaml
# Image configuration
image:
  repository: my-org/payment-service   # ← Docker image name
  tag: "latest"                         # ← image tag (override in prod with a real SHA)
  pullPolicy: IfNotPresent

# Replica count
replicaCount: 2

# Service configuration
service:
  type: ClusterIP
  port: 8080

# Ingress
ingress:
  enabled: false                        # ← disabled by default; prod overrides to true
  host: ""
  annotations: {}

# Resource limits
resources:
  limits:
    cpu: "500m"
    memory: "256Mi"
  requests:
    cpu: "100m"
    memory: "128Mi"

# Environment variables (list of name/value pairs)
env:
  - name: LOG_LEVEL
    value: "info"
  - name: PORT
    value: "8080"

# Subchart toggles
postgresql:
  enabled: false

redis:
  enabled: false
```

**Nested objects** keep related config grouped and readable. A flat list of keys at the top level becomes unmaintainable for anything beyond a toy chart.

**Lists** (like `env`) are used where order matters or where multiple items of the same shape exist.

Values flow into templates as `.Values.<path>`. So `image.tag` becomes `{{ .Values.image.tag }}` in a template. The nesting mirrors the YAML nesting exactly.

---

## 5. Helm Templating Language (Go Templates)

Go templates use `{{ }}` delimiters. Helm adds a large function library on top of the standard Go template functions, primarily from the **Sprig** library. The result is expressive enough to handle nearly any Kubernetes manifest variation.

The analogy: Go templates are like a mail-merge system for YAML. You write the letter once (the template), define the slots (the `{{ }}` markers), and merge with a data set (the values file). The output is a stack of personalized letters — your rendered Kubernetes manifests.

### Value References

```yaml
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
#                    ↑                             ↑
#         nested key from values.yaml     another nested key
```

The dot (`.`) is the **current context**. At the top level of a template, the context is the entire Helm data object — it includes `.Values`, `.Release`, `.Chart`, `.Files`, `.Capabilities`.

### Built-in Objects

```yaml
name: "{{ .Release.Name }}-payment"   # ← .Release.Name = the name given at helm install
namespace: "{{ .Release.Namespace }}" # ← the namespace Helm is installing into
labels:
  chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"  # ← from Chart.yaml
  managed-by: "{{ .Release.Service }}"              # ← always "Helm"
```

The full built-in objects:

```
.Release.Name        ← name given at install (e.g., "my-app-prod")
.Release.Namespace   ← target namespace
.Release.IsInstall   ← true on first install, false on upgrade
.Release.IsUpgrade   ← true on upgrade
.Release.Service     ← always "Helm"
.Chart.Name          ← from Chart.yaml
.Chart.Version       ← chart version from Chart.yaml
.Chart.AppVersion    ← appVersion from Chart.yaml
.Values              ← the merged values object
.Files               ← access to non-template files in the chart
.Capabilities        ← Kubernetes API versions available in the cluster
```

### Conditionals

```yaml
{{- if .Values.ingress.enabled }}    # ← only render this block if ingress.enabled is truthy
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-ingress
{{- end }}                           # ← end the if block
```

The `{{-` and `-}}` variants **strip whitespace** (including newlines) before or after the tag. This matters because Kubernetes YAML is whitespace-sensitive and extra blank lines from conditional blocks can cause parse errors.

### Loops

```yaml
env:
{{- range .Values.env }}             # ← iterate over the env list from values.yaml
  - name: {{ .name }}                # ← inside range, "." is the current list element
    value: {{ .value | quote }}      # ← quote wraps the value in double quotes (safe for strings)
{{- end }}
```

You can also range over maps:

```yaml
{{- range $key, $val := .Values.annotations }}
  {{ $key }}: {{ $val | quote }}
{{- end }}
```

### Named Template Reuse with `include`

```yaml
metadata:
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
#            ↑ named template    ↑  ↑
#            defined in _helpers.tpl |
#                                   pass current context through
#                                       ↑
#                                       nindent 4: add newline + 4-space indent
#                                       (critical — include returns a string, not YAML)
```

### `toYaml | nindent` — The Most Common Pattern

When a value in `values.yaml` is a YAML structure (like `resources`, `annotations`, `affinity`), you cannot use `{{ .Values.resources }}` directly — that would print Go's internal representation. You need to serialize it back to YAML:

```yaml
resources:
  {{- toYaml .Values.resources | nindent 2 }}
#  ↑                              ↑
#  serialize the Go map to YAML   add newline + 2-space indent to align under "resources:"
```

Without `nindent`, the rendered YAML would start on the same line as `resources:` and fail to parse. This is the single most common source of whitespace bugs in Helm templates.

### Required Validation

```yaml
image: "{{ .Values.image.repository }}:{{ required "Must set image.tag" .Values.image.tag }}"
#                                         ↑
#                                         if image.tag is empty or not set,
#                                         helm install fails with this error message
```

Use `required` for values that have no safe default — things like AWS account IDs, domain names, or secret names that must be provided explicitly.

---

## 6. _helpers.tpl — The Partial Template File

`_helpers.tpl` is where you define **named templates**: reusable blocks of text that multiple manifests can include. Without it, you copy-paste the same label block into every manifest. When the label format changes, you update ten files instead of one.

The analogy: named templates are like a stamp. You carve the design once, ink it, and apply it wherever needed. Change the stamp, every impression changes.

```
{{/*
Expand the name of the chart.
*/}}
{{- define "my-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
Truncates to 63 characters because Kubernetes DNS label limits.
*/}}
{{- define "my-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}    # ← avoid "my-app-my-app" duplication
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels — applied to every resource for consistent identification.
*/}}
{{- define "my-app.labels" -}}
helm.sh/chart: {{ include "my-app.chart" . }}
{{ include "my-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — used in matchLabels and Service selectors.
MUST be stable across upgrades (never add/remove from this set after initial deploy).
*/}}
{{- define "my-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Chart name + version string for the helm.sh/chart label.
*/}}
{{- define "my-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
```

How these are used in `deployment.yaml`:

```yaml
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "my-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-app.selectorLabels" . | nindent 8 }}
```

The `selectorLabels` block is intentionally separate from `labels`. The selector is used by Kubernetes to match pods to a Deployment. If you ever change the selector labels on an existing Deployment, Kubernetes will reject the update — you'd need to delete and recreate. Keeping it minimal and stable avoids this foot-gun.

---

## 7. Values Inheritance and Override Chain

Helm merges values in a strict precedence order. Values defined later in the chain win over values defined earlier. Think of it as layers of paint — each layer covers the one beneath it, and the final color is whatever the top layer shows.

```
values.yaml  (lowest precedence — the defaults)
    |
    v overridden by
    |
-f values-staging.yaml  (environment-specific file)
    |
    v overridden by
    |
-f values-prod.yaml  (can stack multiple -f flags, last wins)
    |
    v overridden by
    |
--set key=value  (highest precedence — CLI wins over everything)
```

**values.yaml** — the base defaults. Every key that can ever be set should appear here, even if set to an empty string or `false`. This documents what the chart accepts.

```yaml
# values.yaml
replicaCount: 1
image:
  tag: "latest"
ingress:
  enabled: false
  host: ""
```

**values-prod.yaml** — only the keys that differ from the base. No need to repeat unchanged values.

```yaml
# values-prod.yaml
replicaCount: 3
image:
  tag: "a3f2c91"               # ← specific SHA for production, never "latest"
ingress:
  enabled: true
  host: "payments.example.com"
```

**--set** — for one-off overrides, CI pipeline injection, or secrets you cannot commit to files.

```bash
helm upgrade my-app ./my-app \
  -f values.yaml \
  -f values-prod.yaml \
  --set image.tag="a3f2c91" \          # ← override a single scalar
  --set-string "annotations.commit=abc123" \  # ← force string (avoids 0x1a being parsed as hex)
  --set "env[0].value=debug"           # ← override a list element by index
```

Merging behavior for nested objects: `-f` does a **deep merge** — it only overwrites the keys you specify, leaving other keys at their default. `--set` is additive for new keys, overriding for existing ones. Neither wipes out an entire nested object unless you explicitly set every key.

---

## 8. Chart Dependencies (Subcharts)

Few production services are truly standalone. A payment service needs a database. A job processor needs a queue. Rather than telling every team to deploy PostgreSQL separately and then point their app at it, Helm lets you declare **dependencies** — other charts that Helm will install alongside yours.

The analogy: think of a dependency as a meal kit subscription. The main dish is your app chart. The sides — PostgreSQL, Redis — come pre-packaged with exactly the version you requested, delivered at the same time. You specify what sides you want in the order form (Chart.yaml). The kit arrives assembled.

### Declaring Dependencies in Chart.yaml

```yaml
dependencies:
  - name: postgresql
    version: "12.5.6"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled    # ← only pull in if values.postgresql.enabled is true
    alias: db                        # ← optional: reference as "db" in values instead of "postgresql"

  - name: redis
    version: "17.3.14"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

### Downloading Dependencies

```bash
helm dependency update ./my-app
# ← reads Chart.yaml, contacts the repos, downloads matching .tgz files into charts/
# ← also creates/updates Chart.lock with exact resolved versions
```

`Chart.lock` is the equivalent of `package-lock.json` — it records the exact versions resolved, so future installs are deterministic. Commit `Chart.lock`, not `charts/`.

### Passing Values to Subcharts

Subchart values are namespaced under the chart name (or alias) in your `values.yaml`:

```yaml
# values.yaml
postgresql:
  enabled: true
  auth:
    database: payments_db
    username: payments_user
    password: ""               # ← never commit; override with --set or a Secret

redis:
  enabled: true
  architecture: standalone
  auth:
    enabled: false             # ← disable auth for internal cluster use
```

The `postgresql.enabled: true` key matches the `condition: postgresql.enabled` in Chart.yaml — so the subchart is included. Set it to `false` in environments that use an external RDS instance instead.

### Common Bitnami Dependencies

```
Bitnami Chart         Use Case
─────────────────     ──────────────────────────────────
postgresql            Relational database
redis                 Cache, session store, job queue
kafka                 Event streaming
mongodb               Document store
elasticsearch         Search index
rabbitmq              Message broker
```

---

## 9. Helm Commands Cheatsheet

```
INSTALL AND MANAGE RELEASES
────────────────────────────────────────────────────────────────────────

helm install <release-name> <chart> [flags]
  helm install my-app ./my-app -f values-prod.yaml --namespace prod --create-namespace

helm upgrade <release-name> <chart> [flags]
  helm upgrade my-app ./my-app -f values-prod.yaml
  helm upgrade --install my-app ./my-app       # ← install if not exists, upgrade if exists

helm uninstall <release-name>
  helm uninstall my-app --namespace prod

helm rollback <release-name> [revision]
  helm rollback my-app 3                       # ← roll back to revision 3
  helm rollback my-app                         # ← roll back to previous revision

INSPECT RELEASES
────────────────────────────────────────────────────────────────────────

helm list                                      # ← all releases in current namespace
helm list --all-namespaces                     # ← all releases across all namespaces
helm list -f "my-app"                          # ← filter by name

helm status <release-name>                     # ← current state of a release
helm history <release-name>                    # ← revision history with timestamps and status

DEBUGGING AND VALIDATION
────────────────────────────────────────────────────────────────────────

helm template <release-name> <chart> [flags]
  helm template my-app ./my-app -f values-prod.yaml > rendered.yaml
  # ← renders templates to stdout WITHOUT connecting to Kubernetes
  # ← essential for debugging: see exactly what Kubernetes would receive

helm lint <chart>
  helm lint ./my-app                           # ← validates template syntax and chart structure
  helm lint ./my-app -f values-prod.yaml       # ← lint with specific values

helm get values <release-name>
  helm get values my-app                       # ← show user-supplied values for a live release
  helm get values my-app --all                 # ← show computed values (defaults + overrides)

helm get manifest <release-name>               # ← show the rendered manifests for a live release

PACKAGING AND DISTRIBUTION
────────────────────────────────────────────────────────────────────────

helm package <chart-dir>
  helm package ./my-app                        # ← creates my-app-1.4.2.tgz

helm push <package> <oci-registry>
  helm push my-app-1.4.2.tgz oci://123456789.dkr.ecr.us-east-1.amazonaws.com/helm-charts

helm pull <chart-ref>
  helm pull oci://123456789.dkr.ecr.us-east-1.amazonaws.com/helm-charts/my-app --version 1.4.2
```

---

## 10. Helm Repositories

Before OCI registries, Helm charts were distributed via **HTTP chart repositories** — a server that hosts an `index.yaml` file cataloguing available charts and their download URLs. This still works and is widely used.

Think of a Helm repository like an app store. The store (repo) lists available packages (charts) with version information. You add the store to your device once, then browse and install packages by name.

### Classic HTTP Repositories

```bash
# Add a repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add cert-manager https://charts.jetstack.io

# Update the local index (like apt-get update)
helm repo update

# Search for charts
helm search repo postgresql                  # ← search across all added repos
helm search repo bitnami/postgresql          # ← search specific repo

# Pull (download without installing)
helm pull bitnami/postgresql --version 12.5.6

# Install directly from repo
helm install my-db bitnami/postgresql --version 12.5.6 -f db-values.yaml
```

**Artifact Hub** (artifacthub.io) is the public index of Helm chart repositories — the equivalent of DockerHub for charts. It indexes thousands of charts from dozens of publishers and shows you the `helm repo add` command for each.

### OCI Registries (Helm 3.8+)

OCI (Open Container Initiative) registries — the same infrastructure that stores Docker images — can also store Helm charts as OCI artifacts. This simplifies infrastructure: one registry for both images and charts.

```bash
# Authenticate to ECR (AWS)
aws ecr get-login-password --region us-east-1 \
  | helm registry login --username AWS --password-stdin \
    123456789.dkr.ecr.us-east-1.amazonaws.com

# Push a packaged chart
helm package ./my-app
helm push my-app-1.4.2.tgz oci://123456789.dkr.ecr.us-east-1.amazonaws.com/helm-charts

# Pull and install from OCI
helm install my-app \
  oci://123456789.dkr.ecr.us-east-1.amazonaws.com/helm-charts/my-app \
  --version 1.4.2 \
  -f values-prod.yaml
```

OCI chart references use the `oci://` scheme instead of a repo alias. There is no `helm repo add` step for OCI — you reference the full URI directly.

---

## 11. Helm with Terraform

Terraform can manage Helm releases as infrastructure resources using the `helm_release` resource from the `hashicorp/helm` provider. This is covered in depth in `terraform_to_k8s_variable_flow.md`. The short version:

```hcl
resource "helm_release" "payment_service" {
  name       = "payment-service"
  chart      = "./charts/my-app"       # ← local chart path or repository chart
  namespace  = "prod"

  values = [
    file("values.yaml"),
    file("values-prod.yaml"),
  ]

  set {
    name  = "image.tag"
    value = var.image_tag              # ← inject from Terraform variable
  }
}
```

The key advantage: Terraform can pass outputs from infrastructure resources (RDS endpoint, Redis host, IAM role ARN) directly into Helm values via `set` blocks, creating a single coherent deployment that provisions infrastructure and deploys the application in one plan.

---

## 12. Helm vs Kustomize

Helm and Kustomize both solve the "multiple environments, shared base YAML" problem. They take fundamentally different approaches.

```
HELM                                    KUSTOMIZE
────────────────────────────────────    ────────────────────────────────────
Templating engine (Go templates)        Pure YAML overlays (no templating)
Requires learning template syntax       Reads standard Kubernetes YAML
Manages releases (install/rollback)     No release concept — just kubectl apply
Packages charts for distribution        Not packaged — overlay directories
Values files drive variation            Patches and overlays drive variation
Handles complex conditional logic       Limited to structural patches
Excellent for off-the-shelf charts      Excellent for first-party K8s configs
Subchart dependencies                   No dependency mechanism
```

**When to use Helm:**
- You are packaging software for others to consume (open source, internal platform)
- You need rollback, release history, and version pinning
- You depend on third-party charts (Bitnami PostgreSQL, cert-manager, ingress-nginx)
- Your manifests have significant conditional variation between environments

**When to use Kustomize:**
- You manage internal first-party K8s manifests with minor per-environment differences
- You want to apply patches to a vendor chart you cannot modify directly
- You prefer plain YAML with no template syntax
- You are already using `kubectl apply -k` in a GitOps workflow

**Combining both:** A common pattern is Helm for third-party dependencies (run `helm template` to render to plain YAML) and Kustomize to apply environment-specific patches on top of the rendered output. ArgoCD and FluxCD support both natively.

---

## 13. Testing Helm Charts

A chart that renders without errors does not mean the manifests are correct, complete, or that the deployed application works. Testing at multiple levels catches different failure modes.

### helm lint

The first gate. Validates chart structure and template syntax without connecting to Kubernetes.

```bash
helm lint ./my-app                          # ← check for obvious errors
helm lint ./my-app -f values-prod.yaml      # ← lint with specific values (catches missing required values)
helm lint ./my-app --strict                 # ← promote warnings to errors
```

### helm template

Render to stdout and inspect. Pipe through `kubectl --dry-run` for schema validation.

```bash
helm template my-app ./my-app -f values-prod.yaml \
  | kubectl apply --dry-run=server -f -
# ← renders the chart and sends to Kubernetes API server for validation
# ← API server validates against live CRDs and admission webhooks
# ← nothing is actually applied
```

### helm test

After `helm install`, you can run test pods defined in the chart. Test pods are Jobs or Pods with the annotation `helm.sh/hook: test`. Helm runs them, waits for completion, and reports pass/fail.

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-app.fullname" . }}-test-connection"
  annotations:
    helm.sh/hook: test                  # ← marks this as a test resource
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
spec:
  restartPolicy: Never
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "my-app.fullname" . }}:{{ .Values.service.port }}']
```

```bash
helm test my-app --namespace prod
```

### chart-testing (ct)

The `chart-testing` CLI (`ct`) is the standard CI tool for Helm charts. It installs and tests every changed chart in a repository, using `helm lint`, `helm install`, and `helm test` in sequence.

```bash
ct lint --config ct.yaml                     # ← lint all changed charts
ct install --config ct.yaml                  # ← install + test all changed charts in a kind cluster
```

### helm-unittest

A Helm plugin for unit testing individual templates in isolation — without a running Kubernetes cluster. You write test files in YAML describing expected template output for given values.

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
helm unittest ./my-app
```

```yaml
# tests/deployment_test.yaml
suite: deployment tests
templates:
  - deployment.yaml
tests:
  - it: should set replica count from values
    set:
      replicaCount: 5
    asserts:
      - equal:
          path: spec.replicas
          value: 5
  - it: should use the correct image tag
    set:
      image.tag: "abc123"
    asserts:
      - matchRegex:
          path: spec.template.spec.containers[0].image
          pattern: ":abc123$"
```

---

## 14. Common Mistakes

```
MISTAKE                             ROOT CAUSE                          FIX
────────────────────────────────    ────────────────────────────────    ───────────────────────────────────────
Forgetting nindent on multi-line    include/toYaml returns a string.    Always pipe: toYaml .Values.x | nindent N
values; renders on wrong indent     Without nindent, first line is
line and fails YAML parse.          on the wrong indent level.

Wrong quote handling for            Unquoted string values that look    Pipe through | quote for strings; use
values like "true", "123", "null".  like YAML booleans/numbers are      toYaml for structured values. Never
Kubernetes receives wrong type.     interpreted by YAML parser, not     rely on YAML implicit typing.
                                    passed as strings.

Subcharts not downloading.          Forgot to run                       Run helm dependency update before
templates/ references subchart      helm dependency update. charts/      helm install/upgrade. Add to CI.
values but charts/ is empty.        directory is empty.                 Commit Chart.lock, not charts/.

Values not passed to subchart.      Subchart values must be nested      Use the subchart name (or alias) as
Top-level values have no effect     under the subchart name key in      the top-level key: postgresql.auth.x
on the subchart.                    values.yaml.                        not auth.x.

{{- if .Values.x }} renders         Missing else branch causes          Use {{- if .Values.x }}...{{- else
blank block when false, causing     empty YAML key with no value.       }}...{{- end }} or structure
invalid YAML.                                                           conditionals to emit nothing at all.

Using .Release.Name alone as        Two charts installed to same        Always prefix resource names:
a resource name.                    namespace with same release         {{ include "chart.fullname" . }}
                                    name would collide.                 which combines Release.Name + Chart.Name

Modifying selectorLabels after      Kubernetes Deployments do not       Never add/remove from selectorLabels
initial deploy.                     allow selector changes. Update      after first install. Design them
                                    is rejected with error.             upfront and treat as immutable.

helm upgrade without --reuse-       --set values from previous          Use -f values files for persistence,
values on --set values.             install are not persisted. New      not --set. Or use --reuse-values
                                    upgrade uses defaults for any       (with caution — can pick up stale state).
                                    key not in -f files.

Templating {{ .Values.x }} in       NOTES.txt renders after install     This is fine for NOTES.txt. In templates,
a string context without quote.     so missing values show as           use quote or default "" .Values.x
                                    empty string, not an error.         to avoid rendering empty strings to YAML.

Large values.yaml with no           Users must read all values to       Structure values.yaml with comments,
comments or documentation.          understand intent. Difficult        section headers, and explicit defaults.
                                    to use without docs.                Document every key inline.
```

---

## Navigation

- Back to: [containers/](../10_containers/)
- Helm hooks and lifecycle: [hooks_across_the_stack.md](./hooks_across_the_stack.md)
- Terraform passing values into Helm: [terraform_to_k8s_variable_flow.md](./terraform_to_k8s_variable_flow.md)
- Deployment strategies in Kubernetes: [k8s_deployment_strategies.md](./k8s_deployment_strategies.md)
- EKS cluster setup: [eks.md](./eks.md)
