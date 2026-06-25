#!/usr/bin/env bash
# install.sh — make cmdbook aliases available in your shell.
# Adds a single source line to your shell rc that loads common/ + the file
# matching the current platform. Re-run anytime; it won't duplicate the line.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pick the platform aliases file.
case "$(uname -s)" in
  Linux)  PLATFORM="ubuntu" ;;
  Darwin) PLATFORM="macos" ;;
  *)      PLATFORM="" ;;   # windows uses PowerShell, not this script
esac

# Choose the shell rc to append to.
case "$(basename "${SHELL:-bash}")" in
  zsh) RC="$HOME/.zshrc" ;;
  *)   RC="$HOME/.bashrc" ;;
esac

LOADER="$DIR/load.sh"

# Generate a loader that sources common + this platform on every shell start.
{
  echo '# cmdbook — sourced aliases'
  echo "for f in \"$DIR/common/aliases.sh\" \"$DIR/$PLATFORM/aliases.sh\"; do"
  echo '  [ -f "$f" ] && . "$f"'
  echo 'done'
} > "$LOADER"

MARK="# >>> cmdbook >>>"
if ! grep -qF "$MARK" "$RC" 2>/dev/null; then
  {
    echo ""
    echo "$MARK"
    echo "[ -f \"$LOADER\" ] && . \"$LOADER\""
    echo "# <<< cmdbook <<<"
  } >> "$RC"
  echo "Added cmdbook loader to $RC"
else
  echo "cmdbook already installed in $RC"
fi

echo "Run:  source $RC   (or open a new shell)"
