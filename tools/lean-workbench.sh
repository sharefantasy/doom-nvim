#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: lean-workbench <Lean-file>

Open a Kitty workspace with:
  - top: Neovim source + lean.nvim Infoview/ProofWidgets
  - bottom: Zellij agent/tools/logs tabs
EOF
}

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 2
fi

for executable in kitty nvim zellij resvg; do
    if ! command -v "$executable" >/dev/null 2>&1; then
        echo "lean-workbench: missing executable: $executable" >&2
        exit 1
    fi
done

input_file="$1"
if [[ ! -f "$input_file" ]]; then
    echo "lean-workbench: Lean file does not exist: $input_file" >&2
    exit 1
fi

file_dir="$(cd "$(dirname "$input_file")" && pwd -P)"
lean_file="$file_dir/$(basename "$input_file")"

project_root="$file_dir"
while [[ "$project_root" != "/" ]]; do
    if [[ -f "$project_root/lakefile.toml" ||
          -f "$project_root/lakefile.lean" ||
          -f "$project_root/lean-toolchain" ]]; then
        break
    fi
    project_root="$(dirname "$project_root")"
done

if [[ "$project_root" == "/" ]]; then
    project_root="$file_dir"
fi

script_path="$(realpath "${BASH_SOURCE[0]}")"
script_dir="$(dirname "$script_path")"
zellij_wrapper="$script_dir/lean-zellij.sh"
zellij_layout="$script_dir/zellij/lean-tools.kdl"

if [[ ! -x "$zellij_wrapper" ]]; then
    echo "lean-workbench: helper is not executable: $zellij_wrapper" >&2
    exit 1
fi

if [[ ! -f "$zellij_layout" ]]; then
    echo "lean-workbench: missing Zellij layout: $zellij_layout" >&2
    exit 1
fi

project_name="$(basename "$project_root")"
project_slug="$(printf '%s' "$project_name" |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9_-]+/-/g; s/^-+//; s/-+$//')"
project_slug="${project_slug:-project}"
project_hash="$(printf '%s' "$project_root" | shasum -a 256 | cut -c1-8)"
zellij_session="lean-${project_slug}-${project_hash}"

quote_session_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]), end="")
PY
}

quoted_root="$(quote_session_arg "$project_root")"
quoted_file="$(quote_session_arg "$lean_file")"
quoted_zellij_wrapper="$(quote_session_arg "$zellij_wrapper")"
quoted_layout="$(quote_session_arg "$zellij_layout")"
quoted_session="$(quote_session_arg "$zellij_session")"

cache_root="${XDG_CACHE_HOME:-"$HOME/.cache"}/gentlewind/lean-workbench"
mkdir -p "$cache_root"
session_file="$cache_root/${zellij_session}.kitty-session"
session_tmp="$session_file.tmp.$$"

cat >"$session_tmp" <<EOF
os_window_title Lean · $project_name
layout splits
cd $quoted_root
launch --title "Lean · code + visualization" --var role=lean --env LEAN_WORKBENCH=1 nvim $quoted_file +LeanWorkbenchOpen
launch --location=hsplit --bias=32 --title "Lean · tools" --var role=tools $quoted_zellij_wrapper $quoted_root $quoted_layout $quoted_session
focus_matching_window var:role=lean
EOF
mv -f "$session_tmp" "$session_file"

env -u ZELLIJ -u ZELLIJ_PANE_ID -u ZELLIJ_SESSION_NAME \
    kitty --detach --session "$session_file"
