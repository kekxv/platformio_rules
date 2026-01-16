import sys
import os
import zipfile
import subprocess

def setup_bazel_env():
    """Injects Bazel runfiles into the environment and fixes PATH for portability."""
    # 1. Fix PATH for portability
    path = os.environ.get("PATH", "")
    if os.name == "posix":
        # Ensure standard Unix paths are present
        essential = ["/usr/bin", "/bin", "/usr/local/bin"]
        if sys.platform == "darwin":
            essential.append("/opt/homebrew/bin")
        
        current_paths = path.split(os.pathsep)
        for p in essential:
            if p not in current_paths:
                path = p + os.pathsep + path
    elif os.name == "nt":
        # Ensure standard Windows paths are present
        sys_root = os.environ.get("SystemRoot", "C:\\Windows")
        essential = [
            os.path.join(sys_root, "System32"),
            sys_root,
            os.path.join(sys_root, "System32\\Wbem"),
        ]
        current_paths = path.split(os.pathsep)
        for p in essential:
            if p not in current_paths:
                path = p + os.pathsep + path
    
    os.environ["PATH"] = path

    # 2. Discover runfiles directory
    runfiles_dir = os.environ.get("RUNFILES_DIR") or os.environ.get("PYTHON_RUNFILES")
    
    if not runfiles_dir:
        exec_path = os.path.realpath(sys.argv[0])
        if ".runfiles" in exec_path:
            runfiles_dir = exec_path.split(".runfiles")[0] + ".runfiles"
        elif os.path.exists(exec_path + ".runfiles"):
            runfiles_dir = exec_path + ".runfiles"

    if not runfiles_dir:
        # Last resort: try to find any .runfiles directory in the path
        parts = os.path.abspath(sys.argv[0]).split(os.sep)
        for i in range(len(parts), 0, -1):
            potential = os.sep.join(parts[:i])
            if potential.endswith(".runfiles"):
                runfiles_dir = potential
                break

    if not runfiles_dir:
        return

    # Find ALL site-packages directories and add them to sys.path and PYTHONPATH
    # We use a set to avoid duplicates
    found_paths = set()
    for root, dirs, files in os.walk(runfiles_dir):
        if "site-packages" in dirs:
            sp_path = os.path.join(root, "site-packages")
            found_paths.add(os.path.abspath(sp_path))
    
    if found_paths:
        paths_list = list(found_paths)
        # Add to current process
        for p in paths_list:
            if p not in sys.path:
                sys.path.insert(0, p)
        
        # Add to PYTHONPATH for subprocesses
        new_pythonpath = os.pathsep.join(paths_list)
        old_pythonpath = os.environ.get("PYTHONPATH", "")
        if old_pythonpath:
            os.environ["PYTHONPATH"] = new_pythonpath + os.pathsep + old_pythonpath
        else:
            os.environ["PYTHONPATH"] = new_pythonpath
        
        # Force PlatformIO to use this Python interpreter if possible
        os.environ["PLATFORMIO_PYTHON_EXE"] = sys.executable

def run():
    setup_bazel_env()
    
    args = sys.argv[1:]
    pio_args = []
    unzip_data = os.environ.get("PIO_UNZIP_DATA", "")
    
    # Process custom arguments for unzipping
    # Support both command line flag and environment variable
    unzip_data = os.environ.get("PIO_UNZIP_DATA", "")
    
    i = 0
    while i < len(args):
        if args[i] == "--bazel-unzip" and i + 1 < len(args):
            if unzip_data:
                unzip_data += "," + args[i+1]
            else:
                unzip_data = args[i+1]
            i += 2
        else:
            pio_args.append(args[i])
            i += 1

    if unzip_data:
        for item in unzip_data.split(","):
            if not item or ":" not in item:
                continue
            try:
                # Use rsplit to handle Windows paths if they ever appear (though rare in Bazel)
                zip_path, dest = item.rsplit(":", 1)
                if not os.path.exists(dest):
                    os.makedirs(dest)
                
                # ZipFile is more portable than calling 'unzip' system command
                with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                    zip_ref.extractall(dest)
            except Exception as e:
                print(f"Bazel Wrapper Error: Failed to extract {item}: {e}", file=sys.stderr)
                sys.exit(1)

    # Now run PlatformIO
    from platformio.__main__ import main
    # Override sys.argv for platformio
    sys.argv = [sys.argv[0]] + pio_args
    # platformio.main usually calls sys.exit, but we wrap it to be sure
    sys.exit(main())

if __name__ == "__main__":
    run()