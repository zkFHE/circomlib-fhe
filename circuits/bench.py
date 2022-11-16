import subprocess
import sys
import os
import csv
from datetime import datetime

MAINS = ["main.circom"]
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
    cmd = f"circom --r1cs --json --wasm --c -o out/ {main}"
    # print(cmd)
    res = subprocess.run(cmd, capture_output=True, env={"PATH": os.environ["PATH"]}, shell=True, text=True)
    if res.returncode != 0:
        print(f"'{res.args}' failed with error code {res.returncode} and output {res.stderr}", file=sys.stderr)
        return None
    return parse(res.stdout)

if __name__ == "__main__":
    for main in sys.argv[1:]:
        d = circom(main)
        if d is not None:
            d["name"] = main
            print(",".join([str(tup[1]) for tup in sorted(d.items(), key=lambda tup: tup[0])]))
    
    # with open(f"out/bench_{datetime.now().isoformat()}", "w") as out_file:
    #     writer = csv.DictWriter(out_file, fieldnames=["name"] + PREFIXES)
    #     writer.writeheader()
    #     for main in MAINS:
    #         d = circom(main)
    #         if d is not None:
    #             d["name"] = main
    #             writer.writerow(d)
