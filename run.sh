#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

./build/solve "$@"
./luau/luau-analyze "$1"
