#!/usr/bin/env bash
# install.sh — make cmdbook aliases available in your shell.
# Adds a single source line to your shell rc that loads common/ + the file
# matching the current platform. Re-run anytime; it won't duplicate the line.
#
#   ./install.sh        installs into your rc, then tells you to reload
#   source install.sh   installs AND activates the aliases in THIS shell now
#
# (A script run normally can't touch the shell that launched it — only a
#  sourced script can — so immediate activation requires `source`.)

# Detect whether we're being sourced or executed.
_sourced=0
if [ -n "${BASH_SOURCE:-}" ] && [ "${BASH_SOURCE[0]}" != "${0}" ]; then _sourced=1; fi

# Only harden options when executed — set -e etc. would leak into your
# interactive shell if we're sourced.
[ "$_sourced" -eq 0 ] && set -euo pipefail

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
  echo "export CMDBOOK_DIR=\"$DIR\""        # so cmd-update knows where the repo is
  echo "for f in \"\$CMDBOOK_DIR/common/aliases.sh\" \"\$CMDBOOK_DIR/$PLATFORM/aliases.sh\"; do"
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

if [ "$_sourced" -eq 1 ]; then
  # We're sourced — load the aliases straight into the current shell.
  [ -f "$LOADER" ] && . "$LOADER"
  echo "cmdbook aliases active in this shell ✓"
else
  echo "Run:  source $RC   (or open a new shell)"
  echo "Tip:  next time use  'source install.sh'  to activate immediately"
fi
