#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: tlaplus-workbench <TLA-file>

Open a Kitty workspace with:
  - top: Neovim TLA+ source + SANY/TLC/graph result panel
  - bottom: Zellij TraeX/tools/logs tabs
EOF
}

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 2
fi

for executable in kitty nvim zellij java dot; do
    if ! command -v "$executable" >/dev/null 2>&1; then
        echo "tlaplus-workbench: missing executable: $executable" >&2
        exit 1
    fi
done

input_file="$1"
if [[ ! -f "$input_file" ]]; then
    echo "tlaplus-workbench: TLA+ file does not exist: $input_file" >&2
    exit 1
fi

if [[ "$input_file" != *.tla ]]; then
    echo "tlaplus-workbench: expected a .tla file: $input_file" >&2
    exit 1
fi

file_dir="$(cd "$(dirname "$input_file")" && pwd -P)"
tla_file="$file_dir/$(basename "$input_file")"

project_root="$(
    git -C "$file_dir" rev-parse --show-toplevel 2>/dev/null ||
        printf '%s\n' "$file_dir"
)"

script_path="$(realpath "${BASH_SOURCE[0]}")"
script_dir="$(dirname "$script_path")"
zellij_wrapper="$script_dir/tlaplus-zellij.sh"
zellij_layout="$script_dir/zellij/tlaplus-tools.kdl"
toolchain="$script_dir/tlaplus-toolchain.sh"

for helper in "$zellij_wrapper" "$toolchain"; do
    if [[ ! -x "$helper" ]]; then
        echo "tlaplus-workbench: helper is not executable: $helper" >&2
        exit 1
    fi
done

if [[ ! -f "$zellij_layout" ]]; then
    echo "tlaplus-workbench: missing Zellij layout: $zellij_layout" >&2
    exit 1
fi

if ! "$toolchain" health >/dev/null 2>&1; then
    echo "tlaplus-workbench: TLA+ toolchain is not ready" >&2
    echo "Run: $toolchain install" >&2
    exit 1
fi

project_name="$(basename "$project_root")"
project_slug="$(
    printf '%s' "$project_name" |
        tr '[:upper:]' '[:lower:]' |
        sed -E 's/[^a-z0-9_-]+/-/g; s/^-+//; s/-+$//'
)"
project_slug="${project_slug:-project}"
project_hash="$(printf '%s' "$project_root" | shasum -a 256 | cut -c1-8)"
zellij_session="tla-${project_slug}-${project_hash}"

quote_session_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]), end="")
PY
}

quoted_root="$(quote_session_arg "$project_root")"
quoted_file="$(quote_session_arg "$tla_file")"
quoted_zellij_wrapper="$(quote_session_arg "$zellij_wrapper")"
quoted_layout="$(quote_session_arg "$zellij_layout")"
quoted_session="$(quote_session_arg "$zellij_session")"

cache_root="${XDG_CACHE_HOME:-"$HOME/.cache"}/gentlewind/tlaplus-workbench"
mkdir -p "$cache_root"
session_file="$cache_root/${zellij_session}.kitty-session"
session_tmp="$session_file.tmp.$$"

cat >"$session_tmp" <<EOF
os_window_title TLA+ · $project_name
layout splits
cd $quoted_root
launch --title "TLA+ · code + verification" --var role=tlaplus --env TLAPLUS_WORKBENCH=1 nvim $quoted_file +TlaWorkbenchOpen
launch --location=hsplit --bias=32 --title "TLA+ · agent + tools" --var role=tools $quoted_zellij_wrapper $quoted_root $quoted_layout $quoted_session
focus_matching_window var:role=tlaplus
EOF
mv -f "$session_tmp" "$session_file"

env -u ZELLIJ -u ZELLIJ_PANE_ID -u ZELLIJ_SESSION_NAME \
    kitty --detach --session "$session_file"
