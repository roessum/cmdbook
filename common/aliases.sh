# Cross-platform aliases — sourced on every machine.
# Every line is commented so you can see what it actually does.
# Aliases that need an argument just prefix the command — type the rest after it,
# e.g.  gsw my-branch   ->   git switch my-branch

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
