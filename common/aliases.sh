# Cross-platform aliases — sourced on every machine.
# Every line is commented so you can see what it actually does.
# Aliases that need an argument just prefix the command — type the rest after it,
# e.g.  gsw my-branch   ->   git switch my-branch

# ── cmdbook itself ──────────────────────────────────────────────────────────
# pull the latest cmdbook and reload aliases into THIS shell (no new shell needed)
cmd-update() {
  local d="${CMDBOOK_DIR:-$HOME/cmdbook}"
  git -C "$d" pull && . "$d/load.sh" && echo "cmdbook updated + reloaded ✓"
}
alias cmd-edit='${EDITOR:-nano} "${CMDBOOK_DIR:-$HOME/cmdbook}"'   # open the repo to add aliases

# Browse the book by category (the "# ── ... ──" section headers).
#   cmdbook                     list every platform and its categories
#   cmdbook ubuntu              list categories for one platform
#   cmdbook ubuntu network      show the commands in matching categories
cmdbook() {
  local dir="${CMDBOOK_DIR:-$HOME/cmdbook}" plat="$1" filter="$2" f p
  if [ -z "$plat" ]; then
    echo "usage: cmdbook <platform> [category]   e.g. cmdbook ubuntu network"
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
  awk -v want="$(printf %s "$filter" | tr 'A-Z' 'a-z')" '
    function flush() {
      if ((show || hit) && hdr != "") { printf "\n%s\n", hdr; for (i=1;i<=n;i++) print body[i] }
      n=0; show=0; hit=0
    }
    /^# ──/ { flush(); hdr=substr($0,3); show=(index(tolower($0),want)>0); next }
    { if (index(tolower($0),want)>0) hit=1                    # match in header OR any command
      if (/^alias / || /^[A-Za-z0-9_-]+\(\)/ || /^# /) body[++n]=$0 }
    END { flush() }
  ' "$f"
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
