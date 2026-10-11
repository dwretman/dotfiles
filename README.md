# Dotfiles

These are my dotfiles for setting up a Linux account to my liking.

## Installation

1. Install the dotfiles utility [rcm](https://github.com/thoughtbot/rcm)
2. Clone this repo to `~/.dotfiles`
3. Run `rcup` from the cloned directory
4. Install applications configured and used by these dotfiles:
  - [zsh](https://www.zsh.org/)
  - [Oh My Zsh](https://ohmyz.sh/)
  - [alacritty](https://github.com/alacritty/alacritty)
  - [ripgrep](https://github.com/BurntSushi/ripgrep)
  - [zoxide](https://github.com/ajeetdsouza/zoxide)
  - [fzf](https://github.com/junegunn/fzf)
  - [atuin](https://github.com/atuinsh/atuin)
  - [starship](https://starship.rs/)
  - [1password](https://1password.com/)
  - [tlp](https://linrunner.de/tlp/index.html)

   On Debian 13, the shell tools used by `zshrc` are packaged (Oh My Zsh is
   installed with its own script, 1Password from its own apt repo):
   ```sh
   sudo apt install zsh starship zoxide fzf atuin neovim ripgrep
   chsh -s /usr/bin/zsh
   ```

## Desktop (sway)

The sway desktop configs (sway, waybar, foot, swaylock) are under `config/`.
Packages, extra install steps (Nerd Font, monitor layout) and an explanation
of every change are in [config/sway/SETUP.md](config/sway/SETUP.md).

## Files outside ~

rcm does not track files outside the home directory. To keep track of such
files even if they are manually manged, I have added them under `tag-global`.
