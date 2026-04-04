#!/usr/bin/env bash
# vibomatic worktree manager
#
# Central utility for creating, entering, promoting from, and cleaning up
# git worktrees. All worktrees live under .worktrees/ in the repo root.
#
# Usage:
#   scripts/worktree.sh create <branch-name> [--from <base>]
#   scripts/worktree.sh enter <branch-name>
#   scripts/worktree.sh status
#   scripts/worktree.sh remove <branch-name> [--force]
#   scripts/worktree.sh promote <branch-name>
#   scripts/worktree.sh list
#   scripts/worktree.sh cleanup
#   scripts/worktree.sh preflight
set -euo pipefail

# Find the MAIN repo root, even when called from inside a worktree.
# git rev-parse --show-toplevel returns the worktree root when inside one,
# so we use --git-common-dir to find the shared .git directory, then derive
# the main worktree root from that.
_find_repo_root() {
  local git_common_dir
  git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
  # git-common-dir returns the path to the shared .git dir
  # For main worktree: .git (relative) or /path/to/.git
  # For linked worktree: /path/to/.git (always absolute)
  if [[ "$git_common_dir" == ".git" ]]; then
    pwd
  else
    # Strip /.git from the end to get the repo root
    dirname "$git_common_dir"
  fi
}

REPO_ROOT="$(_find_repo_root 2>/dev/null || pwd)"
WORKTREE_DIR="$REPO_ROOT/.worktrees"
GITIGNORE="$REPO_ROOT/.gitignore"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; }
info() { echo -e "  ${CYAN}[INFO]${NC} $1"; }

# ============================================================
# PREFLIGHT — safety checks before any worktree operation
# ============================================================
preflight() {
  local errors=0

  echo "=== Worktree Preflight Checks ==="

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    fail "Not inside a git repository"
    return 1
  fi
  ok "Inside git repository"

  # Auto-fix: create .gitignore if missing
  if [[ ! -f "$GITIGNORE" ]]; then
    fail ".gitignore does not exist — creating it"
    echo -e "# Worktrees\n.worktrees/" > "$GITIGNORE"
    git add "$GITIGNORE"
    git commit -q -m "Add .gitignore with .worktrees/ exclusion"
    ok ".gitignore created and committed"
  fi

  # Auto-fix: add .worktrees/ to .gitignore if missing
  if ! grep -q '\.worktrees' "$GITIGNORE"; then
    fail ".gitignore does not ignore .worktrees/ — adding it"
    echo -e "\n# Worktrees\n.worktrees/" >> "$GITIGNORE"
    git add "$GITIGNORE"
    git commit -q -m "Add .worktrees/ to .gitignore"
    ok ".worktrees/ added to .gitignore and committed"
  else
    ok ".gitignore contains .worktrees/"
  fi

  if ! git check-ignore -q "$WORKTREE_DIR/" 2>/dev/null; then
    fail ".worktrees/ is not being ignored by git"
    errors=$((errors + 1))
  else
    ok ".worktrees/ is git-ignored (verified)"
  fi

  if ! git diff --quiet HEAD 2>/dev/null; then
    warn "Uncommitted changes on current branch"
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
# GUARD — intelligent worktree check for any skill
#
# Usage: worktree.sh guard --skill <name> --lane <lane> [--branch <name>]
#
# The worktree IS the feature branch. Everything that touches the feature
# runs there — code, tests, E2E, review. Only the squash-merge itself
# and post-merge verification run on main.
#
# Outputs one action:
#   STAY_MAIN      — skill runs on main, already there
#   NEED_WORKTREE  — skill needs a worktree, creates/enters it
#   IN_WORKTREE    — skill needs a worktree, already in one
#   LEAVE_WORKTREE — skill runs on main but we're in a worktree
# ============================================================

# Skills that run BEFORE the worktree exists (planning phase, on main)
PRE_WORKTREE_SKILLS="vision-sync domain-expert competitor-analysis persona-builder feature-discovery writing-spec spec-ac-sync journey-sync writing-ux-design writing-ui-design writing-technical-design spec-style-sync spec-code-sync writing-change-set bugfix-brief repo-conversion work-item-sync skill-finder research feature-marketing-insights journey-qa-ac-testing workflow-compass"

# Skills that run INSIDE the worktree (implementation + validation)
# Everything from execution through review happens in the branch
WORKTREE_SKILLS="executing-change-set review-protocol agentic-e2e-playwright"

# The squash-merge: transitions FROM worktree TO main
PROMOTE_SKILL="promoting-change-set"

# Post-merge verification on main
POST_MERGE_SKILLS="verifying-promotion"

cmd_guard() {
  local skill="" lane="" branch=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skill) skill="$2"; shift 2 ;;
      --lane)  lane="$2"; shift 2 ;;
      --branch) branch="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [[ -z "$skill" ]]; then
    echo "Usage: worktree.sh guard --skill <name> --lane <lane> [--branch <name>]"
    exit 1
  fi

  # Detect current location
  local cwd in_worktree=false current_branch=""
  cwd="$(pwd)"
  if [[ "$cwd" == "$WORKTREE_DIR"/* ]]; then
    in_worktree=true
    current_branch=$(basename "$(echo "$cwd" | sed "s|$WORKTREE_DIR/||" | cut -d/ -f1)")
  fi

  # --- Lanes that never use worktrees ---
  if [[ "$lane" == "drift" || "$lane" == "brownfield-conversion" ]]; then
    if $in_worktree; then
      echo "LEAVE_WORKTREE"
      warn "Lane '$lane' doesn't use worktrees — switch to main"
      echo "  cd $REPO_ROOT"
    else
      echo "STAY_MAIN"
    fi
    return 0
  fi

  # --- Pre-worktree skills (planning, specs, design — always on main) ---
  local is_pre=false
  for s in $PRE_WORKTREE_SKILLS; do
    [[ "$skill" == "$s" ]] && is_pre=true
  done

  if $is_pre; then
    if $in_worktree; then
      echo "STAY_MAIN"
      warn "'$skill' typically runs on main before the worktree is created"
      echo "  If you're doing delta work in an existing branch, this is fine."
    else
      echo "STAY_MAIN"
    fi
    return 0
  fi

  # --- Worktree skills (execution, testing, review — all in the branch) ---
  local is_wt=false
  for s in $WORKTREE_SKILLS; do
    [[ "$skill" == "$s" ]] && is_wt=true
  done

  if $is_wt; then
    if $in_worktree; then
      echo "IN_WORKTREE"
      ok "In worktree for '$skill'"
      echo "  Branch: $current_branch"
    else
      echo "NEED_WORKTREE"
      if [[ -n "$branch" ]]; then
        info "'$skill' needs the worktree — creating/entering '$branch'"
        cmd_create "$branch"
      else
        warn "'$skill' needs a worktree but no --branch specified"
        echo "  Read the branch name from the manifest, then:"
        echo "  scripts/worktree.sh create <branch-name>"
      fi
    fi
    return 0
  fi

  # --- Promoting: transitions from worktree to main ---
  if [[ "$skill" == "$PROMOTE_SKILL" ]]; then
    # promoting-change-set does the squash-merge FROM main.
    # But it first validates the branch, so the branch must exist.
    if $in_worktree; then
      echo "LEAVE_WORKTREE"
      info "'$skill' squash-merges to main — switch to repo root first"
      echo "  cd $REPO_ROOT"
      return 0
    fi

    local target="${branch:-}"
    if [[ -z "$target" ]]; then
      fail "'$skill' needs --branch to know which worktree to promote"
      return 1
    fi

    if [[ -d "$WORKTREE_DIR/$target" ]] || git show-ref --verify --quiet "refs/heads/$target" 2>/dev/null; then
      echo "STAY_MAIN"
      ok "On main. Branch '$target' ready to promote."
      echo "  Run: scripts/worktree.sh promote $target"
    else
      fail "Branch '$target' not found — nothing to promote"
      return 1
    fi
    return 0
  fi

  # --- Post-merge skills (verification on main, worktree already gone) ---
  local is_post=false
  for s in $POST_MERGE_SKILLS; do
    [[ "$skill" == "$s" ]] && is_post=true
  done

  if $is_post; then
    if $in_worktree; then
      echo "LEAVE_WORKTREE"
      warn "'$skill' runs on main after merge — worktree should already be removed"
      echo "  cd $REPO_ROOT"
    else
      echo "STAY_MAIN"
    fi
    return 0
  fi

  # --- Unknown skill: default to current location ---
  if $in_worktree; then
    echo "IN_WORKTREE"
    info "Unknown skill '$skill' — staying in current worktree"
  else
    echo "STAY_MAIN"
  fi
  return 0
}

# ============================================================
# STATUS — detect if currently inside a worktree
# ============================================================
cmd_status() {
  local cwd
  cwd="$(pwd)"

  # Check if we're inside .worktrees/
  if [[ "$cwd" == "$WORKTREE_DIR"/* ]]; then
    local branch_name
    branch_name=$(basename "$(echo "$cwd" | sed "s|$WORKTREE_DIR/||" | cut -d/ -f1)")
    local wt_path="$WORKTREE_DIR/$branch_name"

    echo "=== Worktree Status ==="
    ok "Inside worktree"
    echo "  Branch: $branch_name"
    echo "  Path:   $wt_path"

    if (cd "$wt_path" && ! git diff --quiet HEAD 2>/dev/null); then
      echo "  State:  dirty (uncommitted changes)"
    else
      echo "  State:  clean"
    fi

    local commit_count
    commit_count=$(cd "$wt_path" && git rev-list --count main..HEAD 2>/dev/null || echo "?")
    echo "  Commits ahead of main: $commit_count"
    return 0
  fi

  # Check if we're in the main worktree
  if [[ "$cwd" == "$REPO_ROOT"* && "$cwd" != "$WORKTREE_DIR"* ]]; then
    echo "=== Worktree Status ==="
    info "On main worktree (not inside a feature worktree)"

    # Show any active worktrees
    local count=0
    while IFS= read -r line; do
      local wt_path
      wt_path=$(echo "$line" | awk '{print $1}')
      [[ "$wt_path" == "$REPO_ROOT" ]] && continue
      count=$((count + 1))
    done < <(git worktree list)

    if [[ $count -gt 0 ]]; then
      echo "  Active worktrees: $count (use 'worktree.sh list' to see them)"
    fi
    return 1  # not in a worktree
  fi

  echo "=== Worktree Status ==="
  info "Outside vibomatic repository"
  return 1
}

# ============================================================
# CREATE — create a new worktree, or report if it already exists
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

  preflight || exit 1

  local wt_path="$WORKTREE_DIR/$branch_name"

  # If worktree already exists, report it and exit 0 (idempotent for chain resume)
  if [[ -d "$wt_path" ]]; then
    ok "Worktree already exists — resuming"
    echo "  Path:   $wt_path"
    echo "  Branch: $branch_name"

    local commit_count
    commit_count=$(cd "$wt_path" && git rev-list --count main..HEAD 2>/dev/null || echo "?")
    echo "  Commits ahead of main: $commit_count"

    if (cd "$wt_path" && ! git diff --quiet HEAD 2>/dev/null); then
      warn "Worktree has uncommitted changes"
    fi
    echo ""
    echo "  cd $wt_path"
    return 0
  fi

  echo ""
  echo "=== Creating Worktree ==="
  echo "  Branch: $branch_name"
  echo "  Base:   $base_ref"
  echo "  Path:   $wt_path"
  echo ""

  mkdir -p "$WORKTREE_DIR"

  # If branch already exists (e.g., from a prior remote push), use it
  if git show-ref --verify --quiet "refs/heads/$branch_name" 2>/dev/null; then
    info "Branch '$branch_name' already exists — attaching worktree to it"
    git worktree add "$wt_path" "$branch_name" 2>&1
  else
    git worktree add -b "$branch_name" "$wt_path" "$base_ref" 2>&1
  fi

  ok "Worktree created"

  # --- Project setup (auto-detect) ---
  _run_setup "$wt_path"

  # --- Baseline tests ---
  _run_baseline_tests "$wt_path"

  echo ""
  echo "=== Worktree Ready ==="
  echo "  Path:   $wt_path"
  echo "  Branch: $branch_name"
  echo ""
  echo "  cd $wt_path"
  echo ""
}

# ============================================================
# ENTER — print the cd command for an existing worktree
# ============================================================
cmd_enter() {
  local branch_name="${1:-}"

  if [[ -z "$branch_name" ]]; then
    echo "Usage: worktree.sh enter <branch-name>"
    exit 1
  fi

  local wt_path="$WORKTREE_DIR/$branch_name"

  if [[ ! -d "$wt_path" ]]; then
    fail "No worktree at $wt_path"
    echo "  Available worktrees:"
    for d in "$WORKTREE_DIR"/*/; do
      [[ -d "$d" ]] && echo "    $(basename "$d")"
    done 2>/dev/null || echo "    (none)"
    exit 1
  fi

  echo "=== Entering Worktree ==="
  echo "  Branch: $branch_name"
  echo "  Path:   $wt_path"

  local commit_count
  commit_count=$(cd "$wt_path" && git rev-list --count main..HEAD 2>/dev/null || echo "?")
  echo "  Commits ahead of main: $commit_count"

  if (cd "$wt_path" && ! git diff --quiet HEAD 2>/dev/null); then
    warn "Uncommitted changes present"
  fi

  echo ""
  echo "  cd $wt_path"
}

# ============================================================
# PROMOTE — squash-merge a worktree branch to main, then remove it
# Full lifecycle: validate → checkout main → squash → commit → remove
# ============================================================
cmd_promote() {
  local branch_name="${1:-}"

  if [[ -z "$branch_name" ]]; then
    echo "Usage: worktree.sh promote <branch-name>"
    exit 1
  fi

  local wt_path="$WORKTREE_DIR/$branch_name"

  if [[ ! -d "$wt_path" ]]; then
    fail "No worktree at $wt_path"
    exit 1
  fi

  echo "=== Promoting Worktree: $branch_name ==="
  echo ""

  # 1. Check worktree is clean
  if (cd "$wt_path" && ! git diff --quiet HEAD 2>/dev/null); then
    fail "Worktree has uncommitted changes — commit or discard before promoting"
    exit 1
  fi
  ok "Worktree is clean"

  # 2. Show what will be promoted
  local commit_count
  commit_count=$(cd "$wt_path" && git rev-list --count main..HEAD 2>/dev/null || echo "?")
  info "$commit_count commit(s) ahead of main"

  echo ""
  echo "  Files changed:"
  git diff --stat "main...$branch_name" 2>/dev/null | sed 's/^/    /'

  # 3. Switch to main and squash-merge
  echo ""
  echo "=== Squash Merge ==="

  # Must be in the main worktree for the merge
  cd "$REPO_ROOT"

  if ! git diff --quiet HEAD 2>/dev/null; then
    fail "Main worktree has uncommitted changes — clean it first"
    exit 1
  fi

  git merge --squash "$branch_name" 2>&1
  ok "Squash staged on main"

  echo ""
  echo "  Staged diff:"
  git diff --cached --stat | sed 's/^/    /'

  echo ""
  info "Squash is staged but NOT committed."
  info "Review the diff, then commit:"
  echo "    git commit -m \"Promote $branch_name: <description>\""
  echo ""
  info "After committing, remove the worktree:"
  echo "    scripts/worktree.sh remove $branch_name"
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

  # Must not be inside the worktree we're removing
  local cwd
  cwd="$(pwd)"
  if [[ "$cwd" == "$wt_path"* ]]; then
    info "Currently inside the worktree — switching to repo root"
    cd "$REPO_ROOT"
  fi

  if (cd "$wt_path" && ! git diff --quiet HEAD 2>/dev/null); then
    if $force; then
      warn "Uncommitted changes — force removing"
    else
      fail "Uncommitted changes in worktree. Use --force to discard, or commit first."
      exit 1
    fi
  fi

  if $force; then
    git worktree remove --force "$wt_path" 2>&1
  else
    git worktree remove "$wt_path" 2>&1
  fi

  ok "Worktree removed"

  # Delete branch if merged
  if git branch --merged main 2>/dev/null | grep -q " $branch_name$"; then
    git branch -d "$branch_name" 2>&1 && ok "Branch $branch_name deleted (was merged)"
  else
    warn "Branch $branch_name kept (not merged to main)"
  fi

  # Remove .worktrees/ if now empty
  if [[ -d "$WORKTREE_DIR" ]] && [[ -z "$(ls -A "$WORKTREE_DIR" 2>/dev/null)" ]]; then
    rmdir "$WORKTREE_DIR"
    ok "Removed empty .worktrees/ directory"
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

    [[ "$wt_path" == "$REPO_ROOT" ]] && continue

    count=$((count + 1))
    echo "  $count. $wt_branch"
    echo "     Path:   $wt_path"
    echo "     Commit: $wt_hash"

    if (cd "$wt_path" 2>/dev/null && ! git diff --quiet HEAD 2>/dev/null); then
      echo -e "     Status: ${YELLOW}dirty${NC}"
    else
      echo "     Status: clean"
    fi

    local ahead
    ahead=$(cd "$wt_path" 2>/dev/null && git rev-list --count main..HEAD 2>/dev/null || echo "?")
    echo "     Ahead:  $ahead commit(s)"
    echo ""
  done < <(git worktree list)

  if [[ $count -eq 0 ]]; then
    echo "  No active worktrees."
    echo ""
    echo "  Create one: scripts/worktree.sh create <branch-name>"
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

  local pruned
  pruned=$(git worktree prune -v 2>&1)
  if [[ -n "$pruned" ]]; then
    echo "$pruned" | sed 's/^/  /'
    cleaned=$((cleaned + 1))
  else
    ok "No stale worktree references"
  fi

  if [[ -d "$WORKTREE_DIR" ]]; then
    local known_paths
    known_paths=$(git worktree list --porcelain | grep '^worktree ' | sed 's/^worktree //')

    for dir in "$WORKTREE_DIR"/*/; do
      [[ ! -d "$dir" ]] && continue
      dir="${dir%/}"

      if ! echo "$known_paths" | grep -q "^${dir}$"; then
        warn "Orphaned directory: $dir"
        rm -rf "$dir"
        ok "Removed $dir"
        cleaned=$((cleaned + 1))
      fi
    done

    if [[ -d "$WORKTREE_DIR" ]] && [[ -z "$(ls -A "$WORKTREE_DIR" 2>/dev/null)" ]]; then
      rmdir "$WORKTREE_DIR"
      ok "Removed empty .worktrees/ directory"
    fi
  fi

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
# HELPERS
# ============================================================
_run_setup() {
  local wt_path="$1"
  echo ""
  echo "=== Project Setup ==="

  if [[ -f "$wt_path/package.json" ]]; then
    echo "  Detected: Node.js"
    if [[ -f "$wt_path/package-lock.json" ]]; then
      (cd "$wt_path" && npm ci --silent 2>&1) && ok "npm ci" || warn "npm ci failed"
    elif [[ -f "$wt_path/yarn.lock" ]]; then
      (cd "$wt_path" && yarn install --frozen-lockfile --silent 2>&1) && ok "yarn install" || warn "yarn failed"
    else
      (cd "$wt_path" && npm install --silent 2>&1) && ok "npm install" || warn "npm install failed"
    fi
  elif [[ -f "$wt_path/Cargo.toml" ]]; then
    echo "  Detected: Rust"
    (cd "$wt_path" && cargo build 2>&1) && ok "cargo build" || warn "cargo build failed"
  elif [[ -f "$wt_path/requirements.txt" ]]; then
    echo "  Detected: Python (requirements.txt)"
    (cd "$wt_path" && pip install -r requirements.txt -q 2>&1) && ok "pip install" || warn "pip failed"
  elif [[ -f "$wt_path/pyproject.toml" ]]; then
    echo "  Detected: Python (pyproject.toml)"
    (cd "$wt_path" && pip install -e . -q 2>&1) && ok "pip install" || warn "pip failed"
  elif [[ -f "$wt_path/go.mod" ]]; then
    echo "  Detected: Go"
    (cd "$wt_path" && go build ./... 2>&1) && ok "go build" || warn "go build failed"
  else
    ok "No package manager detected — skipping"
  fi
}

_run_baseline_tests() {
  local wt_path="$1"
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
}

# ============================================================
# MAIN
# ============================================================
usage() {
  cat <<'USAGE'
vibomatic worktree manager

Usage:
  scripts/worktree.sh <command> [options]

Commands:
  guard              Intelligent worktree check for any skill
    --skill <name>   Current skill name
    --lane <lane>    Current lane (greenfield, bugfix, etc.)
    --branch <name>  Branch name (from manifest, optional)

  create <branch>    Create a new worktree (idempotent — resumes if exists)
    --from <ref>     Base on a specific ref (default: HEAD)

  enter <branch>     Show path to enter an existing worktree

  status             Detect if currently inside a worktree

  promote <branch>   Squash-merge branch to main (stages but does not commit)

  remove <branch>    Remove a worktree and clean up
    --force          Remove even with uncommitted changes

  list               Show all active worktrees with status

  cleanup            Find and remove orphaned worktrees

  preflight          Run safety checks without creating anything

Worktree conditions:
  ALWAYS:  executing-change-set, promoting-change-set, framework-test autopilot
  NEVER:   spec writing, vision/persona, reviews/audits
  OPTIONAL: writing-change-set (simulation), tech design (prototyping)

Branch naming convention:
  feature-<name>     Greenfield / brownfield feature
  bugfix-<name>      Bugfix lane
  refactor-<name>    Refactor lane
  test-<name>        Framework test / eval
USAGE
}

case "${1:-}" in
  guard)    shift; cmd_guard "$@" ;;
  create)   shift; cmd_create "$@" ;;
  enter)    shift; cmd_enter "$@" ;;
  status)   cmd_status ;;
  promote)  shift; cmd_promote "$@" ;;
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
