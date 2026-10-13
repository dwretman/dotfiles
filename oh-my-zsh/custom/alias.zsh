picoterm(){
  picocom $1 \
    -b 115200 -e q --omap crlf \
    -s "ascii-xfr -s -n" \
    --receive-cmd "ascii-xfr -r -n" \
    --flow n
}

# Set surrent value of SSH_AUTH_SOCK, use to get ssh agent forwarding working
# in e.g. tmux after ssh reconnection 
fixssh() {
  eval $(tmux show-env -s |grep '^SSH_')
}

alias lg='lazygit'

# Git worktree add + cd: create branch <branch> in a new worktree at
# <path>/<branch> and cd into it. Named to sit beside oh-my-zsh's git plugin
# worktree aliases (gwt, gwta, gwtls, gwtmv, gwtrm).
gwtac() {
  if (( $# != 2 )); then
    echo "usage: gwtac <branch> <path>" >&2
    return 1
  fi
  local dir="${2%/}/$1"
  git worktree add -b "$1" "$dir" && cd "$dir"
}
