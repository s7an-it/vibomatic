#!/usr/bin/env bash
# Tier 1: Validate every SKILL.md has required frontmatter fields and sections.
# No LLM, <10s. Exit 0 if all pass, 1 if any fail.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
MANIFEST="$REPO_ROOT/skills-manifest.json"

PASS=0
FAIL=0
ERRORS=""

# Skills exempt from Pipeline Continuation section
EXEMPT_PIPELINE=("route-workflow" "test-framework")

# Skills that must have Audit Mode section (15 skills)
AUDIT_SKILLS=(
  "write-vision"
  "validate-feature"
  "write-spec"
  "write-journeys"
  "design-ux"
  "design-ui"
  "design-tech"
  "write-e2e"
  "analyze-domain"
  "analyze-competitors"
  "define-code-style"
  "explore-solutions"
  "audit-implementation"
  "track-visuals"
  "extract-bootstrap"
)

is_exempt_pipeline() {
  local skill="$1"
  for exempt in "${EXEMPT_PIPELINE[@]}"; do
    [[ "$skill" == "$exempt" ]] && return 0
  done
  return 1
}

should_have_audit() {
  local skill="$1"
  for a in "${AUDIT_SKILLS[@]}"; do
    [[ "$skill" == "$a" ]] && return 0
  done
  return 1
}

# Get all skills from manifest
SKILLS=$(node -e "
  const m = require('$MANIFEST');
  m.includedSkills.forEach(s => console.log(s));
")

for skill in $SKILLS; do
  SKILL_FILE="$REPO_ROOT/$skill/SKILL.md"

  if [[ ! -f "$SKILL_FILE" ]]; then
    ERRORS+="  FAIL: $skill — SKILL.md not found\n"
    FAIL=$((FAIL + 1))
    continue
  fi

  # Extract frontmatter (between first two --- lines)
  FRONTMATTER=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$SKILL_FILE")

  # Check required frontmatter fields
  for field in name description inputs outputs chain; do
    if ! echo "$FRONTMATTER" | grep -q "^${field}:"; then
      ERRORS+="  FAIL: $skill — missing frontmatter field: $field\n"
      FAIL=$((FAIL + 1))
    else
      PASS=$((PASS + 1))
    fi
  done

  # Check Pipeline Continuation section (unless exempt)
  if ! is_exempt_pipeline "$skill"; then
    if ! grep -q "## Pipeline Continuation" "$SKILL_FILE"; then
      ERRORS+="  FAIL: $skill — missing '## Pipeline Continuation' section\n"
      FAIL=$((FAIL + 1))
    else
      PASS=$((PASS + 1))
    fi
  else
    PASS=$((PASS + 1))  # exempt, auto-pass
  fi

  # Check Audit Mode section for skills that should have it
  if should_have_audit "$skill"; then
    if ! grep -q "## Audit Mode" "$SKILL_FILE"; then
      ERRORS+="  FAIL: $skill — missing '## Audit Mode' section\n"
      FAIL=$((FAIL + 1))
    else
      PASS=$((PASS + 1))
    fi
  fi
done

echo "=== Tier 1: Skill Structure Validation ==="
echo "  $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  echo ""
  printf "$ERRORS"
  exit 1
else
  echo "  PASS — all skills have required structure"
  exit 0
fi
