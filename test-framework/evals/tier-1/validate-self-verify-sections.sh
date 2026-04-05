#!/usr/bin/env bash
# Tier 1: Validate that every skill with self_verify: true has a Self-Verify
# section containing a table with PASS/FAIL column.
# No LLM, <10s.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
MANIFEST="$REPO_ROOT/skills-manifest.json"

PASS=0
FAIL=0
ERRORS=""

SKILLS=$(node -e "
  const m = require('$MANIFEST');
  m.includedSkills.forEach(s => console.log(s));
")

for skill in $SKILLS; do
  SKILL_FILE="$REPO_ROOT/$skill/SKILL.md"
  [[ ! -f "$SKILL_FILE" ]] && continue

  FRONTMATTER=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$SKILL_FILE")

  # Check if self_verify is true
  if echo "$FRONTMATTER" | grep -q "self_verify: true"; then
    # Must have a Self-Verify section (## or ### heading)
    if ! grep -qE '^#{2,3} Self-Verify' "$SKILL_FILE"; then
      ERRORS+="  FAIL: $skill — self_verify: true but missing 'Self-Verify' section\n"
      FAIL=$((FAIL + 1))
      continue
    fi

    # The Self-Verify section must contain a table with PASS or FAIL
    # Extract content after Self-Verify heading until next same-or-higher heading
    SELF_VERIFY_CONTENT=$(awk '/^#{2,3} Self-Verify/,/^#{2,3} [^S]/' "$SKILL_FILE")

    if ! echo "$SELF_VERIFY_CONTENT" | grep -qE 'PASS|FAIL'; then
      ERRORS+="  FAIL: $skill — Self-Verify section exists but has no PASS/FAIL column\n"
      FAIL=$((FAIL + 1))
    else
      PASS=$((PASS + 1))
    fi

    # Check for table structure (pipe-delimited rows)
    if ! echo "$SELF_VERIFY_CONTENT" | grep -qE '^\|'; then
      ERRORS+="  FAIL: $skill — Self-Verify section has no table (expected | delimited rows)\n"
      FAIL=$((FAIL + 1))
    else
      PASS=$((PASS + 1))
    fi
  fi
done

echo "=== Tier 1: Self-Verify Section Validation ==="
echo "  $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  echo ""
  printf "$ERRORS"
  exit 1
else
  echo "  PASS — all self-verify sections valid"
  exit 0
fi
