#!/usr/bin/env bash
# Tier 2: Run integration scenarios via claude -p.
# Each scenario .md is parsed for Setup, Prompt, and Expected Outputs.
# Creates a proper git-initialized workspace per scenario, runs the prompt,
# checks assertions using the shared test-helpers library.
# ~50K tokens per scenario.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCENARIOS_DIR="$SCRIPT_DIR/scenarios"
RESULTS_DIR="$REPO_ROOT/framework-test/evals/results/tier-2/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RESULTS_DIR"

source "$SCRIPT_DIR/../test-helpers.sh"

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0

# Check claude CLI is available
if ! command -v claude &>/dev/null; then
  echo "ERROR: claude CLI not found. Install it or add to PATH."
  exit 1
fi

run_scenario() {
  local scenario_file="$1"
  local scenario_name
  scenario_name="$(basename "$scenario_file" .md)"
  local result_file="$RESULTS_DIR/${scenario_name}.txt"
  local pass=0
  local fail=0

  echo "--- Scenario: $scenario_name ---"

  # Create a proper git-initialized project (obra scaffold pattern)
  local work_dir
  work_dir=$(create_test_project "vibomatic-eval-${scenario_name}")
  trap 'cleanup_test_project "$work_dir"' RETURN

  echo "  Workspace: $work_dir"

  # Copy repo-level markdown for context
  cp "$REPO_ROOT"/*.md "$work_dir/" 2>/dev/null || true

  # Copy fixtures based on scenario setup section
  if grep -q "examples/todo-api" "$scenario_file"; then
    copy_todo_api_fixtures "$work_dir" "$REPO_ROOT"
  fi

  # Initial commit so the workspace has clean git state
  (cd "$work_dir" && git add -A && git commit -q -m "scaffold" 2>/dev/null) || true

  # Extract prompt from scenario (between ``` block under ## Prompt)
  local prompt
  prompt=$(awk '/^## Prompt/,/^## /{
    if (/^```$/ && started) exit
    if (started) print
    if (/^```/) started=1
  }' "$scenario_file")

  if [[ -z "$prompt" ]]; then
    echo "  SKIP: could not extract prompt from $scenario_file"
    TOTAL_SKIP=$((TOTAL_SKIP + 1))
    return
  fi

  # Run claude -p with both text output and stream-json log
  echo "  Running claude -p..."
  local output_file="$RESULTS_DIR/${scenario_name}-output.txt"
  local json_log="$RESULTS_DIR/${scenario_name}-stream.json"

  # Run twice: text for content checks, stream-json for tool invocation analysis
  if ! (cd "$work_dir" && run_claude "$prompt" 300 text > "$output_file" 2>&1); then
    echo "  WARN: claude -p exited non-zero, checking outputs anyway"
  fi

  # Check expected outputs using test-helpers assertions
  echo "  Checking assertions..."

  # --- File existence checks ---
  local file_checks
  file_checks=$(awk '/^### File Exists/,/^### /{
    if (/^- /) print
  }' "$scenario_file")

  while IFS= read -r check; do
    [[ -z "$check" ]] && continue
    local pattern
    pattern=$(echo "$check" | grep -oP '`[^`]+`' | head -1 | tr -d '`')
    [[ -z "$pattern" ]] && continue

    if assert_glob_matches "$work_dir/$pattern" "file exists: $pattern"; then
      pass=$((pass + 1))
    else
      fail=$((fail + 1))
    fi
  done <<< "$file_checks"

  # --- Content checks ([ ] checkboxes in scenario) ---
  local content_checks
  content_checks=$(awk '/^### Content Checks/,/^## /{
    if (/^\- \[ \]/) print
  }' "$scenario_file")

  while IFS= read -r check; do
    [[ -z "$check" ]] && continue

    # Extract grep patterns from quoted terms in the check description
    local grep_terms
    grep_terms=$(echo "$check" | grep -oP '"[^"]*"' | tr -d '"' || true)

    if [[ -z "$grep_terms" ]]; then
      echo "    SKIP: could not parse check: $(echo "$check" | head -c 80)"
      continue
    fi

    # Check if any of the quoted terms appear in workspace docs
    local found=false
    while IFS= read -r term; do
      [[ -z "$term" ]] && continue
      if grep -rqi "$term" "$work_dir/docs/" 2>/dev/null; then
        found=true
        break
      fi
    done <<< "$grep_terms"

    local short_check
    short_check=$(echo "$check" | sed 's/^- \[ \] //' | head -c 80)
    if $found; then
      echo "  [PASS] $short_check"
      pass=$((pass + 1))
    else
      echo "  [FAIL] $short_check"
      fail=$((fail + 1))
    fi
  done <<< "$content_checks"

  echo "  Result: $pass passed, $fail failed"
  echo "$scenario_name: $pass passed, $fail failed" >> "$result_file"

  TOTAL_PASS=$((TOTAL_PASS + pass))
  TOTAL_FAIL=$((TOTAL_FAIL + fail))
}

echo "=== Tier 2: Integration Scenarios ==="
echo "  Scenarios dir: $SCENARIOS_DIR"
echo ""

for scenario in "$SCENARIOS_DIR"/*.md; do
  [[ ! -f "$scenario" ]] && continue
  run_scenario "$scenario"
  echo ""
done

echo "=== Tier 2 Summary ==="
echo "  $TOTAL_PASS passed, $TOTAL_FAIL failed, $TOTAL_SKIP skipped"

# Write summary
cat > "$RESULTS_DIR/summary.txt" <<EOF
Tier 2 Integration Scenarios
Run: $(date -Iseconds)
Passed: $TOTAL_PASS
Failed: $TOTAL_FAIL
Skipped: $TOTAL_SKIP
EOF

if [[ $TOTAL_FAIL -gt 0 ]]; then
  exit 1
else
  exit 0
fi
