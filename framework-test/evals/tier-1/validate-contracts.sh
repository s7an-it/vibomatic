#!/usr/bin/env bash
# Tier 1: Validate input/output contracts across skills.
# Checks: input paths use valid patterns, output paths don't conflict,
# status transitions are valid lifecycle values.
# No LLM, <10s.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
MANIFEST="$REPO_ROOT/skills-manifest.json"

PASS=0
FAIL=0
ERRORS=""

VALID_STATUSES="ACTIVE DRAFT UX-REVIEWED DESIGNED BASELINED CHANGE-SET-APPROVED PROMOTED VERIFIED"

# Collect all output paths to detect conflicts
declare -A OUTPUT_PATHS  # path -> skill that produces it

# Known shared output paths (multiple skills intentionally produce these)
KNOWN_SHARED_OUTPUTS=(
  "docs/specs/work-items/INDEX.md"   # repo-conversion and work-item-sync both manage this
  "docs/specs/research-log.md"       # skill-finder and research both append to this
)

SKILLS=$(node -e "
  const m = require('$MANIFEST');
  m.includedSkills.forEach(s => console.log(s));
")

for skill in $SKILLS; do
  SKILL_FILE="$REPO_ROOT/$skill/SKILL.md"
  [[ ! -f "$SKILL_FILE" ]] && continue

  FRONTMATTER=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$SKILL_FILE")

  # Validate input paths use recognized patterns
  # Use while-read to handle paths with spaces (process substitution to avoid subshell)
  while IFS= read -r ipath; do
    [[ -z "$ipath" ]] && continue
    # Allow known path patterns:
    # - docs/specs/*, docs/plans/*, references/*, REPO_MODES.md, DESIGN*
    # - framework-test/*, package.json, tsconfig.json, e2e/*, .agents/*
    # - Descriptive pseudo-paths in parens like "(branch checkpoint commits)"
    if ! echo "$ipath" | grep -qE '^(docs/|references/|REPO_MODES|framework-test/|DESIGN|package\.json|tsconfig\.json|e2e/|\.agents/|\()'; then
      ERRORS+="  FAIL: $skill — input path '$ipath' doesn't match expected patterns\n"
      FAIL=$((FAIL + 1))
    else
      PASS=$((PASS + 1))
    fi
  done < <(echo "$FRONTMATTER" | grep -oP 'path:\s*"\K[^"]*' || true)

  # Validate output status values
  OUTPUT_STATUSES=$(echo "$FRONTMATTER" | grep -oP 'status:\s*(\S+)' | sed 's/status:\s*//' || true)
  for status in $OUTPUT_STATUSES; do
    if ! echo "$VALID_STATUSES" | grep -qw "$status"; then
      ERRORS+="  FAIL: $skill — invalid output status: $status (valid: $VALID_STATUSES)\n"
      FAIL=$((FAIL + 1))
    else
      PASS=$((PASS + 1))
    fi
  done

  # Collect output paths for conflict detection
  while IFS= read -r opath; do
    [[ -z "$opath" ]] && continue
    # Skip glob patterns (contain * or <) or pseudo-paths in parens
    if echo "$opath" | grep -qE '[*<(]'; then
      PASS=$((PASS + 1))
      continue
    fi
    if [[ -n "${OUTPUT_PATHS[$opath]:-}" ]]; then
      existing="${OUTPUT_PATHS[$opath]}"
      # Same output path from two different skills is a conflict
      if [[ "$existing" != "$skill" ]]; then
        # Check if this is a known shared output
        is_known=false
        for known in "${KNOWN_SHARED_OUTPUTS[@]}"; do
          [[ "$opath" == "$known" ]] && is_known=true && break
        done
        if $is_known; then
          PASS=$((PASS + 1))  # known, acceptable
        else
          ERRORS+="  FAIL: output path '$opath' produced by both '$existing' and '$skill'\n"
          FAIL=$((FAIL + 1))
        fi
      fi
    else
      OUTPUT_PATHS["$opath"]="$skill"
      PASS=$((PASS + 1))
    fi
  done < <(echo "$FRONTMATTER" | awk '/produces:/,/^[a-z]/' | grep -oP 'path:\s*"\K[^"]*' || true)
done

echo "=== Tier 1: Contract Validation ==="
echo "  $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  echo ""
  printf "$ERRORS"
  exit 1
else
  echo "  PASS — all contracts valid"
  exit 0
fi
