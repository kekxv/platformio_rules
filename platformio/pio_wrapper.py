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
    found_paths = set()
    for root, dirs, files in os.walk(runfiles_dir):
        if "site-packages" in dirs:
            sp_path = os.path.join(root, "site-packages")
            found_paths.add(os.path.abspath(sp_path))
    
    if found_paths:
        paths_list = list(found_paths)
        for p in paths_list:
            if p not in sys.path:
                sys.path.insert(0, p)
        
        new_pythonpath = os.pathsep.join(paths_list)
        old_pythonpath = os.environ.get("PYTHONPATH", "")
        if old_pythonpath:
            os.environ["PYTHONPATH"] = new_pythonpath + os.pathsep + old_pythonpath
        else:
            os.environ["PYTHONPATH"] = new_pythonpath
        
        os.environ["PLATFORMIO_PYTHON_EXE"] = sys.executable
        os.environ["PLATFORMIO_DISABLE_UPDATE_CHECK"] = "true"

def run():
    setup_bazel_env()
    
    args = sys.argv[1:]
    pio_args = []
    unzip_data = []
    signing_key = None
    encryption_key = None
    
    i = 0
    while i < len(args):
        if args[i] == "--bazel-unzip" and i + 1 < len(args):
            unzip_data.append(args[i+1])
            i += 2
        elif args[i] == "--signing-key" and i + 1 < len(args):
            signing_key = os.path.abspath(args[i+1])
            i += 2
        elif args[i] == "--encryption-key" and i + 1 < len(args):
            encryption_key = os.path.abspath(args[i+1])
            i += 2
        else:
            pio_args.append(args[i])
            i += 1

    # Process unzipping
    for item in unzip_data:
        if not item or ":" not in item:
            continue
        try:
            zip_path, dest = item.rsplit(":", 1)
            if not os.path.exists(dest):
                os.makedirs(dest)
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(dest)
        except Exception as e:
            print(f"Bazel Wrapper Error: Failed to extract {item}: {e}", file=sys.stderr)
            sys.exit(1)

    # Now run PlatformIO
    from platformio.__main__ import main
    sys.argv = [sys.argv[0]] + pio_args
    
    result = 0
    try:
        main()
    except SystemExit as e:
        result = e.code
    except Exception as e:
        print(f"Bazel Wrapper: Unexpected Exception: {e}", file=sys.stderr)
        result = 1
    
    if result != 0:
        sys.exit(result)

    # If build succeeded and keys are present, post-process the binary
    if "run" in pio_args:
        project_dir = None
        for j in range(len(pio_args)):
            if pio_args[j] == "-d" and j + 1 < len(pio_args):
                project_dir = pio_args[j+1]
                break
        
        if project_dir:
            pio_build_dir = os.path.join(project_dir, ".pio", "build")
            if os.path.exists(pio_build_dir):
                for board in os.listdir(pio_build_dir):
                    board_dir = os.path.join(pio_build_dir, board)
                    if not os.path.isdir(board_dir):
                        continue
                    
                    bin_path = os.path.join(board_dir, "firmware.bin")
                    if os.path.exists(bin_path):
                        if signing_key:
                            print(f"Bazel Wrapper: Signing {bin_path}...")
                            subprocess.run([
                                sys.executable, "-m", "espsecure", "sign_data",
                                "--version", "2",
                                "--keyfile", signing_key,
                                "--output", bin_path + ".signed",
                                bin_path
                            ], check=True)
                            os.replace(bin_path + ".signed", bin_path)

                        if encryption_key:
                            print(f"Bazel Wrapper: Encrypting {bin_path}...")
                            subprocess.run([
                                sys.executable, "-m", "espsecure", "encrypt_flash_data",
                                "--keyfile", encryption_key,
                                "--address", "0x10000",
                                "--output", bin_path + ".encrypted",
                                bin_path
                            ], check=True)
                            os.replace(bin_path + ".encrypted", bin_path)

    sys.exit(0)

if __name__ == "__main__":
    run()