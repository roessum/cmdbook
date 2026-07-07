# macOS aliases — short names for the commands I keep forgetting.
# Sourced by install.sh. Every line is commented so you can see what it does.

# ── dev tunnels ─────────────────────────────────────────────────────────────
# SSH-tunnel Keycloak's 8180 to localhost (uses the `keycloak` host in ssh config).
# Then open: http://keycloak.kaerepleje.plaain.com:8180  (domain is pinned to 127.0.0.1)
alias keycloak-web='ssh-web keycloak 8180'
# Log in to kaerepleje AND forward 8180 (interactive shell + tunnel in one).
alias plaain-tunnel='ssh -i ~/.ssh/rar-plaain-demo -L 8180:localhost:8180 plaain@kaerepleje.plaain.com'

# ── plaain deploy / relay ───────────────────────────────────────────────────
# Watch the newest run of the release workflow.
release-watch() { gh run watch "$(gh run list --workflow=release.yml -L1 --json databaseId --jq '.[0].databaseId')"; }
# Trigger a deploy.  deploy-run <customer> [tag]   (tag defaults to latest)
deploy-run() {
  [ -n "$1" ] || { echo "usage: deploy-run <customer> [tag]"; return 1; }
  gh workflow run deploy.yml -f customer="$1" -f tag="${2:-latest}"
}
# Run the relay's automatic job now. Give an ssh host to run it remotely,
# or no argument when you're already on the VM.  relay-run [ssh-host]
relay-run() {
  if [ -n "$1" ]; then ssh -t "$1" 'docker exec plaain-relay python main.py --mode automatic --run-now'
  else docker exec plaain-relay python main.py --mode automatic --run-now; fi
}
# Open a bash shell inside the relay container.  relay-bash [ssh-host]
relay-bash() {
  if [ -n "$1" ]; then ssh -t "$1" 'docker exec -it plaain-relay /bin/bash'
  else docker exec -it plaain-relay /bin/bash; fi
}
# Show the relay's deploy info (which build/customer/tag is running).  relay-info [ssh-host]
relay-info() {
  if [ -n "$1" ]; then ssh "$1" 'docker exec plaain-relay cat /config/deploy-info.json'
  else docker exec plaain-relay cat /config/deploy-info.json; fi
}
