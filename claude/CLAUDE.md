## Git instructions

- Use conventional-commits
- Don't add Co-Authored-By lines
- Never commit to the main branch. Create a new branch or use checked out feature branch
- Always commit Cargo.lock file in a separate commit after code and config changes
- Always commit poetry.lock files in a separate commit after code and config changes


## GitLab instructions

- When accessing GitLab, use `command glab` since `glab` is aliased to use the 1password shell plugin


## Desktop setup (sway on Debian 13)

My desktop setup is documented in `~/.config/sway/SETUP.md`. Whenever you
change anything in the desktop setup (sway, waybar, input, displays, audio,
network/Bluetooth tools, autostart, installed desktop packages, etc.), update
`SETUP.md` in the same session so it stays accurate:

- Read `SETUP.md` before making changes, to follow the existing setup.
- Record what changed and why, add new packages to the install command, and
  list new config files in the Files section.
- Keep the "Replicating on a new machine" steps working.
- The config files are symlinks into my dotfiles repo `~/.dotfiles` (managed
  with rcm). Add new config files to the repo and link them with `rcup`, and
  commit changes there following the git instructions above.
