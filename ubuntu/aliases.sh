# Ubuntu / Raspberry Pi aliases — short names for the commands I keep forgetting.
# Sourced by install.sh. Every line is commented so you can see what it does.

# ── hostapd / access point ──────────────────────────────────────────────────
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

# ── interface control (usage: wlan-up wlan0 / wlan-down wlan0) ──────────────
wlan-up()   { sudo ip link set "${1:-wlan0}" up; }            # bring an interface up (default wlan0)
wlan-down() { sudo ip link set "${1:-wlan0}" down; }          # bring an interface down (default wlan0)

# ── wireguard VPN (assumes interface wg0) ───────────────────────────────────
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
alias dns-status='resolvectl status'                          # current DNS servers per link
alias dns-flush='sudo resolvectl flush-caches'                # clear the DNS cache
alias dns-query='resolvectl query'                            # resolve a name (add a hostname)
alias dns-conf='cat /etc/resolv.conf'                        # what's actually being used
alias dns-restart='sudo systemctl restart systemd-resolved'   # restart the resolver

# ── DHCP (dnsmasq) ──────────────────────────────────────────────────────────
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

# ── system / services ───────────────────────────────────────────────────────
alias reload='sudo systemctl daemon-reload'                   # reload unit files after editing
alias svc-status='sudo systemctl status'                      # status of a service (add a name)
alias svc-enable='sudo systemctl enable --now'                # enable + start a service now (add a name)
