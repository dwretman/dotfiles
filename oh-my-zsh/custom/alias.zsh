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
