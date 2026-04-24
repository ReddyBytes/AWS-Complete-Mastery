# jq and JSON Processing

> Production DevOps/SRE guide — field access, filters, AWS recipes, and scripting best practices.

---

## 1. What jq Is and Why It Matters

Imagine you are driving cross-country with a paper road atlas the size of a dining table. Every road in the country is on it. But you only want to get from Denver to Boulder. You do not need the map of Florida. You need a **GPS** — something you describe your destination to, and it finds the one path through all that noise.

JSON is the atlas. Modern infrastructure hands it to you constantly: every `aws` CLI call returns it, every REST API responds with it, every Kubernetes resource was born as JSON before YAML dressed it up. The data you actually need — one instance ID, one endpoint URL, one field buried four levels deep — is sitting inside a document that can be thousands of lines long.

**jq** is the GPS. You write a filter expression, jq walks the JSON tree, and you get exactly the output you asked for — nothing more, nothing less.

Why this matters in practice:
- `aws ec2 describe-instances` returns hundreds of lines per instance; you need two fields
- A CI pipeline receives a webhook payload and must extract a commit SHA to pass to the next step
- A Kubernetes operator dumps a 2,000-line JSON manifest; you need to check one annotation
- A CloudWatch Logs Insights query returns results as nested JSON; you need a flat CSV

Without jq you are piping through `grep`, `sed`, `awk`, `python -c`, and hoping the format never changes. With jq you have a purpose-built, stable, POSIX-friendly tool that understands JSON natively.

---

## 2. Installing and Basic Syntax

Like a new power tool, jq needs to be on your workbench before you can use it. Installation is one command on any major platform.

```bash
# macOS
brew install jq

# Debian / Ubuntu
apt install jq

# Amazon Linux 2 / RHEL
yum install jq

# Check version
jq --version
```

**Basic invocation** — two equivalent ways to feed jq a document:

```bash
cat file.json | jq '.'           # ← pipe from stdin
jq '.' file.json                 # ← read file directly (preferred — fewer processes)
```

The filter `'.'` is the **identity filter** — it passes the input through unchanged but pretty-prints it with colour and indentation. This alone is worth having jq installed: `aws sts get-caller-identity | jq '.'` turns a wall of compressed JSON into something readable.

```
Input (raw):                       Output (after jq '.'):
{"Account":"123456789","Arn":...}  {
                                     "Account": "123456789",
                                     "Arn": "arn:aws:iam::..."
                                   }
```

---

## 3. Basic Field Access

Think of JSON as a nested filing cabinet. The **filter** is your hand: you describe which drawer, which folder, which sheet of paper you want, and jq reaches in and pulls it out.

```bash
# .fieldname — get a top-level field
echo '{"region":"us-east-1","account":"123"}' | jq '.region'
# → "us-east-1"

# .fieldname.nested — descend into nested objects
echo '{"meta":{"version":"1.2"}}' | jq '.meta.version'
# → "1.2"

# .[0] — get first element of an array (zero-indexed)
echo '[10,20,30]' | jq '.[0]'
# → 10

# .[] — iterate every element of an array (produces multiple outputs)
echo '["a","b","c"]' | jq '.[]'
# → "a"
#    "b"
#    "c"

# .[2:5] — array slice, indices 2,3,4 (end is exclusive)
echo '[0,1,2,3,4,5]' | jq '.[2:5]'
# → [2,3,4]
```

**Practical — extract your AWS account ID:**

```bash
aws sts get-caller-identity | jq '.Account'
# → "123456789012"

aws sts get-caller-identity | jq -r '.Account'  # ← -r strips the surrounding quotes
# → 123456789012
```

**Field names with hyphens or spaces** must be quoted inside the filter:

```bash
jq '."hyphen-key"' file.json     # ← quotes required; bare .hyphen-key is a parse error
```

---

## 4. Filters and Pipes

jq has its own pipe operator `|` that works exactly like the shell pipe: the **output of the left filter becomes the input of the right filter**. This lets you chain transformations like assembly-line stations.

```
Input JSON  →  [filter 1]  →  intermediate  →  [filter 2]  →  output
```

The `,` operator produces multiple outputs from a single input — think of it as running two filters in parallel and concatenating their results.

```bash
# | — chain filters
echo '{"a":{"b":{"c":42}}}' | jq '.a | .b | .c'
# → 42  (same as .a.b.c, but explicit about each step)

# , — multiple outputs from one document
echo '{"name":"alice","age":30}' | jq '.name, .age'
# → "alice"
#    30

# .[] | .field — iterate array then extract field from each element
echo '[{"id":1},{"id":2}]' | jq '.[] | .id'
# → 1
#    2
```

**Practical — list all EC2 instance IDs:**

```bash
aws ec2 describe-instances | \
  jq '.Reservations[].Instances[].InstanceId'
# .Reservations[]   ← iterate the reservations array
# .Instances[]      ← iterate the instances inside each reservation
# .InstanceId       ← pull the ID field
```

ASCII diagram of the AWS EC2 JSON shape:

```
{
  "Reservations": [          ← outer array (.Reservations[])
    {
      "Instances": [         ← inner array (.Instances[])
        {
          "InstanceId": "i-0abc123",
          "State": { "Name": "running" },
          ...
        }
      ]
    }
  ]
}
```

---

## 5. select() — Filtering

`select()` is the bouncer at the door. Every element that passes the test gets through; everything else is dropped. Unlike a grep that matches text, **`select()`** evaluates a jq boolean expression against the current value — so you can filter on nested fields, types, or computed conditions.

```bash
# Basic: keep only items where .state == "running"
jq '.[] | select(.state == "running")' instances.json

# String prefix check
jq '.[] | select(.name | startswith("prod-"))' servers.json

# Numeric comparison
jq '.[] | select(.memory > 256)' lambdas.json

# Combine conditions with and / or
jq '.[] | select(.state == "running" and .region == "us-east-1")' ec2.json
```

**Practical — find all running EC2 instances:**

```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" | \
  jq '[
    .Reservations[].Instances[]              # ← iterate all instances
    | select(.State.Name == "running")       # ← confirm state (belt-and-suspenders)
    | {id: .InstanceId, ip: .PrivateIpAddress, az: .Placement.AvailabilityZone}
  ]'
```

The filter above also demonstrates **wrapping output in `[]`** to collect individual results into a single JSON array instead of a stream of separate objects.

---

## 6. map() and Arrays

If `select()` is the bouncer, **`map()`** is the assembly line worker who transforms every item as it passes through. `map(f)` is exactly equivalent to `[.[] | f]` — iterate, apply, collect — but reads more clearly.

```bash
# map(.field) — extract one field from every element
echo '[{"name":"alice"},{"name":"bob"}]' | jq 'map(.name)'
# → ["alice","bob"]

# map(select(.condition)) — filter to a new array
echo '[{"v":1},{"v":5},{"v":2}]' | jq 'map(select(.v > 3))'
# → [{"v":5}]

# length — count elements (works on arrays, objects, and strings)
echo '[1,2,3,4]' | jq 'length'
# → 4

# sort_by — stable sort on a field
jq 'sort_by(.LaunchTime)' instances.json

# unique_by — deduplicate by a field
jq 'unique_by(.ImageId)' instances.json    # ← one entry per AMI

# group_by — group into sub-arrays sharing the same field value
jq 'group_by(.InstanceType)' instances.json
```

**Practical — get all unique AMI IDs in use:**

```bash
aws ec2 describe-instances | \
  jq '[.Reservations[].Instances[] | .ImageId] | unique'
# [.Reservations[].Instances[] | .ImageId]   ← collect all AMI IDs into an array
# | unique                                    ← deduplicate
```

---

## 7. Object Construction

So far jq has been reading data. **Object construction** lets you write new shapes — you describe the output JSON structure using `{}`, and fill the values with filters.

Think of it like a form: you define the blank fields and jq fills in the answers by running your filters against the input.

```bash
# {key: filter} — build a new object
echo '{"InstanceId":"i-abc","PrivateIpAddress":"10.0.0.1","State":{"Name":"running"}}' | \
  jq '{id: .InstanceId, ip: .PrivateIpAddress, state: .State.Name}'
# → {"id":"i-abc","ip":"10.0.0.1","state":"running"}

# Reshape an array of objects
aws ec2 describe-instances | \
  jq '[.Reservations[].Instances[] | {id: .InstanceId, ip: .PrivateIpAddress}]'
```

**Output formatters** for non-JSON consumers:

```bash
# @csv — comma-separated values (wrap in "" so jq treats it as a format string)
jq -r '.[] | [.id, .ip, .state] | @csv' data.json
# → "i-abc","10.0.0.1","running"

# @tsv — tab-separated (easy to import into spreadsheets)
jq -r '.[] | [.id, .ip] | @tsv' data.json

# @base64 — base64-encode a string value
jq -r '.secret | @base64' config.json

# @base64d — base64-decode
jq -r '.encoded | @base64d' config.json
```

**Practical — reshape AWS output for another script:**

```bash
aws ec2 describe-instances | \
  jq -r '[.Reservations[].Instances[]
    | {id: .InstanceId, ip: .PrivateIpAddress, name: (.Tags[]? | select(.Key=="Name") | .Value // "unnamed")}
  ] | .[] | [.id, .ip, .name] | @tsv'
# .Tags[]?   ← the ? makes it optional — no error if Tags is missing or empty
# // "unnamed" ← alternative operator: use "unnamed" if value is null
```

---

## 8. Type Functions

Sometimes you receive JSON from an external system and cannot trust its structure. **Type functions** let you interrogate values before you use them — like checking if a box contains what the label says before you reach inside.

```bash
# type — returns the type as a string
echo '"hello"' | jq 'type'      # → "string"
echo '42'      | jq 'type'      # → "number"
echo 'null'    | jq 'type'      # → "null"
echo '[]'      | jq 'type'      # → "array"
echo '{}'      | jq 'type'      # → "object"

# Type-selecting filters (pass through only matching types)
echo '[1,"a",null,true,[]]' | jq '.[] | numbers'    # → 1
echo '[1,"a",null,true,[]]' | jq '.[] | strings'    # → "a"
echo '[1,"a",null,true,[]]' | jq '.[] | booleans'   # → true
echo '[1,"a",null,true,[]]' | jq '.[] | nulls'      # → null
echo '[1,"a",null,true,[]]' | jq '.[] | arrays'     # → []
```

**Key introspection:**

```bash
# has("field") — check if a key exists in an object
echo '{"a":1}' | jq 'has("a")'     # → true
echo '{"a":1}' | jq 'has("b")'     # → false

# keys — array of object keys (sorted)
echo '{"b":2,"a":1}' | jq 'keys'   # → ["a","b"]

# values — array of object values
echo '{"a":1,"b":2}' | jq 'values' # → [1,2]

# to_entries — convert object to [{key,value}] array (useful for iteration)
echo '{"region":"us-east-1","env":"prod"}' | jq 'to_entries'
# → [{"key":"region","value":"us-east-1"},{"key":"env","value":"prod"}]

# from_entries — inverse of to_entries
jq 'to_entries | map(select(.value != null)) | from_entries' config.json
# ← remove null-valued keys from an object
```

**Practical — safely check field existence before use:**

```bash
aws ec2 describe-instances | \
  jq '.Reservations[].Instances[]
    | select(has("PublicIpAddress"))     # ← only instances that have a public IP
    | {id: .InstanceId, public_ip: .PublicIpAddress}'
```

---

## 9. String Operations

Strings in jq are not just read-only passengers. jq has a complete set of **string manipulation** functions that mirror what you would reach for `sed` or `awk` to do.

```bash
# ltrimstr / rtrimstr — remove a prefix or suffix
echo '"prod-web-01"' | jq 'ltrimstr("prod-")'   # → "web-01"
echo '"app.log"'     | jq 'rtrimstr(".log")'     # → "app"

# Case conversion
echo '"Hello World"' | jq 'ascii_downcase'   # → "hello world"
echo '"hello"'       | jq 'ascii_upcase'     # → "HELLO"

# split and join
echo '"a,b,c"'       | jq 'split(",")'       # → ["a","b","c"]
echo '["a","b","c"]' | jq 'join(",")'        # → "a,b,c"

# test — regex match (returns boolean)
echo '"prod-web-01"' | jq 'test("^prod-")'   # → true
echo '"dev-api-02"'  | jq 'test("^prod-")'   # → false

# gsub — global substitution
echo '"us-east-1"'   | jq 'gsub("-"; "_")'   # → "us_east_1"

# String interpolation with \(.expr)
echo '{"env":"prod","region":"us-east-1"}' | \
  jq '"Deploy target: \(.env)-\(.region)"'
# → "Deploy target: prod-us-east-1"
```

**Practical — normalise resource tag values:**

```bash
aws ec2 describe-instances | \
  jq '.Reservations[].Instances[]
    | .Tags[]?
    | select(.Key == "Name")
    | .Value | ascii_downcase | gsub(" "; "-")'   # ← slugify the tag value
```

---

## 10. Variables and reduce

As jq expressions grow, you sometimes need to **name intermediate results** so you can reference them later in the same expression. The `as $var` binding is how you do it — like declaring a local variable, but in a functional style.

```bash
# as $var — bind current value to a name, continue with . unchanged
echo '5' | jq '. as $n | $n * $n'    # → 25

# Useful when you need the parent while processing a child
echo '{"prefix":"prod","items":["a","b","c"]}' | \
  jq '.prefix as $p | .items[] | "\($p)-\(.)"'
# → "prod-a"
#    "prod-b"
#    "prod-c"
```

**`reduce`** — fold an array into a single accumulated value. Think of it as a running total where jq visits each element and updates a running result.

```bash
# reduce .[] as $item (initial; update_expression)
echo '[1,2,3,4,5]' | jq 'reduce .[] as $x (0; . + $x)'
# → 15
# 0          ← starting accumulator
# . + $x     ← `. ` is the accumulator, `$x` is the current element

# Sum a field across objects
echo '[{"cost":10},{"cost":25},{"cost":5}]' | \
  jq 'reduce .[] as $i (0; . + $i.cost)'
# → 40
```

**`env`** — read shell environment variables inside a jq filter:

```bash
export AWS_REGION="us-west-2"
aws ec2 describe-instances | \
  jq --arg region "$AWS_REGION" \
     '.Reservations[].Instances[] | select(.Placement.AvailabilityZone | startswith($region))'
# Using --arg is safer than env.AWS_REGION for variables that may contain special characters
# env.VAR_NAME works too but skips shell quoting protections
```

---

## 11. Real-World AWS CLI + jq Recipes

These are copy-paste ready. Each one is annotated so you understand what every clause does.

**List all S3 bucket names:**

```bash
aws s3api list-buckets | \
  jq -r '.Buckets[].Name'
# .Buckets[]   ← iterate the array
# .Name        ← extract the name field
# -r           ← raw output, no surrounding quotes
```

**Get private IPs of all running EC2 instances in a VPC:**

```bash
aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=vpc-0abc1234" \
            "Name=instance-state-name,Values=running" | \
  jq -r '.Reservations[].Instances[].PrivateIpAddress'
```

**Find all Lambda functions with memory over 256 MB:**

```bash
aws lambda list-functions | \
  jq '.Functions[]
    | select(.MemorySize > 256)         # ← filter by memory
    | {name: .FunctionName, memory: .MemorySize, runtime: .Runtime}'
```

**Extract RDS endpoint from describe-db-instances:**

```bash
aws rds describe-db-instances \
  --db-instance-identifier my-db | \
  jq -r '.DBInstances[0].Endpoint.Address'
# [0]   ← we asked for one specific instance, take the first (and only) result
```

**Get all IAM users created in the last 30 days:**

```bash
CUTOFF=$(date -u -d "30 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
         date -u -v-30d +%Y-%m-%dT%H:%M:%SZ)   # ← macOS vs Linux date syntax

aws iam list-users | \
  jq --arg cutoff "$CUTOFF" \
     '.Users[] | select(.CreateDate > $cutoff) | .UserName'
# String comparison on ISO 8601 dates works correctly because the format is lexicographically ordered
```

**Parse CloudWatch Log Insights results:**

```bash
QUERY_ID="12345678-abcd-..."
aws logs get-query-results --query-id "$QUERY_ID" | \
  jq '.results[]                          # ← each result is an array of {field,value} pairs
    | map({(.field): .value})             # ← convert to [{fieldname: value}] objects
    | add                                 # ← merge array of objects into one object
    | {message: .message, timestamp: ."@timestamp"}'
```

**Extract task ARNs from ECS list-tasks:**

```bash
aws ecs list-tasks --cluster my-cluster | \
  jq -r '.taskArns[]'
# .taskArns[]   ← the response has a top-level array called taskArns
# -r            ← strip quotes for use in shell loops or xargs
```

---

## 12. jq in Bash Scripts — Best Practices

Running jq interactively is forgiving. Inside a production script, mistakes cause silent failures or wrong data flowing into downstream commands. These practices make jq reliable in automation.

**`-r` flag — raw string output:**

```bash
# Without -r, strings have surrounding quotes — breaks variable assignment
REGION=$(aws sts get-caller-identity | jq '.Account')
echo "$REGION"    # → "123456789012"  ← the quotes are part of the string

# With -r, clean output
REGION=$(aws sts get-caller-identity | jq -r '.Account')
echo "$REGION"    # → 123456789012
```

**`-e` flag — exit non-zero on null/false:**

```bash
# Without -e, jq exits 0 even if the filter returned null
VALUE=$(echo 'null' | jq '.missing_field')
echo $?    # → 0  ← script thinks this succeeded

# With -e, null or false output causes exit code 1
VALUE=$(echo 'null' | jq -e '.missing_field') || {
  echo "Field not found, aborting"
  exit 1
}
```

**`-c` flag — compact (single-line) output:**

```bash
# Useful when storing JSON in a shell variable or passing to another command
PAYLOAD=$(aws lambda get-function-configuration --function-name my-fn | \
          jq -c '{name: .FunctionName, memory: .MemorySize}')
# → {"name":"my-fn","memory":128}   ← one line, safe for variable storage
```

**`--arg name value` — pass shell variables safely:**

```bash
INSTANCE_TYPE="t3.micro"

aws ec2 describe-instances | \
  jq --arg itype "$INSTANCE_TYPE" \
     '.Reservations[].Instances[] | select(.InstanceType == $itype)'
# --arg always injects as a string
# $itype is used inside jq without quotes — jq handles the string comparison
# NEVER do: jq ".[] | select(.type == \"$INSTANCE_TYPE\")" — breaks on special chars
```

**`--argjson name value` — pass a JSON value (number, array, object):**

```bash
jq --argjson threshold 256 \
   '.[] | select(.memory > $threshold)' functions.json
# --argjson parses the value as JSON so $threshold is a number, not a string
# select(.memory > 256) works; select(.memory > "256") would fail
```

**`//` alternative operator — null guard / default value:**

```bash
# If .Tags is null or missing, use an empty array
jq '.Tags // []' instance.json

# Chain with map to safely iterate a possibly-absent array
jq '(.Tags // []) | map(select(.Key == "Name")) | .[0].Value // "unnamed"' instance.json
#                                                               # ← default if Name tag absent
```

**Error handling pattern for scripts:**

```bash
#!/usr/bin/env bash
set -euo pipefail                           # ← exit on error, unset var, or pipe failure

RAW=$(aws ec2 describe-instances 2>&1) || {
  echo "AWS CLI failed: $RAW"
  exit 1
}

INSTANCE_IDS=$(echo "$RAW" | jq -re '[.Reservations[].Instances[].InstanceId] | .[]') || {
  echo "jq parsing failed or no instances found"
  exit 1
}
# -r   ← raw output
# -e   ← exit non-zero if result is null/false/empty
```

---

## 13. Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Forgetting `-r` on string output | Variable contains `"value"` with quotes | Add `-r` to strip JSON string quotes |
| Field name with a hyphen: `.some-field` | `jq: error: syntax error` | Quote it: `."some-field"` |
| Treating an object as an array with `.[]` | `Cannot iterate over null` or wrong type error | Check the shape with `jq 'type'` first; objects use `.field`, arrays use `.[]` |
| Using `--arg` for a numeric comparison | `select(.memory > $n)` always false | Use `--argjson` so the value is a JSON number, not a string |
| Piping a stream into a single-document filter | Only first object processed, rest silently dropped | Wrap results in `[]` or use `--slurp` (`-s`) to read all input into one array |
| Forgetting `?` on optional array access | Crashes when field is missing | Use `.field[]?` or `(.field // [])[]` |
| Not quoting `'filter'` in shell | Shell expands `$`, `(`, `)` inside the filter | Always wrap jq filters in single quotes `'...'` |
| `jq` inside a `set -e` script silently ignored | Script continues on jq null result | Add `-e` flag so jq exits non-zero on null/false |

---

## Navigation

- Back to [Shell Basics README](./README.md)
- Previous: [Text Processing](./text_processing.md)
- Related: [Commands](./commands.md) | [Pipes and Redirection](./pipes_and_redirection.md)
