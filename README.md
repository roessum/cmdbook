# cmdbook 📖

Commands I keep forgetting, turned into short aliases — each with a comment on
every line — plus a few diagnostic functions for my Raspberry Pi router. Type
the short name, get the real command. Stop re-googling.

## Structure

- `common/` — works on every platform (`aliases.sh`, `ssh-config.example`)
- `ubuntu/` — Ubuntu/Debian/Raspberry Pi (`aliases.sh`)
- `macos/` — macOS
- `windows/` — Windows 11 PowerShell

`common/aliases.sh` + the file matching the current platform are both sourced.
Open any `aliases.sh` to read what each alias does — every line is commented.

## Install

```bash
source install.sh      # installs AND activates aliases in this shell now
# or:  ./install.sh    # installs, then tells you to reload
```

It adds one loader line to your shell rc, so `common/` + your platform load on
every new shell. Re-run anytime — it won't duplicate itself.

## What's inside

**common/** — git (status, branches, stash, undo, rebase, sync, tags), ssh +
ssh-agent (unlock a key once per boot, reused across shells), and `cmd-update`
to pull the latest cmdbook and reload it into the current shell.

**ubuntu/** (the Pi router) — hostapd/AP control, WireGuard, DNS, DHCP
(dnsmasq), NetworkManager, `ip route`/`ip link`, nftables firewall (`fw*`),
Caddy web server, plus diagnostics:

- `wifi-doctor [iface]` — one-shot AP health check (adapters, link/carrier,
  rfkill, reg domain, hostapd, dnsmasq, IP, NetworkManager conflict, clients,
  recent warnings) with ✓/⚠/✗ and a hint per problem.
- `wifi-bands` — which interface is 2.4 GHz vs 5 GHz, with channel + SSID.
- `net-doctor` — end-to-end router path: ip_forward, every interface IP,
  default route, gateway, internet, DNS, and whether nftables actually has
  masquerade + forward rules.

## Examples

```bash
gs               # git status -sb
gstu             # git stash -u  (stash incl. untracked)
gundo            # undo last commit, keep changes staged
cmd-update       # git pull + reload aliases into this shell
ap-status        # systemctl status hostapd-wlan0
wifi-doctor      # run the AP health check
net-doctor       # test the whole routing path
fw               # show the nftables ruleset
sshkey           # print my SSH public key
```

## Browse by category

The `# ── … ──` section headers are the categories. Browse them without
leaving the shell:

```bash
cmdbook                  # every platform and its categories
cmdbook ubuntu           # categories on the Pi (wifi, dns, dhcp, nftables…)
cmdbook ubuntu network   # show the commands in matching categories
```

The last argument is a case-insensitive filter matching the category name *or
any command inside it*, and prints every category that matches — try `git`,
`ssh`, `wifi`, `route`, `masquerade`, `firewall`, `wireguard`, …

## Add what you forget

Drop a new `alias name='command'  # what it does` line in the right `aliases.sh`
(`common/` if it works everywhere), reload, and it's there. That's the whole
point.

## Check for clashes

`common/` and the platform file are both sourced, so two aliases with the same
name would silently shadow each other. Catch that:

```bash
./check.sh        # lists any duplicate alias/function names (with file:line)
```
