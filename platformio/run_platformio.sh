#!/bin/bash
# Wrapper script to run platformio through py_binary
# This script is generated at build time and includes the py_binary location

set -e

PLATFORMIO_RUNNER="$1"
shift

# Execute the platformio runner with all remaining arguments
"$PLATFORMIO_RUNNER" "$@"
