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
   sudo apt install zsh starship zoxide fzf neovim ripgrep
   chsh -s /usr/bin/zsh
   ```

   atuin: Debian's package (18.6) is too old for `config/atuin/config.toml`
   (`daemon-fuzzy` search and daemon `autostart`). Install the release binary
   into `~/.atuin/bin` instead, which `zshrc` puts on `PATH`. Avoid atuin's
   `curl | sh` installer: it appends to `~/.zshrc`, which is a symlink into
   this repo. Install or update (set `V` to the latest release):
   ```sh
   V=18.23.0; T=atuin-x86_64-unknown-linux-gnu.tar.gz
   cd "$(mktemp -d)"
   curl -fLO https://github.com/atuinsh/atuin/releases/download/v$V/$T
   curl -fLO https://github.com/atuinsh/atuin/releases/download/v$V/$T.sha256
   sha256sum -c $T.sha256 && tar -xzf $T
   mkdir -p ~/.atuin/bin && install -m 755 */atuin ~/.atuin/bin/atuin
   printf '%s\n' 'case ":${PATH}:" in *:"$HOME/.atuin/bin":*) ;; *) export PATH="$HOME/.atuin/bin:$PATH" ;; esac' > ~/.atuin/bin/env
   ```

## Neovim

`config/nvim` uses helix keymaps (`lua/helix.lua`, selection-first, emulated
with visual mode; `v` enters select mode; multiple selections through
multicursor.nvim) and Zed's One Dark theme
(`colors/zed-onedark.lua`). It works with Debian 13's neovim (0.10). Plugins
are installed by lazy.nvim on first start, and treesitter parsers are compiled
with `gcc`. Language servers are started when installed (`rust-analyzer`,
`ruff`, `pyright` or `pylsp`, `clangd`, `lua-language-server`,
`bash-language-server`).

## Desktop (sway)

The sway desktop configs (sway, waybar, foot, swaylock) are under `config/`.
Packages, extra install steps (Nerd Font, monitor layout) and an explanation
of every change are in [config/sway/SETUP.md](config/sway/SETUP.md).

## Files outside ~

rcm does not track files outside the home directory. To keep track of such
files even if they are manually manged, I have added them under `tag-global`.
