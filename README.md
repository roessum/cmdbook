# cmdbook 📖

Commands I keep forgetting, turned into short aliases with a comment on every
line — so I can stop re-googling them. Type the short name, get the real command.

## Structure

- `common/` — works on every platform (`aliases.sh`, `ssh-config.example`)
- `ubuntu/` — Ubuntu/Debian/Raspberry Pi (`aliases.sh`)
- `macos/` — macOS
- `windows/` — Windows 11 PowerShell

Open any `aliases.sh` to read what each alias does — every line is commented.

## Install

```bash
bash install.sh
source ~/.zshrc      # or open a new shell
```

This sources `common/aliases.sh` plus the file matching your platform on every
shell start. Re-run anytime — it won't duplicate itself.

## Examples

```bash
gs               # git status -sb
gstu             # git stash -u  (stash incl. untracked)
gundo            # undo last commit, keep changes staged
ap-status        # sudo systemctl status hostapd-wlan0
wifi-clients     # connected stations on wlan1
sshkey           # print my SSH public key
```

## Add what you forget

Drop a new `alias name='command'  # what it does` line in the right `aliases.sh`
(or `common/` if it works everywhere), `source ~/.zshrc`, and it's there.
That's the whole point.

## Check for clashes

`common/aliases.sh` and the platform file are both sourced, so two aliases with
the same name would silently shadow each other. Catch that:

```bash
./check.sh        # lists any duplicate alias/function names (with file:line)
```

