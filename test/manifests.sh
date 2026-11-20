#!/usr/bin/env bash
# Checks that the copy loop of the Dockerfile and the tools of mise.toml name the same commands.
# mise installs each tool of mise.toml, but the image gets only the commands that the copy loop
# names. Thus a tool that the loop does not name is not in the image, and the build does not fail.
# The CI runs this check before the build. Usage: bash test/manifests.sh, from any folder.
set -euo pipefail

cd "$(dirname "$0")/.."

# The tool keys of mise.toml. tomllib is in the standard library of Python 3.11 and later.
keys=$(python3 -c 'import sys, tomllib; print(*tomllib.load(open(sys.argv[1], "rb"))["tools"], sep="\n")' mise.toml)

# The command of each tool. A key with a backend ("github:owner/name") gives the name after the
# last slash. Two tools have a command with a different name.
expected=$(
  while read -r key; do
    command=${key##*[:/]}
    case $command in
      argo-rollouts) command=kubectl-argo-rollouts ;;
      opentofu) command=tofu ;;
    esac
    echo "$command"
  done <<< "$keys" | sort -u
)

# The words between "for command in" and "; do" in the Dockerfile.
copied=$(sed -n '/for command in/,/; do/p' Dockerfile | tr '\\\n' '  ' \
  | sed -e 's/.*for command in//' -e 's/; do.*//' | tr -s ' ' '\n' | sed '/^$/d' | sort -u)

status=0
missing=$(comm -23 <(echo "$expected") <(echo "$copied"))
if [ -n "$missing" ]; then
  echo "FAIL: the copy loop of the Dockerfile does not name these tools of mise.toml: $(paste -sd " " <<< "$missing")" >&2
  status=1
fi
extra=$(comm -13 <(echo "$expected") <(echo "$copied"))
if [ -n "$extra" ]; then
  echo "FAIL: the copy loop of the Dockerfile names these commands, which are not in mise.toml: $(paste -sd " " <<< "$extra")" >&2
  status=1
fi
if [ "$status" -eq 0 ]; then
  echo "The copy loop of the Dockerfile names the $(echo "$expected" | wc -l) tools of mise.toml."
fi
exit "$status"
