#!/usr/bin/env bash
# Install the portable agent harness into a target repository.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

INSTALL_SUBPATH=".agents"
AGENT_NAME="myAgent"
FORCE=0
TARGET_REPO=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <target-repo-path>

Install the agent harness from template/ into <target-repo>/.agents/

Options:
  --force            Overwrite existing .agents/ (destructive)
  --path <dir>       Install subpath relative to repo root (default: .agents)
  --agent <name>     Agent folder name (default: myAgent)
  -h, --help         Show this help

Examples:
  $(basename "$0") ~/projects/my-app
  $(basename "$0") --force --path .agents ~/projects/my-app
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --path) INSTALL_SUBPATH="${2:?}"; shift 2 ;;
    --agent) AGENT_NAME="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *)
      if [[ -n "$TARGET_REPO" ]]; then
        die "unexpected argument: $1"
      fi
      TARGET_REPO="$1"
      shift
      ;;
  esac
done

[[ -n "$TARGET_REPO" ]] || { usage; exit 1; }

TARGET_REPO="$(cd "$TARGET_REPO" && pwd)"
DEST="${TARGET_REPO}/${INSTALL_SUBPATH}"

[[ -d "$TEMPLATE_DIR" ]] || die "template not found at ${TEMPLATE_DIR}"

if [[ -e "$DEST" ]]; then
  if [[ "$FORCE" -ne 1 ]]; then
    die "${DEST} already exists. Use --force to overwrite."
  fi
  info "Removing existing ${DEST} (--force)"
  rm -rf "$DEST"
fi

info "Installing harness to ${DEST}"

mkdir -p "$DEST"
cp -a "${TEMPLATE_DIR}/." "$DEST/"

CODE_LOG_DATE="$(today_ymd)"
INSTALL_DATE="$(today_iso)"

# Defaults — override via env when scripting non-interactively
PROJECT_NAME="${PROJECT_NAME:-My Project}"
USER_NAME="${USER_NAME:-Your Name}"
USER_WHAT_TO_CALL="${USER_WHAT_TO_CALL:-Your Name}"
AGENT_DISPLAY_NAME="${AGENT_DISPLAY_NAME:-myAgent}"

if [[ -t 0 ]]; then
  read -r -p "Project name [${PROJECT_NAME}]: " _pn || true
  [[ -n "${_pn:-}" ]] && PROJECT_NAME="$_pn"
  read -r -p "Your name [${USER_NAME}]: " _un || true
  [[ -n "${_un:-}" ]] && USER_NAME="$_un"
  read -r -p "What should the agent call you? [${USER_WHAT_TO_CALL}]: " _uc || true
  [[ -n "${_uc:-}" ]] && USER_WHAT_TO_CALL="$_uc"
  read -r -p "Agent display name [${AGENT_DISPLAY_NAME}]: " _ad || true
  [[ -n "${_ad:-}" ]] && AGENT_DISPLAY_NAME="$_ad"
fi

apply_placeholders "$DEST" \
  "$PROJECT_NAME" \
  "$USER_NAME" \
  "$USER_WHAT_TO_CALL" \
  "$AGENT_DISPLAY_NAME" \
  "$CODE_LOG_DATE" \
  "$INSTALL_DATE"

rename_code_log_file "$DEST" "$CODE_LOG_DATE"
rename_agent_folder "$DEST" "$AGENT_NAME"

info ""
info "Done. Harness installed at: ${DEST}"
info ""
info "Quick start:"
info "  1. Open a new chat in your AI-enabled IDE"
info "  2. Add @${INSTALL_SUBPATH}/${AGENT_NAME} as context"
info "  3. Say: Please load context"
info ""
info "Validate: ${HARNESS_ROOT}/scripts/validate.sh ${TARGET_REPO}"
