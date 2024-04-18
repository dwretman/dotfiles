[user]
	signingkey = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdetvJ42i6+4It34Wvuj9rdYDAvW0B4NvtYOZZm367/

[gpg]
	format = ssh
[gpg "ssh"]
	program = /opt/1Password/op-ssh-sign
[commit]
	gpgsign = true
