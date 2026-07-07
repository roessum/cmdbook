# Ubuntu / Raspberry Pi aliases — short names for the commands I keep forgetting.
# Sourced by install.sh. Every line is commented so you can see what it does.

# ── cmdbook auto-update (cron) ──────────────────────────────────────────────
# Keep the repo fresh in the background. NOTE: cron has no ssh-agent, so the
# pull must work non-interactively — use a passwordless deploy key or an HTTPS
# remote, otherwise a passphrase-protected SSH key will make the cron job hang.
# Running shells still pick up changes only on a new shell or `cmd-update`.
alias cron-edit='crontab -e'                                   # edit your crontab
alias cron-list='crontab -l'                                   # show your crontab
cmd-cron-on() {   # enable a pull every 6 hours
  local d="${CMDBOOK_DIR:-$HOME/cmdbook}"
  ( crontab -l 2>/dev/null | grep -v "cmdbook pull"; \
    echo "0 */6 * * * git -C $d pull --quiet # cmdbook pull" ) | crontab -
  echo "cmdbook auto-update on (every 6h) — needs non-interactive git auth"
}
cmd-cron-off() {  # remove the auto-update job
  crontab -l 2>/dev/null | grep -v "cmdbook pull" | crontab - 2>/dev/null
  echo "cmdbook auto-update off"
}

# ── hostapd / access point ──────────────────────────────────────────────────
# tags: wifi ap accesspoint beacon ssid 2.4ghz 5ghz radio
alias ap-status='sudo systemctl status hostapd-wlan0'         # is the AP service running?
alias ap-restart='sudo systemctl restart hostapd'             # restart the access point
alias ap-stop='sudo killall hostapd'                          # kill all hostapd processes
alias ap-log='sudo journalctl -u hostapd --since "1 minute ago" | tail -20'  # last minute of logs
alias ap-logf='sudo journalctl -u hostapd -f'                 # follow hostapd logs live
alias ap-debug='sudo hostapd -d /etc/hostapd/hostapd.conf'    # run in foreground, debug output
alias ap-conf='sudo hostapd /etc/hostapd/hostapd-wlan0.conf'  # run a specific config file

# ── wifi diagnose ───────────────────────────────────────────────────────────
alias usb='lsusb'                                             # list USB devices (find WiFi adapters)
alias wifi0='iwconfig wlan0'                                  # status of wlan0
alias wifi1='iwconfig wlan1'                                  # status of wlan1
alias wifi-info='iw dev wlan1 info'                           # detailed interface info
alias wifi-clients='sudo iw dev wlan1 station dump'           # connected clients on wlan1
alias wifi-vht='iw phy phy0 info | grep -A 10 "VHT Capabilities"'  # check 5 GHz / VHT support
alias wifi-reg='sudo iw reg get'                             # show current regulatory domain
alias wifi-country-dk='sudo raspi-config nonint do_wifi_country DK'  # set WiFi country to DK

# Run a battery of AP/WiFi health checks and flag the likely culprit.
# Usage:  wifi-doctor [interface]   (default wlan0).  Uses sudo for a few checks.
wifi-doctor() {
  local IF="${1:-wlan0}" P="✓" W="⚠" F="✗"
  printf '── wifi-doctor (%s) ──────────────────────────\n' "$IF"

  printf '%-18s' "adapters:"
  if iw dev 2>/dev/null | grep -q Interface; then
    echo "$P $(iw dev 2>/dev/null | grep -c Interface) wireless interface(s)"
  else
    echo "$F none found — check 'lsusb' / driver loaded"
  fi

  printf '%-18s' "$IF link:"
  if ip link show "$IF" >/dev/null 2>&1; then
    # For an AP (master mode) operstate/carrier lies — the AP IS the carrier.
    # The real "is it beaconing" signal is: iw reports type AP and a channel.
    local typ chan
    typ=$(iw dev "$IF" info 2>/dev/null | awk '$1=="type"{print $2}')
    chan=$(iw dev "$IF" info 2>/dev/null | awk '$1=="channel"{print $2}')
    if [ "$typ" = "AP" ] && [ -n "$chan" ]; then echo "$P AP up (ch $chan)"
    elif ip link show "$IF" | grep -qw UP;     then echo "$W admin-up, type=${typ:-?} (not an active AP)"
    else echo "$F admin DOWN — 'sudo ip link set $IF up'"; fi
  else
    echo "$F interface not found"
  fi

  printf '%-18s' "rfkill:"
  if command -v rfkill >/dev/null 2>&1; then
    if rfkill list 2>/dev/null | grep -qi "blocked: yes"; then echo "$F radio BLOCKED — 'sudo rfkill unblock wifi'"
    else echo "$P not blocked"; fi
  else echo "$W rfkill not installed"; fi

  printf '%-18s' "reg domain:"
  local reg; reg=$(iw reg get 2>/dev/null | awk '/^country/{gsub(/:/,"",$2); print $2; exit}')
  if [ -z "$reg" ] || [ "$reg" = "00" ]; then
    echo "$W unset (00) — 5GHz/channels limited. 'wifi-country-dk'"
  else echo "$P $reg"; fi

  printf '%-18s' "hostapd:"
  if systemctl is-active --quiet hostapd 2>/dev/null || systemctl is-active --quiet hostapd-wlan0 2>/dev/null; then
    echo "$P running"
  else echo "$F not running — 'ap-status' for why"; fi

  printf '%-18s' "dnsmasq (DHCP):"
  if systemctl is-active --quiet dnsmasq 2>/dev/null; then echo "$P running"
  else echo "$W not running — clients won't get an IP"; fi

  printf '%-18s' "$IF address:"
  local addr; addr=$(ip -4 addr show "$IF" 2>/dev/null | awk '/inet /{print $2; exit}')
  if [ -n "$addr" ]; then echo "$P $addr"; else echo "$W no IPv4 — AP needs a static address"; fi

  printf '%-18s' "NM on $IF:"
  if command -v nmcli >/dev/null 2>&1; then
    case "$(nmcli -t -f DEVICE,STATE device 2>/dev/null | awk -F: -v i="$IF" '$1==i{print $2}')" in
      unmanaged) echo "$P unmanaged (good for a hostapd AP)" ;;
      "")        echo "$W not listed — 'net-status'" ;;
      *)         echo "$W managed by NetworkManager — may fight hostapd" ;;
    esac
  else echo "$P no NetworkManager"; fi

  printf '%-18s' "clients on $IF:"
  echo "$(sudo iw dev "$IF" station dump 2>/dev/null | grep -c Station) connected"

  echo "recent hostapd warnings:"
  sudo journalctl -u hostapd -u hostapd-wlan0 --since "5 min ago" -p warning -q 2>/dev/null | tail -5 | sed 's/^/    /'
  echo "──────────────────────────────────────────────"
}
alias wifi-debug='wifi-doctor'                               # alias for wifi-doctor

# Show each wireless interface with its band (2.4 vs 5 GHz), channel and SSID.
wifi-bands() {
  local d info ssid chan mhz band
  for d in $(iw dev 2>/dev/null | awk '/Interface/{print $2}'); do
    info=$(iw dev "$d" info 2>/dev/null)
    ssid=$(printf '%s\n' "$info" | awk '/\<ssid\>/{print $2}')
    chan=$(printf '%s\n' "$info" | awk '/\<channel\>/{print $2}')
    mhz=$(printf '%s\n'  "$info" | grep -oE '[0-9]+ MHz' | head -1 | grep -oE '[0-9]+')
    if   [ -z "$mhz" ];                  then band="(idle)"   # not on a channel = AP down/inactive
    elif [ "$mhz" -ge 5000 ] 2>/dev/null; then band="5 GHz"
    else                                      band="2.4 GHz"; fi
    printf '%-6s %-8s ch %-4s ssid=%s\n' "$d" "$band" "${chan:-–}" "${ssid:-(none)}"
  done
}

# ── interface control (usage: wlan-up wlan0 / wlan-down wlan0) ──────────────
wlan-up()   { sudo ip link set "${1:-wlan0}" up; }            # bring an interface up (default wlan0)
wlan-down() { sudo ip link set "${1:-wlan0}" down; }          # bring an interface down (default wlan0)

# ── wireguard VPN (assumes interface wg0) ───────────────────────────────────
# tags: vpn tunnel peer handshake
alias wg-show='sudo wg show'                                  # tunnels, peers, handshakes, transfer
alias wg-up='sudo wg-quick up wg0'                            # bring the wg0 tunnel up
alias wg-down='sudo wg-quick down wg0'                        # bring the wg0 tunnel down
wg-restart() { sudo wg-quick down wg0; sudo wg-quick up wg0; }  # bounce the tunnel
alias wg-status='sudo systemctl status wg-quick@wg0'          # service status
alias wg-enable='sudo systemctl enable --now wg-quick@wg0'    # start on boot + now
alias wg-conf='sudo nano /etc/wireguard/wg0.conf'            # edit the tunnel config
alias wg-latest='sudo wg show wg0 latest-handshakes'          # last handshake per peer
# make a keypair:  prints private key, writes public key next to it
wg-keys() { wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey; }

# ── DNS ─────────────────────────────────────────────────────────────────────
# tags: resolver nameserver resolv systemd-resolved lookup
alias dns-status='resolvectl status'                          # current DNS servers per link
alias dns-flush='sudo resolvectl flush-caches'                # clear the DNS cache
alias dns-query='resolvectl query'                            # resolve a name (add a hostname)
alias dns-conf='cat /etc/resolv.conf'                        # what's actually being used
alias dns-restart='sudo systemctl restart systemd-resolved'   # restart the resolver

# ── DHCP (dnsmasq) ──────────────────────────────────────────────────────────
# tags: lease ip-assignment address-pool
alias dhcp-leases='cat /var/lib/misc/dnsmasq.leases'          # who got which IP
alias dhcp-restart='sudo systemctl restart dnsmasq'           # restart dnsmasq
alias dhcp-status='sudo systemctl status dnsmasq'             # is dnsmasq running?
alias dhcp-log='sudo journalctl -u dnsmasq -f'               # follow dnsmasq logs live
dhcp-renew() { sudo dhclient -r "${1:-}"; sudo dhclient "${1:-}"; }  # release + renew lease (opt. iface)

# ── NetworkManager ──────────────────────────────────────────────────────────
alias net-status='nmcli device status'                        # device overview
alias net-restart='sudo systemctl restart NetworkManager'     # restart NetworkManager
alias nm-conns='nmcli connection show'                        # all saved connections
alias nm-active='nmcli connection show --active'              # currently active connections
alias nm-up='nmcli connection up'                             # activate a connection (add a name)
alias nm-down='nmcli connection down'                         # deactivate a connection (add a name)
alias nm-reload='sudo nmcli connection reload'                # reload conn files from disk
alias nm-scan='nmcli device wifi list'                        # scan for nearby WiFi networks

# ── ip route ────────────────────────────────────────────────────────────────
alias routes='ip route'                                       # the routing table
alias route6='ip -6 route'                                     # IPv6 routing table
alias route-get='ip route get'                                # which route an IP uses (add an IP)
alias route-default='ip route show default'                   # show the default gateway
alias route-add='sudo ip route add'                           # add a route (add  <net> via <gw>)
alias route-del='sudo ip route del'                           # delete a route (add  <net>)

# ── ip link / addresses ─────────────────────────────────────────────────────
alias links='ip -br link'                                      # interfaces, brief (up/down state)
alias addrs='ip -br addr'                                      # interfaces + their IPs, brief
alias link-show='ip link show'                                # full link details (opt. add iface)
alias link-up='sudo ip link set'                              # set an iface up:  link-up wlan0 up
alias link-stats='ip -s link'                                 # per-interface RX/TX stats

# ── routing / connectivity health check ─────────────────────────────────────
# Test the whole router path: forwarding, local IPs, route, internet, DNS, NAT.
net-doctor() {
  local P="✓" W="⚠" F="✗" a gw
  printf '── net-doctor ──────────────────────────────\n'

  printf '%-20s' "ip_forward:"
  if [ "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)" = "1" ]; then echo "$P enabled"
  else echo "$F OFF — routing dead. 'sudo sysctl -w net.ipv4.ip_forward=1' + /etc/sysctl.conf"; fi

  echo "interfaces & IPs:"
  ip -br -4 addr 2>/dev/null | awk '$1!="lo"{printf "    %-8s %-7s %s\n",$1,$2,$3}'

  printf '%-20s' "local IPs respond:"; echo
  for a in $(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1); do
    if ping -c1 -W1 "$a" >/dev/null 2>&1; then echo "    $P $a"; else echo "    $F $a not responding"; fi
  done

  gw=$(ip route show default 2>/dev/null | awk '/default/{print $3; exit}')
  printf '%-20s' "default route:"
  if [ -n "$gw" ]; then echo "$P via $gw"; else echo "$F none — no path off the LAN"; fi

  local inet=0
  printf '%-20s' "internet (1.1.1.1):"
  if ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; then inet=1; echo "$P reachable"; else echo "$F no internet — check NAT/route"; fi

  printf '%-20s' "gateway reachable:"
  if [ -z "$gw" ]; then echo "$F no gateway"
  elif ping -c1 -W1 "$gw" >/dev/null 2>&1; then echo "$P $gw"
  elif [ "$inet" = 1 ]; then echo "$P $gw (no ping reply, but internet works — ISP likely blocks ICMP)"
  else echo "$F can't reach $gw"; fi

  printf '%-20s' "DNS resolves:"
  if getent hosts github.com >/dev/null 2>&1; then echo "$P ok"; else echo "$W fails (but ping-by-IP worked? then it's DNS)"; fi

  printf '%-20s' "NAT (masquerade):"
  if sudo nft list ruleset 2>/dev/null | grep -q masquerade; then echo "$P present"
  else echo "$W none — AP clients can't reach the internet"; fi

  printf '%-20s' "forward rules:"
  if sudo nft list ruleset 2>/dev/null | grep -qiE 'chain .*forward|type filter hook forward'; then echo "$P forward chain present"
  else echo "$W no forward chain — clients between subnets/WAN may be blocked"; fi
  echo "──────────────────────────────────────────────"
}
alias net-test='net-doctor'                                   # alias for net-doctor

# ── web server (Caddy — auto HTTPS) ─────────────────────────────────────────
alias web-conf='sudo nano /etc/caddy/Caddyfile'               # edit the site config
alias web-test='sudo caddy validate --config /etc/caddy/Caddyfile'  # check config is valid
alias web-reload='sudo systemctl reload caddy'                # apply config without dropping connections
alias web-restart='sudo systemctl restart caddy'             # full restart
alias web-status='sudo systemctl status caddy'               # is it running?
alias web-log='sudo journalctl -u caddy -f'                  # follow web server logs live
alias myip='curl -s ifconfig.me; echo'                       # my public IP (compare vs WAN IP for CGNAT)
alias dns-check='dig +short'                                  # what a domain resolves to (add a domain)
alias ports-open='sudo ss -tlnp'                              # which ports are listening locally

# ── nftables firewall ───────────────────────────────────────────────────────
# tags: iptables firewall nat masquerade packet-filter port-forward
alias fw='sudo nft list ruleset'                              # show the whole ruleset
alias fw-handles='sudo nft -a list ruleset'                   # ruleset WITH handles (needed to delete a rule)
alias fw-tables='sudo nft list tables'                        # just the table names
alias fw-edit='sudo nano /etc/nftables.conf'                  # edit the persistent ruleset
alias fw-test='sudo nft -c -f /etc/nftables.conf'             # validate the file WITHOUT applying it
alias fw-apply='sudo nft -f /etc/nftables.conf'               # load the ruleset from the file
alias fw-reload='sudo systemctl restart nftables'             # reload via the service
alias fw-status='sudo systemctl status nftables'              # is the service running?
alias fw-monitor='sudo nft monitor'                           # watch ruleset changes live
alias fw-save='sudo nft list ruleset | sudo tee /etc/nftables.conf'  # persist running rules to the file
alias fw-flush='sudo nft flush ruleset'                       # wipe ALL rules (careful — can lock you out)

# ── ssh-agent (Pi key) ──────────────────────────────────────────────────────
alias ssh-load='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/pi'  # start agent + unlock the pi key once

# ── uptime & shutdown history ───────────────────────────────────────────────
# NB: minimal Pi OS has no `last`/wtmp, so this uses journalctl. Needs a
# PERSISTENT journal to see previous boots — enable once with `journal-persist`.
alias up='uptime -p'                                          # how long has it been up (pretty)
alias boot-time='uptime -s'                                   # exact time it last booted
alias boots='journalctl --list-boots'                         # each boot + its time range (gaps = downtime)
alias last-boot='sudo journalctl -b -1 -n 30 --no-pager'      # tail of the PREVIOUS boot (how it ended)
alias journal-persist='sudo mkdir -p /var/log/journal && sudo systemd-tmpfiles --create --prefix /var/log/journal && sudo systemctl restart systemd-journald'  # keep logs across reboots
# Show WHEN it last went down and try to explain WHY (clean vs crash/power loss).
why-down() {
  echo "── boots systemd remembers (id, first → last message) ──"
  journalctl --list-boots 2>/dev/null | tail -10 || echo "(need sudo, or no persistent journal — run journal-persist)"
  echo
  echo "── how the PREVIOUS boot ended ──"
  # Clean shutdown ends with 'Reached target ... Power-Off/Reboot' or
  # 'systemd-shutdown ... Powering off'. Log just stopping = crash/power loss.
  if sudo journalctl -b -1 -n 20 --no-pager >/tmp/.whydown 2>/dev/null && [ -s /tmp/.whydown ]; then
    cat /tmp/.whydown; rm -f /tmp/.whydown
  else
    echo "(no previous boot in the journal — it's likely volatile; run 'journal-persist')"
  fi
  echo
  echo "── errors during the previous boot ──"
  sudo journalctl -b -1 -p err --no-pager 2>/dev/null | tail -15
}
alias last-down='why-down'                                    # alias for why-down

# ── ssh server: who's on & which keys ───────────────────────────────────────
alias ssh-who='w'                                             # who is logged in + what they're doing
alias ssh-active='ss -tnp state established sport = :22'      # live ssh connections (IPs)
alias ssh-logins='sudo journalctl -u ssh -u sshd --no-pager | grep -E "Accepted|Failed" | tail -20'  # recent auth (ok + failed)
# Recent successful key logins: time, user@ip, key type + fingerprint.
ssh-key-logins() {
  sudo journalctl -u ssh -u sshd --no-pager 2>/dev/null | grep "Accepted publickey" | awk '
    { ts=$1" "$2" "$3
      for(i=1;i<=NF;i++){ if($i=="for")u=$(i+1); if($i=="from")ip=$(i+1) }
      printf "%-15s %-22s %s %s\n", ts, u"@"ip, $(NF-1), $NF }' | tail -20
}
# For each key in an authorized_keys file: its comment, fingerprint, and when it
# was last used to log in (from the journal).  ssh-key-usage [authorized_keys]
ssh-key-usage() {
  local ak="${1:-$HOME/.ssh/authorized_keys}" tmp fp comment last
  [ -f "$ak" ] || { echo "no authorized_keys at $ak"; return 1; }
  tmp=$(mktemp)
  sudo journalctl -u ssh -u sshd --no-pager 2>/dev/null | grep "Accepted publickey" \
    | sed -E 's/^(\w+ +[0-9]+ [0-9:]+).*(SHA256:[A-Za-z0-9+/=]+).*/\2 \1/' > "$tmp"
  echo "keys in $ak:"
  while IFS= read -r line; do
    case "$line" in ""|\#*) continue ;; esac
    fp=$(printf '%s\n' "$line" | ssh-keygen -lf /dev/stdin 2>/dev/null | awk '{print $2}')
    comment=$(printf '%s' "$line" | awk '{print $NF}')
    last=$(grep -F "$fp" "$tmp" 2>/dev/null | tail -1 | cut -d' ' -f2-)
    printf '  %-16s %-50s last: %s\n' "$comment" "$fp" "${last:-never seen in journal}"
  done < "$ak"
  rm -f "$tmp"
}

# ── system / services ───────────────────────────────────────────────────────
alias reload='sudo systemctl daemon-reload'                   # reload unit files after editing
alias svc-status='sudo systemctl status'                      # status of a service (add a name)
alias svc-enable='sudo systemctl enable --now'                # enable + start a service now (add a name)
