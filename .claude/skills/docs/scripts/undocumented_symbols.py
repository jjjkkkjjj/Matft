#!/usr/bin/env python3
"""List Matft's public symbols that have no documentation comment.

Reads the symbol graphs emitted by `scripts/build-docs.sh`
(<repository root>/.build/docc/matft-symbol-graphs/*.symbols.json), so run that first.
The repository root is the one of the current directory, so run this from the checkout (or worktree) you are working on.

Usage:
    python3 .claude/skills/docs/scripts/undocumented_symbols.py          # list, exit 1 if any
    python3 .claude/skills/docs/scripts/undocumented_symbols.py --summary # counts per file

Symbols without a source location (synthesized / inherited from Swift's protocols) are ignored,
because DocC shows the inherited documentation for them.
"""
import argparse
import collections
import glob
import json
import os
import subprocess
import sys


def repository_root():
    # Not the script's location: the skill may be read from another checkout than the one being documented.
    try:
        return subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return os.getcwd()


def undocumented(symbol_dir=None):
    symbol_dir = symbol_dir or os.path.join(repository_root(), ".build", "docc", "matft-symbol-graphs")
    files = glob.glob(os.path.join(symbol_dir, "*.symbols.json"))
    if not files:
        raise SystemExit(f"no symbol graphs in {symbol_dir}; run ./scripts/build-docs.sh first")
    found = set()
    for path in files:
        with open(path) as f:
            graph = json.load(f)
        for s in graph["symbols"]:
            loc = s.get("location")
            if not loc or "docComment" in s:
                continue
            rel = loc["uri"].split("/Sources/Matft/")[-1]
            found.add((f"Sources/Matft/{rel}", loc["position"]["line"] + 1,
                       s["kind"]["displayName"], s["names"]["title"]))
    return sorted(found)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--summary", action="store_true", help="print counts per file")
    args = p.parse_args(argv)

    items = undocumented()
    if args.summary:
        for file, n in collections.Counter(i[0] for i in items).most_common():
            print(f"{n:4d} {file}")
    else:
        for file, line, kind, title in items:
            print(f"{file}:{line}: {kind} {title}")
    print(f"{len(items)} undocumented public symbol(s)", file=sys.stderr)
    return 1 if items else 0


if __name__ == "__main__":
    sys.exit(main())
