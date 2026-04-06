#!/usr/bin/env bash
# Tier 1.5: Skill Comprehension Tests
#
# Tests whether Claude understands the rules of svc skills by asking
# factual questions and checking the answers. Inspired by obra/superpowers
# test-subagent-driven-development.sh.
#
# Each prompt includes the relevant SKILL.md content so Claude can answer
# without needing the skill loaded as a plugin.
#
# Fast (~30s per test), cheap (minimal tokens), catches ambiguous skill text.
# Requires: claude CLI
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

PASS=0
FAIL=0

# Build a prompt that includes the skill's SKILL.md content for context
skill_prompt() {
  local skill_name="$1"
  local question="$2"
  local skill_file="$REPO_ROOT/$skill_name/SKILL.md"

  if [[ ! -f "$skill_file" ]]; then
    echo "$question"
    return
  fi

  # Include first 200 lines of the skill (enough for frontmatter + core rules)
  local content
  content=$(head -200 "$skill_file")

  cat <<EOF
Here is the content of svc's $skill_name skill:

---
$content
---

Based on the skill content above, answer this question concisely:
$question
EOF
}

run_test() {
  local test_name="$1"
  local skill_name="$2"
  local question="$3"
  shift 3
  # remaining args are assert_contains pattern/label pairs

  echo "Test: $test_name"
  local prompt
  prompt=$(skill_prompt "$skill_name" "$question")
  local output
  output=$(run_claude "$prompt" 60) || true

  while [[ $# -ge 2 ]]; do
    local pattern="$1"
    local label="$2"
    shift 2
    if assert_contains "$output" "$pattern" "$label"; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
    fi
  done
  echo ""
}

# Multi-skill test: include multiple skills' content
run_multi_test() {
  local test_name="$1"
  local question="$2"
  shift 2

  # Collect skill names until we hit assertion pairs (pattern/label)
  local skills=()
  local args=()
  local collecting_skills=true
  while [[ $# -gt 0 ]]; do
    if $collecting_skills; then
      # Skills don't contain spaces; assertion labels do. Use -- as separator.
      if [[ "$1" == "--" ]]; then
        collecting_skills=false
        shift
        continue
      fi
      skills+=("$1")
      shift
    else
      args+=("$1")
      shift
    fi
  done

  echo "Test: $test_name"
  local prompt="Here are svc skill definitions:\n\n"
  for s in "${skills[@]}"; do
    local sf="$REPO_ROOT/$s/SKILL.md"
    [[ ! -f "$sf" ]] && continue
    prompt+="### $s\n\`\`\`\n$(head -50 "$sf")\n\`\`\`\n\n"
  done
  prompt+="\nBased on the skill definitions above, answer concisely:\n$question"

  local output
  output=$(run_claude "$(echo -e "$prompt")" 60) || true

  local i=0
  while [[ $i -lt ${#args[@]} ]] && [[ $((i+1)) -lt ${#args[@]} ]]; do
    local pattern="${args[$i]}"
    local label="${args[$((i+1))]}"
    i=$((i + 2))
    if assert_contains "$output" "$pattern" "$label"; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
    fi
  done
  echo ""
}

echo "=== Tier 1.5: Skill Comprehension Tests ==="
echo ""

# --- write-vision ---

run_test "write-vision: chain position" "write-vision" \
  "What is the next skill in the greenfield lane after write-vision? Just name the skill." \
  "analyze-domain" "Next skill is analyze-domain"

run_test "write-vision: scope boundary" "write-vision" \
  "Does write-vision cover implementation details like database schemas, API endpoints, or framework choices? Answer yes or no and explain briefly." \
  "no|No|NOT|never|does not|doesn.t|vision.only" "Vision excludes implementation details"

# --- write-spec ---

run_test "write-spec: lifecycle states" "write-spec" \
  "What are the spec lifecycle states in order? List them all." \
  "DRAFT" "Has DRAFT" \
  "VERIFIED" "Has VERIFIED" \
  "BASELINED" "Has BASELINED"

run_test "write-spec: output status" "write-spec" \
  "What status does the spec have when write-spec first produces it? One word answer." \
  "DRAFT" "Produces DRAFT status"

# --- plan-changeset ---

run_test "plan-changeset: simulation requirement" "plan-changeset" \
  "What does the pre-implementation simulation step do? What is the two-layer resolution model?" \
  "simulation|Simulation" "Mentions simulation" \
  "planned|virtual|CREATE|disk|two.layer|resolution" "Mentions the two-layer model"

run_test "plan-changeset: manifest content" "plan-changeset" \
  "What must the implementation manifest contain? List the key components." \
  "task" "Contains tasks" \
  "AC" "Maps to ACs"

# --- execute-changeset ---

run_test "execute-changeset: TDD enforcement" "execute-changeset" \
  "What is the TDD enforcement order for each task? List the red-green-refactor steps." \
  "test.*first|write.*test|failing.*test|red|Write test|test before|TDD|test-driven" "Write test first" \
  "FAIL|fail|red|must fail" "Test must fail initially" \
  "PASS|pass|green|must pass" "Then test must pass"

run_test "execute-changeset: checkpoint behavior" "execute-changeset" \
  "When does execute-changeset create git checkpoints? Per-task or at the end?" \
  "per.task|each.*task|after.*task|checkpoint|per task|every task" "Checkpoints per task"

# --- validate-feature ---

run_test "validate-feature: validate mode" "validate-feature" \
  "What does validate-feature's validate mode do? What is a 'ship brief'?" \
  "ship|Ship" "Mentions ship brief" \
  "validat|assess|recommend|evaluat" "Validates feature viability"

# --- sync-spec-code ---

run_test "sync-spec-code: primary purpose" "sync-spec-code" \
  "What does sync-spec-code detect and report? Is it for new features or for checking existing ones?" \
  "drift|gap|mismatch|diverge|existing|audit|sync|out of date|difference" "Detects spec-code drift"

# --- chain order (multi-skill) ---

run_multi_test "greenfield lane order" \
  "What is the order of the first 6 skills in the greenfield lane? List them in sequence." \
  "write-vision" "build-personas" "validate-feature" "write-spec" -- \
  "vision" "Starts with write-vision" \
  "persona" "Includes build-personas" \
  "feature.discovery|validate-feature" "Includes validate-feature" \
  "writing.spec|write-spec" "Includes write-spec"

# --- self-verify gating ---

run_test "self-verify gating" "write-vision" \
  "According to the Pipeline Continuation section, what happens if a self-verify check FAILs? Can the skill chain to the next skill?" \
  "block|stop|cannot|must.*fix|no|prevent|do not|fix before" "Self-verify FAIL blocks chaining"

# --- Summary ---

report_results "Skill Comprehension" $PASS $FAIL
