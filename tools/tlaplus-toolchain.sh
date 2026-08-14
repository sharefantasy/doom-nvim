#!/usr/bin/env bash

set -euo pipefail

readonly TLA_TOOLS_VERSION="v1.7.4"
readonly TLA_TOOLS_SHA256="936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88"
readonly TLA_TOOLS_URL="https://github.com/tlaplus/tlaplus/releases/download/${TLA_TOOLS_VERSION}/tla2tools.jar"
readonly DATA_ROOT="${XDG_DATA_HOME:-"$HOME/.local/share"}/gentlewind/tlaplus/${TLA_TOOLS_VERSION}"
readonly DEFAULT_JAR="${DATA_ROOT}/tla2tools.jar"
readonly JAR_PATH="${TLA2TOOLS_JAR:-"$DEFAULT_JAR"}"

child_pid=""

usage() {
    cat <<'EOF'
Usage: tlaplus-toolchain <command> [arguments]

Commands:
  install
      Install the pinned stable tla2tools.jar.
  health
      Check Java, tla2tools.jar and Graphviz.
  jar-path
      Print the active tla2tools.jar path.
  check <spec.tla>
      Run SANY syntax, semantic and level checking.
  model-check <spec.tla> [model.cfg]
      Run exhaustive TLC model checking.
  smoke <spec.tla> [model.cfg] [seconds]
      Run bounded-time TLC simulation. Success does not prove correctness.
  translate <spec.tla>
      Translate the PlusCal algorithm in the file to TLA+.
  graph <spec.tla> [model.cfg]
      Model-check and render the reachable state graph as DOT, SVG and PNG.
EOF
}

fail() {
    echo "tlaplus-toolchain: $*" >&2
    exit 1
}

terminate_child() {
    if [[ -n "$child_pid" ]]; then
        kill -TERM "$child_pid" 2>/dev/null || true
        wait "$child_pid" 2>/dev/null || true
        child_pid=""
    fi
}

trap 'terminate_child; exit 143' TERM INT

run_child() {
    "$@" &
    child_pid=$!
    local status=0
    wait "$child_pid" || status=$?
    child_pid=""
    return "$status"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "missing executable: $1"
}

sha256() {
    shasum -a 256 "$1" | awk '{print $1}'
}

verify_jar() {
    require_command java
    [[ -f "$JAR_PATH" ]] ||
        fail "missing ${JAR_PATH}; run '$(basename "$0") install'"

    if [[ "$JAR_PATH" == "$DEFAULT_JAR" ]]; then
        local actual
        actual="$(sha256 "$JAR_PATH")"
        [[ "$actual" == "$TLA_TOOLS_SHA256" ]] ||
            fail "checksum mismatch for ${JAR_PATH}; remove it and reinstall"
    fi
}

absolute_file() {
    local input="$1"
    [[ -f "$input" ]] || fail "file does not exist: $input"
    local directory
    directory="$(cd "$(dirname "$input")" && pwd -P)"
    printf '%s/%s\n' "$directory" "$(basename "$input")"
}

spec_file() {
    local input
    input="$(absolute_file "$1")"
    [[ "$input" == *.tla ]] || fail "expected a .tla file: $input"
    printf '%s\n' "$input"
}

config_file() {
    local spec="$1"
    local requested="${2:-${spec%.tla}.cfg}"
    absolute_file "$requested"
}

project_root() {
    local spec_dir
    spec_dir="$(dirname "$1")"
    git -C "$spec_dir" rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$spec_dir"
}

artifact_dir() {
    local spec="$1"
    local root module
    root="$(project_root "$spec")"
    module="$(basename "${spec%.tla}")"
    printf '%s/.tla-cache/%s\n' "$root" "$module"
}

java_tla() {
    verify_jar
    run_child java -XX:+UseParallelGC -cp "$JAR_PATH" "$@"
}

install_tools() {
    require_command curl
    require_command shasum

    mkdir -p "$DATA_ROOT"
    local temporary="${DEFAULT_JAR}.tmp.$$"
    trap 'rm -f "$temporary"; terminate_child; exit 143' TERM INT

    echo "Downloading TLA+ tools ${TLA_TOOLS_VERSION}..."
    run_child curl -fL --retry 3 --retry-delay 1 "$TLA_TOOLS_URL" -o "$temporary"

    local actual
    actual="$(sha256 "$temporary")"
    if [[ "$actual" != "$TLA_TOOLS_SHA256" ]]; then
        rm -f "$temporary"
        fail "download checksum mismatch: expected ${TLA_TOOLS_SHA256}, got ${actual}"
    fi

    chmod 0644 "$temporary"
    mv -f "$temporary" "$DEFAULT_JAR"
    trap 'terminate_child; exit 143' TERM INT
    echo "Installed ${DEFAULT_JAR}"
}

health() {
    local failed=0

    echo "TLA+ toolchain"
    echo "  pinned release: ${TLA_TOOLS_VERSION}"
    echo "  jar: ${JAR_PATH}"

    if command -v java >/dev/null 2>&1; then
        echo "  java: $(command -v java)"
        java -version 2>&1 | sed 's/^/    /'
    else
        echo "  java: missing"
        failed=1
    fi

    if [[ -f "$JAR_PATH" ]]; then
        local actual
        actual="$(sha256 "$JAR_PATH")"
        echo "  jar sha256: ${actual}"
        if [[ "$JAR_PATH" == "$DEFAULT_JAR" && "$actual" != "$TLA_TOOLS_SHA256" ]]; then
            echo "  jar status: checksum mismatch"
            failed=1
        else
            echo "  jar status: ready"
        fi
    else
        echo "  jar status: not installed"
        echo "  install: $(basename "$0") install"
        failed=1
    fi

    if command -v dot >/dev/null 2>&1; then
        echo "  graphviz: $(dot -V 2>&1)"
    else
        echo "  graphviz: missing (required only for graph rendering)"
    fi

    return "$failed"
}

run_check() {
    local spec
    spec="$(spec_file "$1")"
    cd "$(dirname "$spec")"
    java_tla tla2sany.SANY "$(basename "$spec")"
}

run_model_check() {
    local spec cfg cache workers
    spec="$(spec_file "$1")"
    cfg="$(config_file "$spec" "${2:-}")"
    cache="$(artifact_dir "$spec")/tlc"
    workers="${TLC_WORKERS:-auto}"
    mkdir -p "$cache"

    cd "$(dirname "$spec")"
    java_tla tlc2.TLC \
        -cleanup \
        -workers "$workers" \
        -metadir "$cache" \
        -config "$cfg" \
        "$(basename "$spec")"
}

run_smoke() {
    local spec cfg seconds cache workers
    spec="$(spec_file "$1")"
    cfg="$(config_file "$spec" "${2:-}")"
    seconds="${3:-5}"
    [[ "$seconds" =~ ^[1-9][0-9]*$ ]] || fail "seconds must be a positive integer"
    cache="$(artifact_dir "$spec")/smoke"
    workers="${TLC_WORKERS:-auto}"
    mkdir -p "$cache"

    cd "$(dirname "$spec")"
    verify_jar
    run_child java \
        -XX:+UseParallelGC \
        "-Dtlc2.TLC.stopAfter=${seconds}" \
        -cp "$JAR_PATH" \
        tlc2.TLC \
        -cleanup \
        -simulate \
        -workers "$workers" \
        -metadir "$cache" \
        -config "$cfg" \
        "$(basename "$spec")"
}

run_translate() {
    local spec cfg cache backup cfg_backup old_file
    spec="$(spec_file "$1")"
    cfg="${spec%.tla}.cfg"
    cache="$(artifact_dir "$spec")/translation"
    backup="$cache/$(basename "${spec%.tla}").before.tla"
    cfg_backup="$cache/$(basename "${spec%.tla}").before.cfg"
    old_file="${spec%.tla}.old"
    mkdir -p "$cache"
    cp "$spec" "$backup"
    if [[ -f "$cfg" ]]; then
        cp "$cfg" "$cfg_backup"
    fi

    cd "$(dirname "$spec")"
    if java_tla pcal.trans "$(basename "$spec")"; then
        if [[ -f "$old_file" ]]; then
            mv -f "$old_file" "$cache/$(basename "${spec%.tla}").old.tla"
        fi
        echo "TLAPLUS_TRANSLATION_BACKUP=${backup}"
        if [[ -f "$cfg_backup" ]]; then
            echo "TLAPLUS_CONFIG_BACKUP=${cfg_backup}"
        fi
    else
        return $?
    fi
}

run_graph() {
    require_command dot

    local spec cfg cache dot_file svg_file png_file workers
    spec="$(spec_file "$1")"
    cfg="$(config_file "$spec" "${2:-}")"
    cache="$(artifact_dir "$spec")/graph"
    dot_file="$cache/$(basename "${spec%.tla}").dot"
    svg_file="$cache/$(basename "${spec%.tla}").svg"
    png_file="$cache/$(basename "${spec%.tla}").png"
    workers="${TLC_WORKERS:-auto}"
    mkdir -p "$cache"

    cd "$(dirname "$spec")"
    java_tla tlc2.TLC \
        -cleanup \
        -workers "$workers" \
        -metadir "$cache/states" \
        -config "$cfg" \
        -dump dot,colorize "$dot_file" \
        "$(basename "$spec")"
    run_child dot -Tsvg "$dot_file" -o "$svg_file"
    run_child dot -Tpng "$dot_file" -o "$png_file"
    echo "TLAPLUS_GRAPH_DOT=${dot_file}"
    echo "TLAPLUS_GRAPH_SVG=${svg_file}"
    echo "TLAPLUS_GRAPH_PNG=${png_file}"
}

command_name="${1:-}"
case "$command_name" in
    install)
        [[ $# -eq 1 ]] || fail "install takes no arguments"
        install_tools
        ;;
    health)
        [[ $# -eq 1 ]] || fail "health takes no arguments"
        health
        ;;
    jar-path)
        [[ $# -eq 1 ]] || fail "jar-path takes no arguments"
        printf '%s\n' "$JAR_PATH"
        ;;
    check)
        [[ $# -eq 2 ]] || fail "usage: $(basename "$0") check <spec.tla>"
        run_check "$2"
        ;;
    model-check)
        [[ $# -ge 2 && $# -le 3 ]] ||
            fail "usage: $(basename "$0") model-check <spec.tla> [model.cfg]"
        run_model_check "$2" "${3:-}"
        ;;
    smoke)
        [[ $# -ge 2 && $# -le 4 ]] ||
            fail "usage: $(basename "$0") smoke <spec.tla> [model.cfg] [seconds]"
        run_smoke "$2" "${3:-}" "${4:-}"
        ;;
    translate)
        [[ $# -eq 2 ]] || fail "usage: $(basename "$0") translate <spec.tla>"
        run_translate "$2"
        ;;
    graph)
        [[ $# -ge 2 && $# -le 3 ]] ||
            fail "usage: $(basename "$0") graph <spec.tla> [model.cfg]"
        run_graph "$2" "${3:-}"
        ;;
    -h | --help | help)
        usage
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
