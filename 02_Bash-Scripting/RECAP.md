# Bash Scripting — Topic Recap

> One-line summary of every module. Use this to quickly find which module covers the concept you need.

---

## Foundations

| Module | Topics Covered |
|--------|----------------|
| [01_shell_basics](./01_shell_basics/) | What a shell script is, the shebang line (`#!/usr/bin/env bash`), making scripts executable (`chmod +x`), running scripts, script structure and comments |
| [02_variables_and_data](./02_variables_and_data/) | Declaring and expanding variables, quoting rules, environment vs local variables, arrays (indexed and associative), string operations (length, substring, replace, upper/lower, trim) |

## Logic and Structure

| Module | Topics Covered |
|--------|----------------|
| [03_control_flow](./03_control_flow/) | `if`/`elif`/`else`, test operators (`-eq`, `-gt`, `-f`, `-d`, `-z`, `==`), `[[ ]]` vs `[ ]`, `case` statements, `for` loops (list and C-style), `while` and `until` loops, `break` and `continue` |
| [04_functions](./04_functions/) | Defining functions (both syntaxes), positional parameters (`$1`, `$@`, `$#`), local variables and scope, return values vs exit codes, passing and returning data, libraries and sourcing |

## Input, Output and Errors

| Module | Topics Covered |
|--------|----------------|
| [05_input_output](./05_input_output/) | `read` for interactive input (prompts, silent mode, timeout), positional arguments (`$1`, `$*`, `$@`), `getopts` for flags, pipes and redirection in scripts, `printf` vs `echo`, heredocs |
| [06_error_handling](./06_error_handling/) | Exit codes and `$?`, `set -e` (exit on error), `set -u` (undefined variable protection), `set -o pipefail`, `trap` for cleanup on EXIT/ERR/SIGINT, debugging with `set -x` (trace mode), `bash -n` syntax check |

## Automation and Real-World Use

| Module | Topics Covered |
|--------|----------------|
| [07_automation](./07_automation/) | Cron syntax (minute/hour/day/month/weekday), `crontab -e`, common cron patterns (`*/5`, `0 2 * * *`), `at` for one-shot tasks, `watch` for continuous monitoring, systemd timers as cron replacement, `anacron` for non-always-on machines |
| [08_real_world_scripts](./08_real_world_scripts/) | Production backup scripts (3-2-1 rule, compression, rotation, S3 upload), deployment scripts (pre-flight checks, rollback, health checks, locking), system monitoring scripts (`df`, `free`, service checks, alerting) |

## Interview Prep

| Module | Topics Covered |
|--------|----------------|
| [99_interview_master](./99_interview_master/) | Beginner to advanced Bash interview questions: shebang, redirection, quoting, arrays, functions, error handling, `set -euo pipefail`, debugging broken scripts, writing scripts on the spot |

---

*Total modules: 8 + interview · Last updated: 2026-04-21*
