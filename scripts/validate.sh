#!/usr/bin/env bash
# Validate an installed .agents/ harness.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

INSTALL_SUBPATH=".agents"
AGENT_NAME="myAgent"
TARGET_REPO=""
ERRORS=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <target-repo-path>

Validate harness at <target-repo>/.agents/

Options:
  --path <dir>     Install subpath (default: .agents)
  --agent <name>   Agent folder name (default: myAgent)
  -h, --help       Show this help
EOF
}

warn() {
  echo "warn: $*" >&2
}

fail_check() {
  echo "fail: $*" >&2
  ERRORS=$((ERRORS + 1))
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) INSTALL_SUBPATH="${2:?}"; shift 2 ;;
    --agent) AGENT_NAME="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *)
      [[ -z "$TARGET_REPO" ]] && TARGET_REPO="$1" || die "unexpected argument: $1"
      shift
      ;;
  esac
done

[[ -n "$TARGET_REPO" ]] || { usage; exit 1; }

TARGET_REPO="$(cd "$TARGET_REPO" && pwd)"
AGENTS="${TARGET_REPO}/${INSTALL_SUBPATH}"
AGENT_DIR="${AGENTS}/${AGENT_NAME}"

[[ -d "$AGENTS" ]] || die "not found: ${AGENTS}"

check_file() {
  local rel="$1"
  if [[ ! -f "${AGENTS}/${rel}" ]]; then
    fail_check "missing file: ${rel}"
  fi
}

info "Validating ${AGENTS} (agent: ${AGENT_NAME})"

check_file "README.md"
check_file "${AGENT_NAME}/SESSION.md"
check_file "${AGENT_NAME}/MEMORY.md"
check_file "${AGENT_NAME}/IDENTITY.md"
check_file "${AGENT_NAME}/SOUL.md"
check_file "${AGENT_NAME}/USER.md"
check_file "${AGENT_NAME}/memory/full-cry-sdlc/Full_CRY_Overview.md"
check_file "${AGENT_NAME}/memory/wip_TopicX_work_plan.md"
check_file "${AGENT_NAME}/skills/code-log-entries/SKILL.md"

# At least one code log
if ! compgen -G "${AGENTS}/code-log/code-log-"*.md >/dev/null 2>&1; then
  fail_check "no code-log/code-log-*.md found"
fi

# Unreplaced placeholders
while IFS= read -r -d '' f; do
  if grep -q '{{[A-Z_]*}}' "$f" 2>/dev/null; then
    fail_check "unreplaced placeholder in: ${f#${AGENTS}/}"
  fi
done < <(find "$AGENTS" -type f \( -name '*.md' -o -name '*.sh' \) -print0 2>/dev/null || true)

# MEMORY size guideline
if [[ -f "${AGENT_DIR}/MEMORY.md" ]]; then
  lines=$(wc -l < "${AGENT_DIR}/MEMORY.md")
  if [[ "$lines" -gt 120 ]]; then
    warn "MEMORY.md has ${lines} lines (guideline: keep pickup snapshot lean)"
  fi
fi

if [[ "$ERRORS" -gt 0 ]]; then
  die "${ERRORS} validation error(s)"
fi

info "OK — harness validation passed."
