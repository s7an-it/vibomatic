#!/usr/bin/env bash
# Tier 1.5: Skill Triggering Tests
#
# Tests whether Claude recommends the correct vibomatic skill from a naive
# prompt. Unlike obra/superpowers (installed as plugins), vibomatic skills
# are local SKILL.md files — they aren't auto-discovered. So we test whether
# Claude, given knowledge of the skill manifest, correctly identifies which
# skill to use.
#
# Each test: ~60s, ~10K tokens.
# Requires: claude CLI
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

PROMPTS_DIR="$SCRIPT_DIR/prompts"

PASS=0
FAIL=0

# Build a manifest context block for the prompt
MANIFEST_CONTEXT=$(cat <<'EOF'
You are a vibomatic routing assistant. Given a user request, identify which vibomatic skill should handle it.

Available skills and their purposes:
- vision-sync: Create/refine product vision documents
- persona-builder: Create user personas from vision
- feature-discovery: Discover, validate, and prioritize features
- writing-spec: Define feature requirements with user stories and ACs
- spec-ac-sync: Audit spec ACs for quality and completeness
- spec-code-sync: Detect drift between specs and code
- spec-style-sync: Generate/audit code style contracts
- journey-sync: Create user journey maps and Gherkin scenarios
- writing-ux-design: Create UX screen flows and states
- writing-ui-design: Create UI component specs and design tokens
- writing-technical-design: Create technical architecture design
- writing-change-set: Produce implementation manifests with task graphs
- executing-change-set: Execute implementation tasks with TDD
- review-protocol: Multi-pass code review
- promoting-change-set: Squash-merge reviewed branch to main
- verifying-promotion: Post-merge verification
- bugfix-brief: Triage and scope bug fixes
- repo-conversion: Convert existing repos to vibomatic structure
- work-item-sync: Track work items across iterations
- domain-expert: Build domain knowledge profiles
- competitor-analysis: Analyze competitor products
- research: On-demand research for APIs, libraries, patterns
- agentic-e2e-playwright: Generate E2E tests from journey scenarios

Respond with ONLY the skill name (e.g., "bugfix-brief"). No explanation.
EOF
)

test_routing() {
  local expected_skill="$1"
  local prompt_file="$2"
  local user_prompt
  user_prompt=$(cat "$prompt_file")

  echo "--- Routing test: $expected_skill ---"
  echo "  Prompt: $(head -c 80 "$prompt_file")..."

  local full_prompt="${MANIFEST_CONTEXT}

User request: ${user_prompt}"

  local output
  output=$(run_claude "$full_prompt" 60) || true

  if assert_contains "$output" "$expected_skill" "Routes to $expected_skill"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "    Claude suggested: $(echo "$output" | head -1)"
  fi
  echo ""
}

echo "=== Tier 1.5: Skill Triggering (Routing) Tests ==="
echo "  Prompts dir: $PROMPTS_DIR"
echo ""

for prompt_file in "$PROMPTS_DIR"/*.txt; do
  [[ ! -f "$prompt_file" ]] && continue
  expected_skill="$(basename "$prompt_file" .txt)"
  test_routing "$expected_skill" "$prompt_file"
done

report_results "Skill Triggering" $PASS $FAIL
