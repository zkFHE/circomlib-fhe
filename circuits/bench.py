import subprocess
import sys
import os

MAINS = ["main"]
PREFIXES = ["non-linear constraints", "linear constraints", "public inputs", "public outputs", "private inputs", "private outputs", "wires", "labels"]

def parse(out):
    lines = out.splitlines()
    parsed = dict()
    for line in lines:
        for pre in PREFIXES:
            if line.startswith(pre + ": "):
                parsed[pre] = int(line[len(pre)+2:])
    return parsed

def circom(main):
    cmd = f"circom --r1cs --json -o out/ {main}.circom"
    print(cmd)
    res = subprocess.run(cmd, capture_output=True, env={"PATH": os.environ["PATH"]}, shell=True, text=True)
    if res.returncode != 0:
        print()
        print(f"'{res.args}' failed with error code {res.returncode} and output {res.stderr}", file=sys.stderr)
        return
    return parse(res.stdout)

if __name__ == "__main__":
    for main in MAINS:
        d = circom(main)
        print(d)
