# macOS aliases — short names for the commands I keep forgetting.
# Sourced by install.sh. Every line is commented so you can see what it does.

# ── dev tunnels ─────────────────────────────────────────────────────────────
# SSH-tunnel Keycloak's 8180 to localhost (uses the `keycloak` host in ssh config).
# Then open: http://keycloak.kaerepleje.plaain.com:8180  (domain is pinned to 127.0.0.1)
alias keycloak-web='ssh-web keycloak 8180'
