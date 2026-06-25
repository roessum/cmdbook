#!/usr/bin/env bash
# check.sh — find duplicate / shadowing alias & function names across aliases.sh.
# common/aliases.sh and the platform file are BOTH sourced, so a name defined in
# two files means one silently shadows the other. This catches that.
# Exits non-zero if any duplicate is found (handy for a pre-commit hook / CI).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Collect "<name>\t<file>:<line>" for every alias and function definition.
collect() {
  while IFS= read -r f; do
    # aliases:  alias name='...'
    grep -nE '^[[:space:]]*alias[[:space:]]+[A-Za-z0-9_-]+=' "$f" \
      | sed -E "s|^([0-9]+):[[:space:]]*alias[[:space:]]+([A-Za-z0-9_-]+)=.*|\2\t${f#"$DIR/"}:\1|"
    # functions:  name() { ... }
    grep -nE '^[[:space:]]*[A-Za-z0-9_-]+\(\)' "$f" \
      | sed -E "s|^([0-9]+):[[:space:]]*([A-Za-z0-9_-]+)\(\).*|\2\t${f#"$DIR/"}:\1|"
  done < <(find "$DIR" -name 'aliases.sh' | sort)
}

names="$(collect)"

# A name is duplicated if it appears on more than one line of the collection.
dupes="$(printf '%s\n' "$names" | cut -f1 | sort | uniq -d || true)"

if [ -z "$dupes" ]; then
  count="$(printf '%s\n' "$names" | grep -c . || true)"
  echo "✓ no duplicate alias/function names ($count defined)"
  exit 0
fi

echo "✗ duplicate alias/function names found:"
while IFS= read -r name; do
  [ -z "$name" ] && continue
  echo "  $name"
  printf '%s\n' "$names" | awk -F'\t' -v n="$name" '$1==n {print "      "$2}'
done <<< "$dupes"
exit 1
