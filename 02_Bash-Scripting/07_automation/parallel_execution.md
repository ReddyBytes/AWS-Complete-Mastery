# Parallel Execution in Bash

Imagine a restaurant kitchen where a single chef has to cook every dish on the menu one at a time. Appetizer for table 3, done. Entree for table 1, done. Dessert for table 7, done. Service grinds to a halt. Now add 10 chefs working simultaneously — every station fires at once, throughput multiplies, and the dining room stays happy.

Bash scripts default to the single-chef model: run one command, wait for it to finish, run the next. For anything touching networks, remote servers, or file I/O, this is a performance catastrophe. **Parallel execution** breaks that model and lets your script become the kitchen that runs all stations at once.

---

## 1. Why Parallel Execution

The math is brutal for sequential work:

```
100 servers × 5 seconds per SSH check = 500 seconds (~8 minutes)
100 servers × 5 seconds, run 20 at a time = 25 seconds
```

Parallel execution matters most when:
- Work is **I/O-bound** (network calls, SSH, API requests)
- Jobs are **independent** (no shared state, no ordering requirement)
- You have a **pool of identical targets** (servers, files, regions)

It matters less (or backfires) when:
- Work is CPU-bound on a single-core machine
- Jobs share state and need locking
- External API has strict rate limits

---

## 2. Background Jobs with `&`

The simplest parallelism tool in bash is `&` — it sends a command to the background and returns control immediately.

```bash
#!/usr/bin/env bash

# Send a command to the background
sleep 5 &                         # ← runs in background, prompt returns instantly
echo "Started sleep in background"

# List background jobs
jobs                              # ← shows: [1]+ Running   sleep 5

# Wait for ALL background jobs to finish
wait                              # ← blocks until every background job is done
echo "All done"
```

### Waiting for a specific job by PID

```bash
#!/usr/bin/env bash

# Capture the PID of a background job with $!
deploy_service "frontend" &
FRONTEND_PID=$!                   # ← $! is the PID of the last backgrounded process

deploy_service "backend" &
BACKEND_PID=$!

# Wait for just the frontend
wait $FRONTEND_PID
echo "Frontend deploy finished"

wait $BACKEND_PID
echo "Backend deploy finished"
```

### Capturing exit codes from background jobs

This is where most scripts get it wrong. `wait $PID` returns the exit code of that job.

```bash
#!/usr/bin/env bash

run_job() {
  sleep 2
  return 1                        # ← simulate failure
}

run_job &
JOB_PID=$!

wait $JOB_PID
EXIT_CODE=$?                      # ← captures the exit code of that specific background job

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "Job failed with exit code: $EXIT_CODE"
fi
```

### `jobs` command

```bash
jobs          # ← list all background jobs in current shell
jobs -l       # ← include PIDs
jobs -p       # ← just PIDs (useful for scripting)
```

---

## 3. Job Control Patterns

### Throttling: the semaphore pattern

Running all 1000 jobs at once will exhaust file descriptors, overwhelm remote servers, and hit API rate limits. The semaphore pattern caps concurrency at N.

```bash
#!/usr/bin/env bash

MAX_JOBS=10                       # ← maximum parallel jobs
PIDS=()                           # ← array to track running PIDs

servers=( server{1..50} )

for server in "${servers[@]}"; do
  # If we've hit the cap, wait for one slot to free up
  while [[ ${#PIDS[@]} -ge $MAX_JOBS ]]; do
    NEW_PIDS=()
    for pid in "${PIDS[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then  # ← kill -0 checks if process is alive
        NEW_PIDS+=("$pid")
      fi
    done
    PIDS=("${NEW_PIDS[@]}")
    sleep 0.1                     # ← small sleep to avoid busy-waiting
  done

  # Launch the job and track its PID
  ssh "$server" uptime &
  PIDS+=($!)
done

# Wait for remaining jobs
wait
echo "All jobs complete"
```

### Collecting output from parallel jobs

Parallel jobs writing to stdout will interleave. Write each job's output to a temp file instead.

```bash
#!/usr/bin/env bash

TMPDIR=$(mktemp -d)               # ← create temp dir for output files
PIDS=()

for server in server{1..10}; do
  {
    ssh "$server" uptime > "$TMPDIR/$server.out" 2>&1   # ← each job writes its own file
  } &
  PIDS+=($!)
done

wait

# Print results in order
for server in server{1..10}; do
  echo "=== $server ==="
  cat "$TMPDIR/$server.out"
done

rm -rf "$TMPDIR"
```

### Complete pattern: N parallel, wait all, check all exit codes

```bash
#!/usr/bin/env bash

MAX_JOBS=5
declare -A JOB_PIDS              # ← associative array: job_name → PID
declare -A JOB_STATUS            # ← associative array: job_name → exit_code

run_job() {
  local name=$1
  echo "Running: $name"
  ssh "$name" "df -h" &> "/tmp/${name}.log"
}

servers=( web{1..20} )

for server in "${servers[@]}"; do
  # Throttle to MAX_JOBS
  while [[ $(jobs -rp | wc -l) -ge $MAX_JOBS ]]; do
    sleep 0.1
  done

  run_job "$server" &
  JOB_PIDS["$server"]=$!
done

wait                              # ← wait for all jobs

# Collect exit codes
FAILED=0
for server in "${!JOB_PIDS[@]}"; do
  wait "${JOB_PIDS[$server]}"
  JOB_STATUS["$server"]=$?
  if [[ ${JOB_STATUS[$server]} -ne 0 ]]; then
    echo "FAILED: $server (exit ${JOB_STATUS[$server]})"
    FAILED=$((FAILED + 1))
  fi
done

echo "$FAILED servers failed"
exit $FAILED
```

---

## 4. `xargs -P` — Parallel with Process Pool

`xargs` takes a list of arguments and runs a command on them. The `-P` flag sets how many processes run at once — it is a built-in process pool.

```bash
# -P 10: run 10 processes at a time
# -I {}: placeholder for the argument
cat servers.txt | xargs -P 10 -I {} ssh {} uptime
```

### Core flags

```
-P N    number of parallel processes
-I {}   placeholder string replaced by each argument
-n N    number of arguments passed per invocation (default: all remaining)
-t      print each command before running (debug)
```

### Parallel curl health checks

```bash
# Check HTTP status for 100 URLs in parallel (10 at a time)
cat urls.txt | xargs -P 10 -I {} curl -s -o /dev/null -w "%{http_code} {}\n" {}
```

### Parallel file processing

```bash
# Compress all .log files in parallel (4 gzip processes)
find /var/log -name "*.log" | xargs -P 4 gzip

# -n 1: pass one file at a time to gzip
find /var/log -name "*.log" | xargs -P 4 -n 1 gzip
```

### Parallel SSH

```bash
# Run uptime on every server in servers.txt, 5 at a time
cat servers.txt | xargs -P 5 -I {} ssh -o StrictHostKeyChecking=no {} uptime
```

### Limitation of `xargs -P`

Output from parallel `xargs -P` jobs is **not guaranteed to be ordered** and can interleave. For structured output collection, GNU `parallel` is the better tool.

---

## 5. GNU Parallel — The Serious Tool

GNU `parallel` is `xargs -P` with superpowers: structured output, job retry, ETA, result saving, and argument composition.

### Installation

```bash
brew install parallel        # macOS
apt install parallel         # Debian/Ubuntu
yum install parallel         # RHEL/CentOS
```

### Basic syntax

```bash
# Run echo on three arguments
parallel echo ::: foo bar baz

# Run 8 workers on jobs 1-100
parallel -j 8 "echo job {}" ::: {1..100}

# Read commands from a file (one per line)
parallel -j 4 < commands.txt
```

### Real patterns

```bash
# Parallel SSH to 50 servers (20 at a time)
parallel -j 20 'ssh {} "df -h"' ::: $(cat servers.txt)

# Save each job's output to a separate file under results/
parallel -j 8 --results results/ "curl -s {}" ::: $(cat urls.txt)
# ← results/1/stdout, results/1/stderr, results/2/stdout ...

# Show estimated completion time
parallel -j 8 --eta "process_file {}" ::: *.csv

# Retry jobs that failed (up to 3 times)
parallel -j 8 --retries 3 "deploy_to {}" ::: $(cat servers.txt)
```

### Composing arguments from multiple sources

```bash
# All combinations of env × region
parallel "aws ec2 describe-instances --region {2} --filters Name=tag:Env,Values={1}" \
  ::: dev staging prod \
  ::: us-east-1 us-west-2 eu-west-1
# ← runs 9 commands: 3 envs × 3 regions
```

---

## 6. Parallel SSH Operations

```bash
#!/usr/bin/env bash

# Check disk usage on all prod servers in parallel
parallel -j 20 \
  'ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 {} "df -h | grep /dev/xvda"' \
  ::: $(cat /etc/prod-servers.txt)
```

### Collecting errors from parallel SSH

```bash
#!/usr/bin/env bash

# Use --results to capture stdout/stderr per host
parallel -j 20 --results /tmp/ssh-results/ \
  'ssh {} "systemctl status nginx"' \
  ::: $(cat servers.txt)

# Find failed hosts
for dir in /tmp/ssh-results/*/; do
  if [[ $(cat "${dir}exitval") -ne 0 ]]; then
    echo "FAILED: $(basename $dir)"
    cat "${dir}stderr"
  fi
done
```

### Parallel kubectl across namespaces

```bash
# Restart deployments in 5 namespaces in parallel
parallel -j 5 \
  'kubectl rollout restart deployment/api -n {}' \
  ::: ns-team1 ns-team2 ns-team3 ns-team4 ns-team5
```

---

## 7. Parallel AWS CLI Calls

### Describe instances across 5 regions

```bash
#!/usr/bin/env bash

REGIONS=( us-east-1 us-west-2 eu-west-1 ap-southeast-1 ap-northeast-1 )

# Run 5 describe-instances calls in parallel, save each to a file
parallel -j 5 \
  'aws ec2 describe-instances --region {} --query "Reservations[*].Instances[*].[InstanceId,State.Name]" --output json > /tmp/instances-{}.json' \
  ::: "${REGIONS[@]}"

# Merge results with jq
jq -s 'add' /tmp/instances-*.json > /tmp/all-instances.json
echo "Total instances: $(jq 'length' /tmp/all-instances.json)"
```

### Deploy to multiple environments simultaneously

```bash
#!/usr/bin/env bash

deploy_env() {
  local env=$1
  echo "Deploying to $env..."
  aws ecs update-service \
    --cluster "cluster-${env}" \
    --service "api-${env}" \
    --force-new-deployment \
    --region us-east-1 > "/tmp/deploy-${env}.log" 2>&1
  echo "Done: $env (exit $?)"
}

export -f deploy_env              # ← export function so parallel can call it

parallel -j 3 deploy_env ::: dev staging prod
```

### Rate limiting: handling AWS API throttling

```bash
#!/usr/bin/env bash

# AWS will throttle if you hit the same API too hard
# Add random jitter between 0-2 seconds before each call

parallel -j 10 \
  'sleep $(python3 -c "import random; print(round(random.uniform(0,2),2))"); aws ec2 describe-instances --instance-ids {} --region us-east-1' \
  ::: $(cat instance-ids.txt)
```

---

## 8. Output Management

### The interleaved stdout problem

```
# Without buffering, parallel jobs mix output like this:
[job1] Starting deploy...
[job3] Starting deploy...
[job2] Starting deploy...
[job1] Pulling image...
[job3] Done.
[job2] ERROR: image not found   ← impossible to tell which job produced what
```

### Solutions

```bash
# --line-buffer: buffer output per line (faster, some interleaving)
parallel -j 8 --line-buffer "curl -s {}" ::: $(cat urls.txt)

# --group: buffer ALL output per job, print only when job completes (cleanest)
parallel -j 8 --group "deploy {}" ::: server{1..20}

# Manual: each job logs to its own file
for server in server{1..20}; do
  {
    ssh "$server" "uptime && df -h"
  } > "/tmp/output-${server}.log" 2>&1 &
done
wait
```

### Structured logging pattern

```bash
#!/usr/bin/env bash

LOG_DIR=$(mktemp -d)

run_with_log() {
  local target=$1
  local logfile="$LOG_DIR/${target}.log"
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting $target"
    ssh "$target" "uptime && free -h"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished $target (exit $?)"
  } > "$logfile" 2>&1
}

export -f run_with_log
export LOG_DIR

parallel -j 20 run_with_log ::: $(cat servers.txt)

echo "Logs in: $LOG_DIR"
```

---

## 9. Exit Code and Error Handling

### GNU parallel halt strategies

```bash
# Stop immediately when first job fails (kill all running jobs)
parallel --halt now,fail=1 "deploy {}" ::: server{1..50}

# Finish currently running jobs, then stop (don't start new ones)
parallel --halt soon,fail=1 "deploy {}" ::: server{1..50}

# Stop after N failures (useful for tolerating flaky SSH)
parallel --halt soon,fail=5 "check {}" ::: server{1..50}
```

### The `$?` trap with `wait`

```bash
# WRONG: only catches the exit code of the LAST job
job1 & job2 & job3 &
wait
echo $?   # ← only the exit code of job3
```

```bash
# CORRECT: wait on each PID individually
declare -A PIDS

job1 & PIDS[job1]=$!
job2 & PIDS[job2]=$!
job3 & PIDS[job3]=$!

FAILED=0
for name in "${!PIDS[@]}"; do
  wait "${PIDS[$name]}"
  code=$?
  if [[ $code -ne 0 ]]; then
    echo "FAILED: $name (exit $code)"
    FAILED=1
  fi
done

exit $FAILED
```

### Killing child processes on script exit

When your script is killed (Ctrl+C, SIGTERM), background jobs keep running unless you clean them up.

```bash
#!/usr/bin/env bash

# Track all child PIDs
CHILD_PIDS=()

# Kill all children when this script exits for any reason
cleanup() {
  echo "Cleaning up ${#CHILD_PIDS[@]} background jobs..."
  for pid in "${CHILD_PIDS[@]}"; do
    kill "$pid" 2>/dev/null
  done
  wait
}

trap cleanup EXIT                 # ← run cleanup() on any exit

for server in server{1..20}; do
  ssh "$server" "long_running_job.sh" &
  CHILD_PIDS+=($!)
done

wait
```

---

## 10. Production Script Patterns

### Health-checking 50 servers in 5 seconds

```bash
#!/usr/bin/env bash

check_server() {
  local host=$1
  if curl -sf --max-time 3 "http://${host}/health" > /dev/null; then
    echo "OK    $host"
  else
    echo "FAIL  $host"
  fi
}

export -f check_server

parallel -j 20 --group check_server ::: $(cat /etc/servers.txt) | sort
```

### Rotating credentials on 100 instances

```bash
#!/usr/bin/env bash

NEW_KEY=$(cat /tmp/new-api-key.txt)

rotate_cred() {
  local host=$1
  ssh "$host" "echo 'API_KEY=${NEW_KEY}' | sudo tee /etc/app/creds.env && sudo systemctl restart app" \
    > "/tmp/rotate-${host}.log" 2>&1
  echo "$? $host"
}

export -f rotate_cred
export NEW_KEY

parallel -j 25 --halt soon,fail=10 rotate_cred ::: $(cat servers.txt)
```

### Running database migrations on read replicas in parallel

```bash
#!/usr/bin/env bash

REPLICAS=( replica{1..8}.db.internal )

run_migration() {
  local host=$1
  mysql -h "$host" -u admin -p"$DB_PASS" < /deploy/migration.sql \
    > "/tmp/migration-${host}.log" 2>&1
}

export -f run_migration

# Run on all replicas in parallel — migrations must be idempotent
parallel -j 8 run_migration ::: "${REPLICAS[@]}"

# Check all succeeded
FAILED=0
for host in "${REPLICAS[@]}"; do
  if grep -q "ERROR" "/tmp/migration-${host}.log" 2>/dev/null; then
    echo "Migration error on $host:"
    cat "/tmp/migration-${host}.log"
    FAILED=$((FAILED + 1))
  fi
done

exit $FAILED
```

### Parallel file uploads to S3

```bash
#!/usr/bin/env bash

BUCKET="s3://my-data-bucket/archive"

# Upload all .parquet files in parallel (8 at a time)
find /data/export -name "*.parquet" | \
  parallel -j 8 'aws s3 cp {} '"$BUCKET"'/{/}'
#                                          ← {/} = basename of argument
```

---

## 11. Common Mistakes

| Mistake | What goes wrong | Fix |
|---|---|---|
| Forgetting `wait` | Script exits while background jobs still run | Always call `wait` before checking results or exiting |
| Reading `$?` after `wait` with multiple jobs | Only gets exit code of last-started job | `wait $PID` per job, store results in array |
| Shell variable races | Two parallel jobs write to same variable | Use files, arrays indexed by job name, or `flock` |
| AWS API throttling | `ThrottlingException` from too many parallel API calls | Reduce `-j`, add jitter (`sleep $(($RANDOM % 3))`) |
| Not killing children on exit | Orphan processes keep running after script dies | `trap cleanup EXIT` with `kill` of all tracked PIDs |
| Interleaved output | Can't tell which job produced which output | Use `--group` in GNU parallel or write to per-job log files |
| `xargs -P` without `-n` | All arguments go to a single invocation | Use `-n 1` to pass one argument per process |
| Large fan-out with no throttle | Exhausts file descriptors, floods network | Always set `-j N` or `MAX_JOBS` |

---

## Navigation

- Previous: [loops.md](../loops.md)
- Next: [scheduling.md](scheduling.md)
- Related: [jobs_and_daemons.md](jobs_and_daemons.md)
