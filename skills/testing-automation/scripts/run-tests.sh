#!/bin/bash
# run-tests.sh — Auto-detect test framework and package manager, then run tests.
# macOS bash 3.2 compatible (no associative arrays, no [[ regex =~ ]])
# Usage:
#   bash run-tests.sh [--path <file-or-dir>] [--coverage]

set -e

# ── Argument parsing ────────────────────────────────────────────────────────────
TEST_PATH=""
COVERAGE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      TEST_PATH="$2"
      shift 2
      ;;
    --coverage)
      COVERAGE=1
      shift
      ;;
    *)
      echo "Unknown flag: $1" >&2
      echo "Usage: bash run-tests.sh [--path <file-or-dir>] [--coverage]" >&2
      exit 1
      ;;
  esac
done

# ── Locate project root (directory containing package.json) ────────────────────
find_project_root() {
  local dir
  dir="$(pwd)"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/package.json" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo ""
}

PROJECT_ROOT="$(find_project_root)"
if [ -z "$PROJECT_ROOT" ]; then
  echo "Error: could not find package.json in current directory or any parent." >&2
  exit 1
fi

echo "Project root: $PROJECT_ROOT"

# ── Detect package manager ─────────────────────────────────────────────────────
detect_pkg_manager() {
  if [ -f "$PROJECT_ROOT/bun.lockb" ] || [ -f "$PROJECT_ROOT/bun.lock" ]; then
    echo "bun"
  elif [ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "$PROJECT_ROOT/yarn.lock" ]; then
    echo "yarn"
  else
    echo "npm"
  fi
}

PKG_MANAGER="$(detect_pkg_manager)"
echo "Package manager: $PKG_MANAGER"

# ── Read package.json deps as a single string for grep-based detection ─────────
PKG_JSON="$PROJECT_ROOT/package.json"
PKG_CONTENT="$(cat "$PKG_JSON")"

has_dep() {
  # $1 = dependency name (exact key match with quotes)
  echo "$PKG_CONTENT" | grep -q "\"$1\""
}

# ── Detect frameworks ─────────────────────────────────────────────────────────
HAS_VITEST=0
HAS_JEST=0
HAS_PLAYWRIGHT=0

if has_dep "vitest"; then
  HAS_VITEST=1
fi
if has_dep "jest"; then
  HAS_JEST=1
fi
if has_dep "@playwright/test"; then
  HAS_PLAYWRIGHT=1
fi

if [ "$HAS_VITEST" -eq 0 ] && [ "$HAS_JEST" -eq 0 ] && [ "$HAS_PLAYWRIGHT" -eq 0 ]; then
  echo "Error: no test framework detected in package.json." >&2
  echo "Install one of: vitest, jest, @playwright/test" >&2
  exit 1
fi

# ── Helper: build runner prefix ───────────────────────────────────────────────
# Returns the command prefix to run a package binary (e.g. "npx", "bunx", etc.)
runner_prefix() {
  case "$PKG_MANAGER" in
    bun)   echo "bun run" ;;
    pnpm)  echo "pnpm exec" ;;
    yarn)  echo "yarn" ;;
    *)     echo "npx" ;;
  esac
}

RUN="$(runner_prefix)"

# ── Run unit tests (Vitest preferred over Jest) ───────────────────────────────
run_unit_tests() {
  local extra_args=""

  if [ "$COVERAGE" -eq 1 ]; then
    extra_args="--coverage"
  fi

  if [ "$HAS_VITEST" -eq 1 ]; then
    echo ""
    echo "══════════════════════════════════════════"
    echo " Running Vitest"
    echo "══════════════════════════════════════════"
    local vitest_cmd="$RUN vitest run"
    if [ -n "$TEST_PATH" ]; then
      vitest_cmd="$vitest_cmd $TEST_PATH"
    fi
    if [ -n "$extra_args" ]; then
      vitest_cmd="$vitest_cmd $extra_args"
    fi
    echo "$ $vitest_cmd"
    cd "$PROJECT_ROOT" && eval "$vitest_cmd"

  elif [ "$HAS_JEST" -eq 1 ]; then
    echo ""
    echo "══════════════════════════════════════════"
    echo " Running Jest"
    echo "══════════════════════════════════════════"
    local jest_cmd="$RUN jest"
    if [ -n "$TEST_PATH" ]; then
      jest_cmd="$jest_cmd $TEST_PATH"
    fi
    if [ -n "$extra_args" ]; then
      jest_cmd="$jest_cmd $extra_args"
    fi
    jest_cmd="$jest_cmd --passWithNoTests"
    echo "$ $jest_cmd"
    cd "$PROJECT_ROOT" && eval "$jest_cmd"
  fi
}

# ── Run Playwright E2E tests ──────────────────────────────────────────────────
run_playwright_tests() {
  echo ""
  echo "══════════════════════════════════════════"
  echo " Running Playwright"
  echo "══════════════════════════════════════════"
  local pw_cmd="$RUN playwright test"
  if [ -n "$TEST_PATH" ]; then
    pw_cmd="$pw_cmd $TEST_PATH"
  fi
  echo "$ $pw_cmd"
  cd "$PROJECT_ROOT" && eval "$pw_cmd"
}

# ── Execute ───────────────────────────────────────────────────────────────────
UNIT_EXIT=0
PW_EXIT=0

if [ "$HAS_VITEST" -eq 1 ] || [ "$HAS_JEST" -eq 1 ]; then
  run_unit_tests || UNIT_EXIT=$?
fi

if [ "$HAS_PLAYWRIGHT" -eq 1 ]; then
  run_playwright_tests || PW_EXIT=$?
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo " Test Run Summary"
echo "══════════════════════════════════════════"

if [ "$HAS_VITEST" -eq 1 ] || [ "$HAS_JEST" -eq 1 ]; then
  if [ "$UNIT_EXIT" -eq 0 ]; then
    echo " Unit tests:  PASSED"
  else
    echo " Unit tests:  FAILED (exit $UNIT_EXIT)"
  fi
fi

if [ "$HAS_PLAYWRIGHT" -eq 1 ]; then
  if [ "$PW_EXIT" -eq 0 ]; then
    echo " E2E tests:   PASSED"
  else
    echo " E2E tests:   FAILED (exit $PW_EXIT)"
  fi
fi

if [ "$COVERAGE" -eq 1 ]; then
  echo ""
  echo " Coverage report:"
  if [ -d "$PROJECT_ROOT/coverage" ]; then
    echo "   $PROJECT_ROOT/coverage/index.html"
  fi
  if [ -d "$PROJECT_ROOT/coverage/lcov-report" ]; then
    echo "   $PROJECT_ROOT/coverage/lcov-report/index.html"
  fi
fi

echo "══════════════════════════════════════════"

# Exit with non-zero if anything failed
if [ "$UNIT_EXIT" -ne 0 ] || [ "$PW_EXIT" -ne 0 ]; then
  exit 1
fi

exit 0
