#!/usr/bin/env python3
"""Wrapper script to run PlatformIO commands.

This script provides a clean interface to run PlatformIO commands,
managed through rules_python instead of relying on PATH or hardcoded paths.
"""

import sys

def main():
    """Run PlatformIO with the provided arguments."""
    try:
        # Import platformio CLI directly and execute it
        # This avoids subprocess calls that require 'python' in PATH
        from platformio.cli import main as platformio_main
    except ImportError:
        print("Error: platformio is not installed.", file=sys.stderr)
        print("Please add platformio to requirements.txt and run:", file=sys.stderr)
        print("  bazel run //:requirements.update", file=sys.stderr)
        sys.exit(1)
    
    # Execute platformio with all provided arguments
    # The CLI main function expects argv[0] to be the program name
    sys.exit(platformio_main())

if __name__ == "__main__":
    main()
