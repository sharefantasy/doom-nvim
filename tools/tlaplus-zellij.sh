#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: tlaplus-zellij <project-root> <layout-file> <session-name>" >&2
    exit 2
fi

project_root="$1"
layout_file="$2"
session_name="$3"

cd "$project_root"

session_line="$(
    zellij list-sessions --no-formatting 2>/dev/null |
        grep -E "^${session_name} " |
        head -n 1 ||
        true
)"

if [[ -n "$session_line" && "$session_line" != *"(EXITED"* ]]; then
    exec zellij attach "$session_name"
fi

if [[ -n "$session_line" ]]; then
    zellij delete-session --force "$session_name" >/dev/null
fi

zellij --layout "$layout_file" attach --create-background "$session_name" >/dev/null
exec zellij attach "$session_name"
