import os
import subprocess
import shlex
import sys

class BashScript:
    def __init__(self, script_path, script_root=None):
        """
        Args:
            script_path (str): Relative path to the script (e.g. 'iot/mqtt_helper.sh').
            script_root (str, optional): Root directory to look for scripts.
                                         Defaults to finding the repo root or package location.
        """
        self.script_rel_path = script_path

        if script_root:
             self.script_path = os.path.join(script_root, script_path)
        else:
             # Try to find the script relative to CWD (repo root)
             if os.path.exists(script_path):
                 self.script_path = os.path.abspath(script_path)
             else:
                 # Look relative to this file's parent directory (repo root assumption)
                 base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
                 candidate = os.path.join(base_dir, script_path)
                 if os.path.exists(candidate):
                     self.script_path = candidate
                 else:
                     raise FileNotFoundError(f"Script not found: {script_path}. Please run from repo root or ensure scripts are available.")

    def run(self, args, stream=False, dry_run=False):
        """
        Run the bash script.

        Args:
            args (list): Arguments.
            stream (bool): If True, yield output line by line.
            dry_run (bool): If True, print command and return dummy output.
        """
        cmd = [self.script_path] + [str(arg) for arg in args]

        if dry_run:
            command_str = " ".join(shlex.quote(str(arg)) for arg in cmd)
            print(f"Dry run: {command_str}")
            if stream:
                 # Return a generator that yields the command string
                 def dummy_gen():
                     yield f"Dry run: {command_str}"
                 return dummy_gen()
            else:
                 return f"Dry run: {command_str}"

        if stream:
            return self._stream_output(cmd)
        else:
            return self._run_blocking(cmd)

    def _run_blocking(self, cmd):
        try:
            result = subprocess.run(
                cmd,
                check=True,
                text=True,
                capture_output=True
            )
            return result.stdout
        except subprocess.CalledProcessError as e:
            error_msg = f"Script failed with code {e.returncode}.\nStderr: {e.stderr}\nStdout: {e.stdout}"
            raise RuntimeError(error_msg)

    def _stream_output(self, cmd):
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
            universal_newlines=True
        )

        with process.stdout:
            for line in iter(process.stdout.readline, ''):
                yield line

        process.wait()
        if process.returncode != 0:
            stderr = process.stderr.read()
            raise RuntimeError(f"Script failed with code {process.returncode}: {stderr}")

def run_script(script_path, args, stream=False, dry_run=False):
    script = BashScript(script_path)
    return script.run(args, stream=stream, dry_run=dry_run)
