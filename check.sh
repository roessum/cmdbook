#!/usr/bin/env bash
# check.sh — find alias/function names that would shadow each other when sourced.
# common/ is sourced together with exactly ONE platform file, so a name clashes
# only if it is defined twice in the same file, or in common AND a platform.
# The SAME name in two different platforms (e.g. wg-show in ubuntu and macos) is
# fine — those files are never sourced together.
# Exits non-zero on a real clash (used by the pre-commit hook).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Emit "<name>\t<platform>\t<file>:<line>" for every alias and function.
records() {
  local f plat
  while IFS= read -r f; do
    plat=$(basename "$(dirname "$f")")
    grep -nE '^[[:space:]]*alias[[:space:]]+[A-Za-z0-9_-]+=' "$f" \
      | sed -E "s|^([0-9]+):[[:space:]]*alias[[:space:]]+([A-Za-z0-9_-]+)=.*|\2\t$plat\t${f#"$DIR/"}:\1|"
    grep -nE '^[[:space:]]*[A-Za-z0-9_-]+\(\)' "$f" \
      | sed -E "s|^([0-9]+):[[:space:]]*([A-Za-z0-9_-]+)\(\).*|\2\t$plat\t${f#"$DIR/"}:\1|"
  done < <(find "$DIR" -name 'aliases.sh' | sort)
}

recs="$(records)"
total=$(printf '%s\n' "$recs" | grep -c . || true)

# A name clashes if, for common paired with any single platform, it is defined
# more than once: twice in common, twice in that platform, or once in each.
conflicts="$(printf '%s\n' "$recs" | awk -F'\t' '
  BEGIN { np = split("ubuntu macos windows", P, " ") }
  NF { cnt[$1 SUBSEP $2]++; seen[$1]=1; where[$1] = where[$1] "\n      " $3 " [" $2 "]" }
  END {
    for (n in seen) {
      c = cnt[n SUBSEP "common"] + 0
      bad = (c >= 2)
      for (i = 1; i <= np; i++) { pc = cnt[n SUBSEP P[i]] + 0; if (pc >= 2 || c + pc >= 2) bad = 1 }
      if (bad) printf "  %s%s\n", n, where[n]
    }
  }
')"

if [ -z "$conflicts" ]; then
  echo "✓ no shadowing alias/function names ($total defined)"
  exit 0
fi
echo "✗ names that would shadow each other when sourced:"
printf '%s\n' "$conflicts"
exit 1
