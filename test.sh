#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
set +o posix

dbg() {
    >&2 echo "$(tput dim)$*$(tput sgr0)"
}

dbg_stdin() {
    local prefix=$1
    shift
    while IFS= read -r line; do dbg "$prefix $line"; done
}

write=0
override=0

_process_input_file() {
    local dir
    local base
    local input_file=$1
    dir=$(dirname "$input_file")
    base=$(basename "$input_file")
    base=${base%%.*}
    local script="$dir/$base.luau"
    local prefix="[$input_file]"
    if [ ! -f "$script" ]; then
        dbg "$prefix $script not found"
        exit 1
    fi
    local output
    set +e
    output=$(./run.sh "$script" "$input_file")
    local retval=$?
    set -e
    if [ $retval -ne 0 ]; then
        echo "$output"
        exit $retval
    fi
    if [ -z "$output" ]; then
        dbg "$prefix empty output"
        exit 1
    fi
    local output_file="${input_file%.*}.out"
    if [ $override -eq 0 ] && [ -f "$output_file" ]; then
        local expected
        expected=$(<"$output_file")
        if [[ "$output" == "$expected" ]]; then
            dbg "$prefix output matches $output_file"
            echo "$output"
        else
            dbg "$prefix output does not match $output_file"
            dbg "$prefix Expected:"
            dbg_stdin "$prefix" <<< "$expected"
            dbg "$prefix Actual:"
            echo "$output"
            exit 1
        fi
    elif [ $write -eq 1 ]; then
        dbg "$prefix create output file $output_file"
        echo "$output" | tee "$output_file"
    else
        echo "$output"
    fi
}

opts=()
while getopts "wo" opt ; do
    opts+=("-$opt")
    if [[ "$opt" == "w" ]]; then
        write=1
    elif [[ "$opt" == "o" ]]; then
        write=1
        override=1
    fi
done
shift $((OPTIND-1))

if [ $# -eq 0 ]; then
    if command -v fd &>/dev/null; then
        exec fd \
            --no-ignore \
            --extension in \
            --exact-depth 2 \
            --exec "$0" "${opts[@]}"
    fi

    exec find . \
        -mindepth 2 \
        -maxdepth 2 \
        -name "*.in" \
        -exec "$0" "${opts[@]}" {} \;
fi

for file; do
    _process_input_file "$file"
done
