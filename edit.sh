#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Usage: ./edit.sh 2015 9
year=$1
day=$2
fday=$(printf '%02d' "$day")

script="$year/${fday}.luau"

if [[ -f "$script" ]]; then
    >&2 echo "$script already exists"
else
    >&2 echo "Create $script"
    mkdir -p "$year"
    year=$year day=$day envsubst < template.luau > "$script"
fi

input_file="$year/${fday}.my.in"
if [[ -f "$input_file" ]]; then
    >&2 echo "$input_file already exists"
else
    if [[ -n "${ADVENT_OF_CODE_COOKIE:-}" ]]; then
        >&2 echo "Download input to $input_file"
        curl -sSf \
            --cookie "session=$ADVENT_OF_CODE_COOKIE" \
            --output "$input_file" \
            "https://adventofcode.com/$year/day/$day/input"
    else
        >&2 echo "Could not download $input_file, ADVENT_OF_CODE_COOKIE not set"
    fi
fi

exec nvim -O "$script" "$input_file"
