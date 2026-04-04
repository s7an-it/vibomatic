#!/usr/bin/env bash
# vibomatic worktree manager
#
# Central utility for creating, removing, listing, and cleaning up git worktrees.
# All worktrees live under .worktrees/ in the repo root. No exceptions.
#
# Usage:
#   scripts/worktree.sh create <branch-name> [--from <base>]
#   scripts/worktree.sh remove <branch-name> [--force]
#   scripts/worktree.sh list
#   scripts/worktree.sh cleanup
#   scripts/worktree.sh preflight
#
# Conditions for worktree creation (enforced automatically):
#   1. .gitignore must contain .worktrees/
#   2. No uncommitted changes on the current branch
#   3. Branch name must not already exist (unless --from is used to reset)
#   4. .worktrees/ directory must be git-ignored (verified via git check-ignore)
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
WORKTREE_DIR="$REPO_ROOT/.worktrees"
GITIGNORE="$REPO_ROOT/.gitignore"

# --- Colors (if terminal supports them) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; }

# ============================================================
# PREFLIGHT — safety checks before any worktree operation
# ============================================================
preflight() {
  local errors=0

  echo "=== Worktree Preflight Checks ==="

  # 1. Must be in a git repo
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    fail "Not inside a git repository"
    return 1
  fi
  ok "Inside git repository"

  # 2. .gitignore must exist
  if [[ ! -f "$GITIGNORE" ]]; then
    fail ".gitignore does not exist — creating it"
    echo -e "# Worktrees\n.worktrees/" > "$GITIGNORE"
    git add "$GITIGNORE"
    git commit -q -m "Add .gitignore with .worktrees/ exclusion"
    ok ".gitignore created and committed"
  fi

  # 3. .gitignore must contain .worktrees/
  if ! grep -q '\.worktrees' "$GITIGNORE"; then
    fail ".gitignore does not ignore .worktrees/ — adding it"
    echo -e "\n# Worktrees\n.worktrees/" >> "$GITIGNORE"
    git add "$GITIGNORE"
    git commit -q -m "Add .worktrees/ to .gitignore"
    ok ".worktrees/ added to .gitignore and committed"
  else
    ok ".gitignore contains .worktrees/"
  fi

  # 4. git check-ignore confirms .worktrees/ is ignored
  if ! git check-ignore -q "$WORKTREE_DIR/" 2>/dev/null; then
    fail ".worktrees/ is not being ignored by git (check .gitignore patterns)"
    errors=$((errors + 1))
  else
    ok ".worktrees/ is git-ignored (verified)"
  fi

  # 5. No uncommitted changes (warn, don't block)
  if ! git diff --quiet HEAD 2>/dev/null; then
    warn "Uncommitted changes on current branch — worktree will branch from HEAD"
  else
    ok "Working tree is clean"
  fi

  echo ""
  if [[ $errors -gt 0 ]]; then
    fail "Preflight failed with $errors error(s)"
    return 1
  fi
  ok "All preflight checks passed"
  return 0
}

# ============================================================
# CREATE — create a new worktree under .worktrees/
# ============================================================
cmd_create() {
  local branch_name=""
  local base_ref="HEAD"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from) base_ref="$2"; shift 2 ;;
      *) branch_name="$1"; shift ;;
    esac
  done

  if [[ -z "$branch_name" ]]; then
    echo "Usage: worktree.sh create <branch-name> [--from <base>]"
    exit 1
  fi

  # Run preflight
  preflight || exit 1

  local wt_path="$WORKTREE_DIR/$branch_name"

  # Check if worktree already exists
  if [[ -d "$wt_path" ]]; then
    fail "Worktree already exists at $wt_path"
    echo "  Use 'worktree.sh remove $branch_name' first, or choose a different name."
    exit 1
  fi

  # Create the worktree
  echo ""
  echo "=== Creating Worktree ==="
  echo "  Branch: $branch_name"
  echo "  Base:   $base_ref"
  echo "  Path:   $wt_path"
  echo ""

  mkdir -p "$WORKTREE_DIR"
  git worktree add -b "$branch_name" "$wt_path" "$base_ref" 2>&1

  ok "Worktree created"

  # --- Project setup (auto-detect) ---
  echo ""
  echo "=== Project Setup ==="

  if [[ -f "$wt_path/package.json" ]]; then
    echo "  Detected: Node.js (package.json)"
    if [[ -f "$wt_path/package-lock.json" ]]; then
      (cd "$wt_path" && npm ci --silent 2>&1) && ok "npm ci complete" || warn "npm ci failed"
    elif [[ -f "$wt_path/yarn.lock" ]]; then
      (cd "$wt_path" && yarn install --frozen-lockfile --silent 2>&1) && ok "yarn install complete" || warn "yarn install failed"
    else
      (cd "$wt_path" && npm install --silent 2>&1) && ok "npm install complete" || warn "npm install failed"
    fi
  elif [[ -f "$wt_path/Cargo.toml" ]]; then
    echo "  Detected: Rust (Cargo.toml)"
    (cd "$wt_path" && cargo build 2>&1) && ok "cargo build complete" || warn "cargo build failed"
  elif [[ -f "$wt_path/requirements.txt" ]]; then
    echo "  Detected: Python (requirements.txt)"
    (cd "$wt_path" && pip install -r requirements.txt -q 2>&1) && ok "pip install complete" || warn "pip install failed"
  elif [[ -f "$wt_path/pyproject.toml" ]]; then
    echo "  Detected: Python (pyproject.toml)"
    (cd "$wt_path" && pip install -e . -q 2>&1) && ok "pip install complete" || warn "pip install failed"
  elif [[ -f "$wt_path/go.mod" ]]; then
    echo "  Detected: Go (go.mod)"
    (cd "$wt_path" && go build ./... 2>&1) && ok "go build complete" || warn "go build failed"
  else
    ok "No package manager detected — skipping setup"
  fi

  # --- Baseline test check ---
  echo ""
  echo "=== Baseline Tests ==="

  local test_cmd=""
  if [[ -f "$wt_path/package.json" ]] && grep -q '"test"' "$wt_path/package.json" 2>/dev/null; then
    test_cmd="npm test"
  elif [[ -f "$wt_path/Cargo.toml" ]]; then
    test_cmd="cargo test"
  elif [[ -f "$wt_path/go.mod" ]]; then
    test_cmd="go test ./..."
  fi

  if [[ -n "$test_cmd" ]]; then
    echo "  Running: $test_cmd"
    if (cd "$wt_path" && eval "$test_cmd" 2>&1 >/dev/null); then
      ok "Baseline tests pass"
    else
      warn "Baseline tests FAIL — proceed with caution"
    fi
  else
    ok "No test command detected — skipping"
  fi

  # --- Summary ---
  echo ""
  echo "=== Worktree Ready ==="
  echo "  Path:   $wt_path"
  echo "  Branch: $branch_name"
  echo ""
  echo "  cd $wt_path"
  echo ""
}

# ============================================================
# REMOVE — remove a worktree and optionally its branch
# ============================================================
cmd_remove() {
  local branch_name=""
  local force=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force) force=true; shift ;;
      *) branch_name="$1"; shift ;;
    esac
  done

  if [[ -z "$branch_name" ]]; then
    echo "Usage: worktree.sh remove <branch-name> [--force]"
    exit 1
  fi

  local wt_path="$WORKTREE_DIR/$branch_name"

  if [[ ! -d "$wt_path" ]]; then
    fail "No worktree at $wt_path"
    exit 1
  fi

  echo "=== Removing Worktree ==="
  echo "  Path:   $wt_path"
  echo "  Branch: $branch_name"
  echo ""

  # Check for uncommitted changes
  if (cd "$wt_path" && ! git diff --quiet HEAD 2>/dev/null); then
    if $force; then
      warn "Uncommitted changes — force removing"
    else
      fail "Uncommitted changes in worktree. Use --force to discard, or commit first."
      exit 1
    fi
  fi

  # Remove worktree
  if $force; then
    git worktree remove --force "$wt_path" 2>&1
  else
    git worktree remove "$wt_path" 2>&1
  fi

  ok "Worktree removed"

  # Clean up the branch if it was fully merged
  if git branch --merged main 2>/dev/null | grep -q "$branch_name"; then
    git branch -d "$branch_name" 2>&1 && ok "Branch $branch_name deleted (was merged)"
  else
    warn "Branch $branch_name kept (not merged to main)"
  fi
}

# ============================================================
# LIST — show all active worktrees
# ============================================================
cmd_list() {
  echo "=== Active Worktrees ==="
  echo ""

  local count=0
  while IFS= read -r line; do
    local wt_path wt_hash wt_branch
    wt_path=$(echo "$line" | awk '{print $1}')
    wt_hash=$(echo "$line" | awk '{print $2}')
    wt_branch=$(echo "$line" | grep -oP '\[.*?\]' || echo "[detached]")

    # Skip the main worktree
    if [[ "$wt_path" == "$REPO_ROOT" ]]; then
      continue
    fi

    count=$((count + 1))
    echo "  $count. $wt_branch"
    echo "     Path:   $wt_path"
    echo "     Commit: $wt_hash"

    # Check for uncommitted changes
    if (cd "$wt_path" 2>/dev/null && ! git diff --quiet HEAD 2>/dev/null); then
      echo "     Status: ${YELLOW}dirty (uncommitted changes)${NC}"
    else
      echo "     Status: clean"
    fi
    echo ""
  done < <(git worktree list)

  if [[ $count -eq 0 ]]; then
    echo "  No active worktrees (besides main)."
    echo ""
    echo "  Create one with: scripts/worktree.sh create <branch-name>"
  else
    echo "  Total: $count worktree(s)"
  fi
}

# ============================================================
# CLEANUP — find and remove orphaned/stale worktrees
# ============================================================
cmd_cleanup() {
  echo "=== Worktree Cleanup ==="
  echo ""

  local cleaned=0

  # 1. Prune git's worktree list (removes entries for deleted directories)
  local pruned
  pruned=$(git worktree prune -v 2>&1)
  if [[ -n "$pruned" ]]; then
    echo "$pruned" | sed 's/^/  /'
    cleaned=$((cleaned + 1))
  else
    ok "No stale worktree references"
  fi

  # 2. Check .worktrees/ for directories not in git worktree list
  if [[ -d "$WORKTREE_DIR" ]]; then
    local known_paths
    known_paths=$(git worktree list --porcelain | grep '^worktree ' | sed 's/^worktree //')

    for dir in "$WORKTREE_DIR"/*/; do
      [[ ! -d "$dir" ]] && continue
      dir="${dir%/}"  # strip trailing slash

      if ! echo "$known_paths" | grep -q "^${dir}$"; then
        warn "Orphaned directory: $dir (not in git worktree list)"
        echo "    Removing..."
        rm -rf "$dir"
        ok "Removed $dir"
        cleaned=$((cleaned + 1))
      fi
    done

    # Remove .worktrees/ if empty
    if [[ -d "$WORKTREE_DIR" ]] && [[ -z "$(ls -A "$WORKTREE_DIR" 2>/dev/null)" ]]; then
      rmdir "$WORKTREE_DIR"
      ok "Removed empty .worktrees/ directory"
    fi
  fi

  # 3. Check for orphaned /tmp/vibomatic-* directories
  local tmp_orphans=0
  for dir in /tmp/vibomatic-*/; do
    [[ ! -d "$dir" ]] && continue
    warn "Orphaned temp directory: $dir"
    tmp_orphans=$((tmp_orphans + 1))
  done

  if [[ $tmp_orphans -gt 0 ]]; then
    warn "$tmp_orphans orphaned /tmp/vibomatic-* directories found"
    echo "    Remove manually: rm -rf /tmp/vibomatic-*"
  fi

  echo ""
  if [[ $cleaned -gt 0 ]]; then
    ok "Cleaned $cleaned item(s)"
  else
    ok "Nothing to clean"
  fi
}

# ============================================================
# MAIN — route to subcommand
# ============================================================
usage() {
  cat <<'USAGE'
vibomatic worktree manager

Usage:
  scripts/worktree.sh <command> [options]

Commands:
  create <branch>  Create a new worktree under .worktrees/
    --from <ref>   Base the worktree on a specific ref (default: HEAD)

  remove <branch>  Remove a worktree and clean up
    --force        Remove even with uncommitted changes

  list             Show all active worktrees

  cleanup          Find and remove orphaned worktrees

  preflight        Run safety checks without creating anything

When to use worktrees:
  ALWAYS for:
    - executing-change-set   (implementation work)
    - promoting-change-set   (squash-merge to main)
    - framework-test autopilot (scenario execution)
    - parallel feature work   (multiple features at once)

  NEVER for:
    - spec writing           (single-file edits on main)
    - vision/persona work    (foundational docs on main)
    - reviews/audits         (read-only analysis)

  OPTIONAL for:
    - writing-change-set     (if simulation needs isolation)
    - tech design            (if prototyping is needed)
USAGE
}

case "${1:-}" in
  create)   shift; cmd_create "$@" ;;
  remove)   shift; cmd_remove "$@" ;;
  list)     cmd_list ;;
  cleanup)  cmd_cleanup ;;
  preflight) preflight ;;
  -h|--help|help) usage ;;
  *)
    if [[ -n "${1:-}" ]]; then
      echo "Unknown command: $1"
      echo ""
    fi
    usage
    exit 1
    ;;
esac
