#!/usr/bin/env bash
# Tier 1.5: Skill Comprehension Tests
#
# Tests whether Claude understands the rules of vibomatic skills by asking
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
Here is the content of vibomatic's $skill_name skill:

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
  local prompt="Here are vibomatic skill definitions:\n\n"
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

# --- vision-sync ---

run_test "vision-sync: chain position" "vision-sync" \
  "What is the next skill in the greenfield lane after vision-sync? Just name the skill." \
  "domain-expert" "Next skill is domain-expert"

run_test "vision-sync: scope boundary" "vision-sync" \
  "Does vision-sync cover implementation details like database schemas, API endpoints, or framework choices? Answer yes or no and explain briefly." \
  "no|No|NOT|never|does not|doesn.t|vision.only" "Vision excludes implementation details"

# --- writing-spec ---

run_test "writing-spec: lifecycle states" "writing-spec" \
  "What are the spec lifecycle states in order? List them all." \
  "DRAFT" "Has DRAFT" \
  "VERIFIED" "Has VERIFIED" \
  "BASELINED" "Has BASELINED"

run_test "writing-spec: output status" "writing-spec" \
  "What status does the spec have when writing-spec first produces it? One word answer." \
  "DRAFT" "Produces DRAFT status"

# --- writing-change-set ---

run_test "writing-change-set: simulation requirement" "writing-change-set" \
  "What does the pre-implementation simulation step do? What is the two-layer resolution model?" \
  "simulation|Simulation" "Mentions simulation" \
  "planned|virtual|CREATE|disk|two.layer|resolution" "Mentions the two-layer model"

run_test "writing-change-set: manifest content" "writing-change-set" \
  "What must the implementation manifest contain? List the key components." \
  "task" "Contains tasks" \
  "AC" "Maps to ACs"

# --- executing-change-set ---

run_test "executing-change-set: TDD enforcement" "executing-change-set" \
  "What is the TDD enforcement order for each task? List the red-green-refactor steps." \
  "test.*first|write.*test|failing.*test|red|Write test|test before|TDD|test-driven" "Write test first" \
  "FAIL|fail|red|must fail" "Test must fail initially" \
  "PASS|pass|green|must pass" "Then test must pass"

run_test "executing-change-set: checkpoint behavior" "executing-change-set" \
  "When does executing-change-set create git checkpoints? Per-task or at the end?" \
  "per.task|each.*task|after.*task|checkpoint|per task|every task" "Checkpoints per task"

# --- feature-discovery ---

run_test "feature-discovery: validate mode" "feature-discovery" \
  "What does feature-discovery's validate mode do? What is a 'ship brief'?" \
  "ship|Ship" "Mentions ship brief" \
  "validat|assess|recommend|evaluat" "Validates feature viability"

# --- spec-code-sync ---

run_test "spec-code-sync: primary purpose" "spec-code-sync" \
  "What does spec-code-sync detect and report? Is it for new features or for checking existing ones?" \
  "drift|gap|mismatch|diverge|existing|audit|sync|out of date|difference" "Detects spec-code drift"

# --- chain order (multi-skill) ---

run_multi_test "greenfield lane order" \
  "What is the order of the first 6 skills in the greenfield lane? List them in sequence." \
  "vision-sync" "persona-builder" "feature-discovery" "writing-spec" -- \
  "vision" "Starts with vision-sync" \
  "persona" "Includes persona-builder" \
  "feature.discovery|feature-discovery" "Includes feature-discovery" \
  "writing.spec|writing-spec" "Includes writing-spec"

# --- self-verify gating ---

run_test "self-verify gating" "vision-sync" \
  "According to the Pipeline Continuation section, what happens if a self-verify check FAILs? Can the skill chain to the next skill?" \
  "block|stop|cannot|must.*fix|no|prevent|do not|fix before" "Self-verify FAIL blocks chaining"

# --- Summary ---

report_results "Skill Comprehension" $PASS $FAIL
