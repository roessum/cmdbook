# Cross-platform aliases — sourced on every machine.
# Every line is commented so you can see what it actually does.
# Aliases that need an argument just prefix the command — type the rest after it,
# e.g.  gsw my-branch   ->   git switch my-branch

# ── cmdbook itself ──────────────────────────────────────────────────────────
# Pull the latest cmdbook and reload it into THIS shell. Loads the ssh key into
# the agent first, so you type the passphrase at most once per boot (not per pull).
# Override the key it loads with CMDBOOK_KEY if auto-detection guesses wrong.
cmd-update() {
  local d="${CMDBOOK_DIR:-$HOME/cmdbook}" host key
  ssh-agent-ensure 2>/dev/null                        # start/reuse a persistent agent
  if ! ssh-add -l >/dev/null 2>&1; then               # agent has no key → add the one origin uses
    key="$CMDBOOK_KEY"
    [ -z "$key" ] && host=$(git -C "$d" remote get-url origin 2>/dev/null | sed -E 's#^[a-z]+://##; s/.*@//; s/[:/].*//')
    [ -z "$key" ] && key=$(ssh -G "${host:-github.com}" 2>/dev/null | awk '/^identityfile /{print $2; exit}')
    case "$key" in "~/"*) key="$HOME/${key#\~/}" ;; esac
    [ -n "$key" ] && [ -f "$key" ] && ssh-add "$key"   # prompts for passphrase once, then remembered
  fi
  git -C "$d" pull && . "$d/load.sh" && echo "cmdbook updated + reloaded ✓"
}
alias cmd-edit='${EDITOR:-nano} "${CMDBOOK_DIR:-$HOME/cmdbook}"'   # open the repo to add aliases
# List when each alias/function was first added (from git history), newest last.
# cmd-new [N] shows the N most recently added (default 20).
cmd-new() {
  local d="${CMDBOOK_DIR:-$HOME/cmdbook}" n="${1:-20}"
  git -C "$d" log --reverse --date=short --format='COMMIT %ad' -p -- '*aliases.sh' 2>/dev/null | awk '
    /^COMMIT / { date=$2; next }
    /^\+[[:space:]]*alias [A-Za-z0-9_-]+=/ {
      s=$0; sub(/^\+[[:space:]]*alias /,"",s); sub(/=.*/,"",s)
      if (!(s in seen)) { seen[s]=date; ord[++k]=s } }
    /^\+[[:space:]]*[A-Za-z0-9_-]+\(\)/ {
      s=$0; sub(/^\+[[:space:]]*/,"",s); sub(/\(\).*/,"",s)
      if (!(s in seen)) { seen[s]=date; ord[++k]=s } }
    END { for (i=1;i<=k;i++) printf "%s  %s\n", seen[ord[i]], ord[i] }
  ' | tail -n "$n"
}

# Print sections of a file that match a term (in the header, a command, a
# comment, or a "# tags:" line). Args: file, term, platform-label (optional).
_cmdbook_filter() {
  awk -v want="$(printf %s "$2" | tr 'A-Z' 'a-z')" -v lbl="$3" '
    function flush() {
      if ((show || hit) && hdr != "") {
        printf "\n%s%s\n", (lbl != "" ? "[" lbl "] " : ""), hdr
        for (i=1;i<=n;i++) print body[i]
      }
      n=0; show=0; hit=0
    }
    /^# ──/ { flush(); hdr=substr($0,3); show=(index(tolower($0),want)>0); next }
    { if (index(tolower($0),want)>0) hit=1                    # match header OR any command/comment/tag
      if (/^alias / || /^[A-Za-z0-9_-]+\(\)/ || /^# /) body[++n]=$0 }
    END { flush() }
  ' "$1"
}

# Browse or search the book. Sections carry "# tags:" lines for synonyms.
#   cmdbook                     list every platform and its categories
#   cmdbook ubuntu              list categories for one platform
#   cmdbook ubuntu network      commands in matching categories (that platform)
#   cmdbook search <term>       search across ALL platforms by keyword
cmdbook() {
  local dir="${CMDBOOK_DIR:-$HOME/cmdbook}" plat="$1" filter="$2" f p
  if [ "$plat" = search ]; then
    shift; filter="$*"
    [ -n "$filter" ] || { echo "usage: cmdbook search <term>"; return 1; }
    for p in common ubuntu macos windows; do
      f="$dir/$p/aliases.sh"; [ -f "$f" ] && _cmdbook_filter "$f" "$filter" "$p"
    done; return
  fi
  if [ -z "$plat" ]; then
    echo "usage: cmdbook <platform> [category] | cmdbook search <term>"
    for p in common ubuntu macos windows; do
      f="$dir/$p/aliases.sh"; [ -f "$f" ] || continue
      printf '\n[%s]\n' "$p"; grep '^# ──' "$f" | sed 's/^# //'
    done; return
  fi
  f="$dir/$plat/aliases.sh"
  [ -f "$f" ] || { echo "no such platform: $plat (try: common ubuntu macos windows)"; return 1; }
  if [ -z "$filter" ]; then
    echo "[$plat] categories — 'cmdbook $plat <name>' to open one:"
    grep '^# ──' "$f" | sed 's/^# //'; return
  fi
  _cmdbook_filter "$f" "$filter" ""
}

# ── git: status & history ──────────────────────────────────────────────────
alias gs='git status -sb'                          # short status + branch info
alias gl='git log --oneline --graph --all'         # compact, visual history
alias glp='git log -p'                             # history with diffs (add a file)
alias gshow='git show'                             # what a commit changed (add a hash)
alias gd='git diff'                                # unstaged changes
alias gds='git diff --staged'                      # staged changes (what will commit)
alias gbl='git blame'                              # who last touched each line (add a file)

# ── git: branches ───────────────────────────────────────────────────────────
alias gsw='git switch'                             # change branch (add a name)
alias gswc='git switch -c'                         # create + switch to new branch (add a name)
alias gbd='git branch -d'                          # delete a merged branch (add a name)
alias gbD='git branch -D'                          # force-delete a branch (add a name)
alias gbm='git branch -m'                          # rename current branch (add a name)

# ── git: staging & committing ───────────────────────────────────────────────
alias ga='git add'                                 # stage a file (add a path)
alias gaa='git add -A'                             # stage everything
alias gap='git add -p'                             # stage chunk by chunk (interactive)
alias gunstage='git restore --staged'              # unstage but keep changes (add a file)
alias gdiscard='git restore'                       # discard working changes (add a file — careful)
alias gc='git commit -m'                           # commit with a message (add "msg")
alias gca='git commit --amend --no-edit'           # add staged changes to last commit

# ── git: stash (park changes without committing) ────────────────────────────
alias gst='git stash'                              # stash tracked changes away
alias gstu='git stash -u'                          # stash including untracked files
alias gstl='git stash list'                        # list all stashes
alias gsts='git stash show -p'                     # preview a stash's diff (add stash@{0})
alias gstp='git stash pop'                         # re-apply newest stash and drop it
alias gsta='git stash apply'                       # re-apply a stash but keep it (add stash@{n})
alias gstd='git stash drop'                        # delete one stash (add stash@{n})
alias gstc='git stash clear'                       # delete all stashes

# ── git: undo & fix mistakes ────────────────────────────────────────────────
alias gundo='git reset --soft HEAD~1'              # undo last commit, keep changes staged
alias gunstageall='git reset --mixed HEAD~1'       # undo last commit, keep changes unstaged
alias ghardundo='git reset --hard HEAD~1'          # undo last commit AND discard changes (careful)
alias grevert='git revert'                         # new commit that undoes an old one (add a hash)
alias greflog='git reflog'                         # find "lost" commits to recover

# ── git: sync with remote ───────────────────────────────────────────────────
alias gp='git pull'                                # fetch + merge
alias gpr='git pull --rebase'                      # fetch + rebase (linear history)
alias gpush='git push'                             # push current branch
alias gpushu='git push -u origin'                  # push + set upstream (add branch name)
alias gpushf='git push --force-with-lease'         # safe force-push (won't clobber others)
alias gfetch='git fetch --all --prune'             # update remotes, drop deleted branches

# ── git: rebase & merge ─────────────────────────────────────────────────────
alias gm='git merge'                               # merge a branch into current (add a name)
alias grb='git rebase'                             # replay current branch onto another (add a name)
alias grbi='git rebase -i'                         # interactive rebase (add e.g. HEAD~3)
alias grba='git rebase --abort'                    # bail out of a messy rebase
alias gcp='git cherry-pick'                        # copy one commit onto current branch (add a hash)

# ── git: clone & tags ───────────────────────────────────────────────────────
alias gcl='git clone'                              # clone a repo (add a URL)
alias gtag='git tag -a'                            # annotated tag (add  v1.0 -m "msg")
alias gpushtags='git push --tags'                  # push all tags

# ── ssh ─────────────────────────────────────────────────────────────────────
alias sshkey='cat ~/.ssh/id_ed25519.pub'           # print my SSH public key (add to GitHub)
alias sshtest='ssh -T git@github.com'              # test the GitHub SSH connection
alias sshgen='ssh-keygen -t ed25519 -C'            # make a new ed25519 key (add "your@email")
alias ssh-keys='ssh-add -l'                        # list keys the agent has loaded
alias ssh-forget='ssh-add -D'                      # drop all keys from the agent now
ssh-unlock() { eval "$(ssh-agent -s)"; ssh-add "${1:-$HOME/.ssh/id_ed25519}"; }  # start agent + add a key (default id_ed25519)
alias ssh-debug='ssh -vvv'                         # verbose connection debug (add user@host)
ssh-fp() { ssh-keygen -lf "${1:-$HOME/.ssh/id_ed25519.pub}"; }   # fingerprint of a key file

# ── ssh: authorized_keys management ─────────────────────────────────────────
alias authkeys-list='ssh-keygen -lf ~/.ssh/authorized_keys 2>/dev/null || cat ~/.ssh/authorized_keys'  # fingerprints of allowed keys
alias authkeys-edit='${EDITOR:-nano} ~/.ssh/authorized_keys'   # edit the file directly
authkeys-setup() {   # create ~/.ssh + authorized_keys with correct permissions
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
  echo "~/.ssh/authorized_keys ready (700/600)"
}
authkeys-add() {     # authkeys-add <pubkey-file | "ssh-ed25519 AAAA... comment">
  local key="$*"
  [ -n "$key" ] || { echo 'usage: authkeys-add <pubkey-file | "ssh-... AAAA... comment">'; return 1; }
  [ -f "$key" ] && key=$(cat "$key")
  case "$key" in ssh-*|ecdsa-*|sk-*) : ;; *) echo "that doesn't look like a public key"; return 1 ;; esac
  authkeys-setup >/dev/null
  grep -qF "$key" ~/.ssh/authorized_keys 2>/dev/null && { echo "already present"; return 0; }
  printf '%s\n' "$key" >> ~/.ssh/authorized_keys
  echo "added: $(printf '%s' "$key" | awk '{print $NF}')"
}

# Make sure a single ssh-agent is running and REUSED across all shells, so you
# unlock a key once per boot instead of once per terminal. Does nothing if an
# agent is already reachable (e.g. the macOS Keychain agent).
ssh-agent-ensure() {
  ssh-add -l >/dev/null 2>&1; [ $? -ne 2 ] && return 0      # agent already reachable
  local env="$HOME/.ssh/agent.env"
  if [ -f "$env" ]; then . "$env" >/dev/null 2>&1; ssh-add -l >/dev/null 2>&1; [ $? -ne 2 ] && return 0; fi
  (umask 077; ssh-agent -s > "$env") && . "$env" >/dev/null 2>&1   # start a fresh persistent agent
}
case $- in *i*) ssh-agent-ensure 2>/dev/null ;; esac   # auto-run in interactive shells

# ── /etc/hosts & SSH tunnels ────────────────────────────────────────────────
alias host-show='cat /etc/hosts'                   # show the hosts file
alias port-test='nc -zv'                           # is a port open?  port-test host 8180
# Reverse DNS for an IP using whatever is installed (getent works without dig,
# and on the Pi it even answers from dnsmasq's DHCP names).  rdns 10.0.1.5
rdns() {
  local ip="$1" r; [ -n "$ip" ] || { echo "usage: rdns <ip>"; return 1; }
  r=$(getent hosts "$ip" 2>/dev/null | awk '{print $2; exit}')
  [ -z "$r" ] && command -v dig  >/dev/null 2>&1 && r=$(dig +short -x "$ip" 2>/dev/null | head -1 | sed 's/\.$//')
  [ -z "$r" ] && command -v host >/dev/null 2>&1 && r=$(host "$ip" 2>/dev/null | awk '/name pointer/{print $NF}' | head -1 | sed 's/\.$//')
  echo "${r:-—}"
}
# tags: connectivity test ping traceroute route port reachable dns resolve
# Test the network path to a host: DNS, which route/interface, ping, opt. port.
# Usage: reach <host> [port]
reach() {
  local h="$1" p="$2" ip tgt; [ -n "$h" ] || { echo "usage: reach <host> [port]"; return 1; }
  echo "── reach $h ──"
  ip=$(getent hosts "$h" 2>/dev/null | awk '{print $1; exit}')
  [ -z "$ip" ] && command -v dig >/dev/null 2>&1 && ip=$(dig +short "$h" 2>/dev/null | tail -1)
  echo "resolves:   ${ip:-FAILED (DNS)}"
  tgt="${ip:-$h}"
  if command -v ip >/dev/null 2>&1; then echo "route:      $(ip route get "$tgt" 2>/dev/null | head -1 | sed 's/  */ /g')"
  else echo "route:      $(route -n get "$tgt" 2>/dev/null | awk '/interface:|gateway:/{printf $2" "}')"; fi
  if ping -c2 -W1 "$tgt" >/dev/null 2>&1 || ping -c2 -t2 "$tgt" >/dev/null 2>&1; then echo "ping:       ok"; else echo "ping:       no reply"; fi
  if [ -n "$p" ]; then
    if nc -z -w2 "$tgt" "$p" 2>/dev/null || nc -z -G2 "$tgt" "$p" 2>/dev/null; then echo "port $p:  open"; else echo "port $p:  closed/filtered"; fi
  fi
}
host-add() {   # host-add <ip> <name> — add (or replace) an /etc/hosts entry
  local ip="$1" name="$2" tmp
  { [ -n "$ip" ] && [ -n "$name" ]; } || { echo "usage: host-add <ip> <name>"; return 1; }
  tmp=$(mktemp)
  grep -vE "[[:space:]]$name(\$|[[:space:]])" /etc/hosts > "$tmp" 2>/dev/null
  printf '%s\t%s\n' "$ip" "$name" >> "$tmp"
  sudo cp "$tmp" /etc/hosts && rm -f "$tmp" && echo "hosts: $ip -> $name"
}
host-del() {   # host-del <name> — remove an /etc/hosts entry
  local name="$1" tmp; [ -n "$name" ] || { echo "usage: host-del <name>"; return 1; }
  tmp=$(mktemp)
  grep -vE "[[:space:]]$name(\$|[[:space:]])" /etc/hosts > "$tmp"
  sudo cp "$tmp" /etc/hosts && rm -f "$tmp" && echo "removed $name"
}
# Open a website that lives on a remote SSH host's port, locally in your browser.
# Forwards your localhost:<port> to the host's own localhost:<port> over SSH, and
# (optionally) adds a pretty /etc/hosts name pointing at 127.0.0.1.
# Usage: ssh-web <user@host> [port] [hostname]
#   ssh-web me@server 8180 mysite.local   ->  http://mysite.local:8180
ssh-web() {
  local target="$1" port="${2:-8180}" name="$3"
  [ -n "$target" ] || { echo "usage: ssh-web <user@host> [port] [hostname]"; return 1; }
  [ -n "$name" ] && host-add 127.0.0.1 "$name"
  echo "tunnel: localhost:${port} -> $target (its localhost:${port}).  Ctrl-C to stop."
  echo "open:   http://${name:-localhost}:${port}"
  # braces are required: in zsh, $port:localhost would parse :l as a modifier
  ssh -N -L "127.0.0.1:${port}:localhost:${port}" "$target"
}
