import subprocess

# Pushes from inside a script, written as a Python argument list
subprocess.run(["git", "push", "origin", "main"], check=True)
