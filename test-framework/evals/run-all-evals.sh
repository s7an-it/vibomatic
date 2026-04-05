#!/usr/bin/env bash
# Run all eval tiers.
# Tier 1 always runs (free, <10s).
# Tier 1.5, 2, and 3 run only if EVALS=1 is set.
#
# Usage:
#   ./run-all-evals.sh          # tier 1 only
#   EVALS=1 ./run-all-evals.sh  # all tiers
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo "  vibomatic Eval Framework"
echo "  $(date -Iseconds)"
echo "============================================"
echo ""

TIER1_PASS=0
TIER1_FAIL=0

# --- Tier 1: Static validation (always, free, <10s) ---
echo ">>> Tier 1: Static Validation (no LLM, <10s)"
echo ""

for script in "$SCRIPT_DIR/tier-1"/*.sh; do
  [[ ! -f "$script" ]] && continue
  script_name="$(basename "$script")"
  echo "  Running $script_name..."
  if bash "$script"; then
    TIER1_PASS=$((TIER1_PASS + 1))
  else
    TIER1_FAIL=$((TIER1_FAIL + 1))
  fi
  echo ""
done

echo ">>> Tier 1 Result: $TIER1_PASS scripts passed, $TIER1_FAIL failed"
echo ""

# --- Tier 1.5, 2, 3: Only with EVALS=1 ---
if [[ "${EVALS:-0}" != "1" ]]; then
  echo ">>> Tiers 1.5, 2, 3 skipped (set EVALS=1 to run)"
  echo ""

  if [[ $TIER1_FAIL -gt 0 ]]; then
    echo "RESULT: FAIL ($TIER1_FAIL tier-1 scripts failed)"
    exit 1
  else
    echo "RESULT: PASS (tier-1 only)"
    exit 0
  fi
fi

TIER15_EXIT=0
TIER2_EXIT=0
TIER3_EXIT=0

# --- Tier 1.5: Skill comprehension + triggering (~30-60s per test, ~5K tokens) ---
echo ">>> Tier 1.5: Skill Comprehension & Triggering (~5K tokens/test)"
echo ""

for script in "$SCRIPT_DIR/tier-1.5"/test-*.sh; do
  [[ ! -f "$script" ]] && continue
  script_name="$(basename "$script")"
  echo "  Running $script_name..."
  if bash "$script"; then
    echo "  $script_name: PASS"
  else
    TIER15_EXIT=1
    echo "  $script_name: FAIL"
  fi
  echo ""
done

# --- Tier 2: Integration scenarios (~50K tokens/scenario) ---
echo ">>> Tier 2: Integration Scenarios (~50K tokens/scenario)"
echo ""

if [[ -f "$SCRIPT_DIR/tier-2/run-tier2.sh" ]]; then
  if bash "$SCRIPT_DIR/tier-2/run-tier2.sh"; then
    echo "  Tier 2: PASS"
  else
    TIER2_EXIT=1
    echo "  Tier 2: FAIL"
  fi
else
  echo "  WARN: tier-2/run-tier2.sh not found"
fi
echo ""

# --- Tier 3: LLM-as-judge (~20K tokens/judgment) ---
echo ">>> Tier 3: LLM-as-Judge (~20K tokens/judgment)"
echo "  Note: Tier 3 requires skill output files to evaluate."
echo "  Run tier 2 first to produce outputs, then pass them to tier 3."
echo ""

# If tier-2 produced outputs, evaluate them
TIER2_RESULTS="$SCRIPT_DIR/results/tier-2"
LATEST_TIER2=$(ls -td "$TIER2_RESULTS"/*/ 2>/dev/null | head -1 || true)

if [[ -n "$LATEST_TIER2" && -d "$LATEST_TIER2" ]]; then
  echo "  Using tier-2 outputs from: $LATEST_TIER2"
  for output_file in "$LATEST_TIER2"/*-output.txt; do
    [[ ! -f "$output_file" ]] && continue
    scenario_name="$(basename "$output_file" -output.txt)"
    echo "  Judging: $scenario_name"
    for dim in completeness actionability; do
      bash "$SCRIPT_DIR/tier-3/run-tier3.sh" "$output_file" "$dim" || TIER3_EXIT=1
    done
  done
else
  echo "  No tier-2 outputs found. Run tier 2 first."
fi
echo ""

# --- Summary ---
echo "============================================"
echo "  Summary"
echo "============================================"
echo "  Tier 1:   $TIER1_PASS passed, $TIER1_FAIL failed"
echo "  Tier 1.5: $([ $TIER15_EXIT -eq 0 ] && echo 'PASS' || echo 'FAIL')"
echo "  Tier 2:   $([ $TIER2_EXIT -eq 0 ] && echo 'PASS' || echo 'FAIL')"
echo "  Tier 3:   $([ $TIER3_EXIT -eq 0 ] && echo 'PASS' || echo 'FAIL')"
echo ""

if [[ $TIER1_FAIL -gt 0 || $TIER15_EXIT -ne 0 || $TIER2_EXIT -ne 0 || $TIER3_EXIT -ne 0 ]]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
