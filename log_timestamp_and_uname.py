import sys
from datetime import datetime
from subprocess import call


def print_timestamp_and_uname():
    try:
        timestamp = datetime.now()
        call(f"echo '{timestamp}' > uname-output.log", shell=True)
        call('uname -a >> uname-output.log', shell=True)
    except Exception as e:
        print("Execution failed:", e, file=sys.stderr)

if __name__ == "__main__":
    print_timestamp_and_uname()
