#!/usr/bin/env bash
# Shared helpers for portable-agent-harness scripts.

set -euo pipefail

HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATE_DIR="${HARNESS_ROOT}/template"
MANIFEST="${HARNESS_ROOT}/manifest.yaml"

die() {
  echo "error: $*" >&2
  exit 1
}

info() {
  echo "$*"
}

today_ymd() {
  date +%Y%m%d
}

today_iso() {
  date +%Y-%m-%d
}

# Replace {{PLACEHOLDER}} in all text files under a directory.
apply_placeholders() {
  local root="$1"
  local project_name="$2"
  local user_name="$3"
  local user_call="$4"
  local agent_display="$5"
  local code_log_date="$6"
  local install_date="$7"

  export PROJECT_NAME="$project_name"
  export USER_NAME="$user_name"
  export USER_WHAT_TO_CALL="$user_call"
  export AGENT_DISPLAY_NAME="$agent_display"
  export CODE_LOG_DATE="$code_log_date"
  export INSTALL_DATE="$install_date"

  while IFS= read -r -d '' f; do
    if file -b --mime-type "$f" 2>/dev/null | grep -q '^text/'; then
      perl -pi -e '
        s/\{\{PROJECT_NAME\}\}/$ENV{PROJECT_NAME}/g;
        s/\{\{USER_NAME\}\}/$ENV{USER_NAME}/g;
        s/\{\{USER_WHAT_TO_CALL\}\}/$ENV{USER_WHAT_TO_CALL}/g;
        s/\{\{AGENT_DISPLAY_NAME\}\}/$ENV{AGENT_DISPLAY_NAME}/g;
        s/\{\{CODE_LOG_DATE\}\}/$ENV{CODE_LOG_DATE}/g;
        s/\{\{INSTALL_DATE\}\}/$ENV{INSTALL_DATE}/g;
      ' "$f"
    fi
  done < <(find "$root" -type f -print0)
}

rename_code_log_file() {
  local agents_dir="$1"
  local date_ymd="$2"
  local template_name="code-log-{{CODE_LOG_DATE}}.md"
  local target_name="code-log-${date_ymd}.md"
  local src="${agents_dir}/code-log/${template_name}"
  local dst="${agents_dir}/code-log/${target_name}"

  if [[ -f "$src" ]]; then
    mv "$src" "$dst"
  fi
}

rename_agent_folder() {
  local agents_dir="$1"
  local agent_name="$2"
  if [[ "$agent_name" != "myAgent" && -d "${agents_dir}/myAgent" ]]; then
    mv "${agents_dir}/myAgent" "${agents_dir}/${agent_name}"
  fi
}
