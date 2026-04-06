#!/usr/bin/env bash
# Tier 1.5: Skill Triggering Tests
#
# Tests whether Claude recommends the correct svc skill from a naive
# prompt. Unlike obra/superpowers (installed as plugins), svc skills
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
You are a svc routing assistant. Given a user request, identify which svc skill should handle it.

Available skills and their purposes:
- write-vision: Create/refine product vision documents
- build-personas: Create user personas from vision
- validate-feature: Discover, validate, and prioritize features
- write-spec: Define feature requirements with user stories and ACs
- audit-ac: Audit spec ACs for quality and completeness
- sync-spec-code: Detect drift between specs and code
- define-code-style: Generate/audit code style contracts
- write-journeys: Create user journey maps and Gherkin scenarios
- design-ux: Create UX screen flows and states
- design-ui: Create UI component specs and design tokens
- design-tech: Create technical architecture design
- plan-changeset: Produce implementation manifests with task graphs
- execute-changeset: Execute implementation tasks with TDD
- review-gate: Multi-pass code review
- land-changeset: Squash-merge reviewed branch to main
- verify-promotion: Post-merge verification
- diagnose-bug: Triage and scope bug fixes
- onboard-repo: Convert existing repos to svc structure
- sync-work-items: Track work items across iterations
- analyze-domain: Build domain knowledge profiles
- analyze-competitors: Analyze competitor products
- research: On-demand research for APIs, libraries, patterns
- write-e2e: Generate E2E tests from journey scenarios

Respond with ONLY the skill name (e.g., "diagnose-bug"). No explanation.
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
