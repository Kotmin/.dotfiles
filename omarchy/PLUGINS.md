# PLUGINS.md — preferred plugins & tooling on Omarchy

Companion to `adapt.sh` / `../intent.md`. What to layer on top once the dotfiles
load. Nothing here is installed automatically — `adapt.sh` only handles the
baseline. Pick what you want.

Legend: **[repo]** = official Arch repo (`pacman -S`) · **[aur]** = AUR (`yay -S`) ·
**[omarchy]** = already shipped/wired by Omarchy.

---

## Shell — bash (the Omarchy default)

Bash has no plugin manager; "plugins" = small tools you `eval`/`source` from
`~/.bashrc` (after the `>>> dotfiles/omarchy >>>` block).

| Tool | Pkg | Why |
|------|-----|-----|
| starship | **[omarchy]** | prompt; already `eval`'d in `default/bash/init`. Customise `~/.config/starship.toml`. Don't also run p10k in bash. |
| fzf | **[omarchy]** | `Ctrl-R` history, `Ctrl-T` files, `Alt-C` cd. Key-bindings wired from `/usr/share/fzf/`. |
| zoxide | **[omarchy]** | `z <frag>` / `zi`. Already `eval`'d. Omarchy also aliases `cd`→`zd`. |
| bash-completion | **[omarchy]** | sourced in `default/bash/shell`. |
| **atuin** | **[repo]** | SQLite shell history: fuzzy search, per-dir, stats, optional E2E sync. `atuin import auto && atuin init bash` → add `eval "$(atuin init bash)"`. Rebinds `Ctrl-R` (keep or `--disable-up-arrow`). |
| **ble.sh** | **[aur]** `blesh-git` | the zsh-autosuggestions / syntax-highlighting experience for bash. `source /usr/share/blesh/ble.sh` first line of `.bashrc`, `[[ ${BLE_VERSION-} ]] && ble-attach` last line. Slight startup cost. |
| fzf-tab-completion | **[aur]** | fzf UI for `<Tab>` completion in bash. Optional; overlaps ble.sh. |

Modern CLI replacements (muscle-memory upgrades; Omarchy already has `eza`,
`bat`, `fd`, `ripgrep`, `fzf`, `zoxide`):

| Tool | Pkg | Replaces |
|------|-----|----------|
| duf | **[repo]** | `df` |
| dust | **[repo]** | `du` |
| procs | **[repo]** | `ps` |
| bottom (`btm`) | **[repo]** | `top`/`htop` |
| delta (`git-delta`) | **[repo]** | git pager/diff — pairs with `.gitconfig` |
| lazygit | **[repo]** | git TUI |
| jq / yq | **[repo]** | JSON / YAML |
| tldr (`tealdeer`) | **[repo]** | man-page examples |

`git-delta` wiring for `git/.gitconfig`:

```ini
[core]
    pager = delta
[interactive]
    diffFilter = delta --color-only
[delta]
    navigate = true
    line-numbers = true
[merge]
    conflictStyle = zdiff3
```

---

## Shell — zsh (only if you keep it; see intent.md §3.3)

`zsh` is **not installed** here and the repo's `.oh-my-zsh` dir is **empty**.
`adapt.sh --with-zsh` installs zsh, guards the macOS Homebrew line in
`.zprofile`, and clones oh-my-zsh + the two plugins below.

**oh-my-zsh `plugins=(...)`** (edit `zsh/.zshrc`):

| Plugin | Source | Note |
|--------|--------|------|
| git | bundled | aliases (`gst`, `gco`, …) |
| zsh-autosuggestions | `zsh-users/zsh-autosuggestions` | fish-style history ghost text |
| zsh-syntax-highlighting | `zsh-users/zsh-syntax-highlighting` | **must be listed last** |
| fzf | bundled | key-bindings + completion |
| fzf-tab | `Aloxaf/fzf-tab` | fzf UI for tab-completion (load after compinit, before syntax-highlighting) |
| you-should-use | `MichaelAquilina/zsh-you-should-use` | nags when you skip an alias |
| zoxide | via `eval "$(zoxide init zsh)"` | not an omz plugin |

**Prompt:** the repo carries a full `.p10k.zsh` (Powerlevel10k). Either keep p10k
for zsh, or standardise on **starship** across bash+zsh and drop p10k +
`ZSH_THEME`. Don't run both.

**Faster alternative to oh-my-zsh:** `sheldon` **[repo]** or `zinit` **[aur]** —
plugin managers with lazy-loading; ~5–10× faster startup. Bigger migration.

---

## tmux

Current `tmux/.tmux.conf` is plugin-free and uses **hardcoded 256-colour**
styling (won't follow Omarchy themes). Add **TPM** and a handful of plugins:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Append to `.tmux.conf` (keep the manual config above it):

```tmux
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-yank'          # y in copy-mode -> system clipboard
set -g @plugin 'christoomey/vim-tmux-navigator'  # C-h/j/k/l across tmux+nvim splits
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'     # auto save/restore
set -g @plugin 'omerxx/catppuccin-tmux'          # or 'catppuccin/tmux' — theme-aware status

set -g @continuum-restore 'on'
run '~/.tmux/plugins/tpm/tpm'                     # MUST be the last line
```

Then `prefix + I` to install.

- **tmux-yank** matters: current copy-mode `y` only fills the tmux buffer, not
  the Wayland clipboard. tmux-yank uses `wl-copy` automatically.
- **vim-tmux-navigator** needs the matching nvim plugin (below) to be seamless.
- Drop the hardcoded `status-style`/`colour236` lines if you adopt a theme plugin.

---

## Neovim

`vim` isn't installed; `nvim` is, and it does **not** read `~/.vimrc`. Options:

**Minimal parity** — `~/.config/nvim/init.lua`:

```lua
vim.cmd('source ~/.vimrc')   -- reuse the existing vimscript settings
```

Track it as a `nvim/` stow package.

**Full setup** — pick a starter and add `nvim/` to the repo:

| Starter | Pkg/repo | For |
|---------|----------|-----|
| kickstart.nvim | `nvim-lua/kickstart.nvim` | single-file, readable, you own it |
| LazyVim | `LazyVim/starter` | batteries-included distro |
| AstroNvim | `AstroNvim/template` | heavier, GUI-ish |

Core plugins worth having regardless of starter (all via `lazy.nvim`):

- `nvim-treesitter/nvim-treesitter` — syntax/indent
- `neovim/nvim-lspconfig` + `williamboman/mason.nvim` — LSP install & config
- `nvim-telescope/telescope.nvim` (+ `telescope-fzf-native`) — fuzzy everything
- `lewis6991/gitsigns.nvim` — gutter git + blame
- `christoomey/vim-tmux-navigator` — pairs with the tmux plugin
- `folke/which-key.nvim` — keybinding discovery
- `stevearc/oil.nvim` or `nvim-neo-tree/neo-tree.nvim` — file explorer
- `hrsh7th/nvim-cmp` or `saghen/blink.cmp` — completion
- theme: `catppuccin/nvim`, `folke/tokyonight.nvim` — match your Omarchy theme

Language servers via mason (`:Mason`): `lua_ls`, `pyright`/`basedpyright`,
`ruff`, `bashls`, `yamlls`, `jsonls`, `dockerls`, `terraformls`, `gopls`.

---

## Omarchy shell plugins (Quickshell bar / panel / service)

Omarchy-specific — **not portable**. The bar, panels and overlays are one
long-running `omarchy-shell` (Quickshell) process; a plugin is just a git repo
with a `manifest.json` at its root. Docs:
<https://omarchy.org/manual/shell-plugins/> · browse:
<https://plugins.omarchy.org> · <https://omahub.dev>.

```bash
omarchy plugin add https://github.com/OWNER/REPO.git --enable --yes
omarchy plugin list                 # ids + enabled/disabled + first/third-party
omarchy plugin clone omarchy.clock  # fork a built-in widget to edit safely
omarchy plugin disable <id> ; omarchy plugin remove <id>
omarchy plugin update <id>
```

> ⚠️  Plugins run as **arbitrary, unsandboxed code** inside your long-lived
> `omarchy-shell`. `omarchy plugin add` validates the manifest, refuses
> symlinks / the reserved `omarchy.*` id namespace / duplicates — it does **not**
> read the code for you. Only add repos you have reviewed and trust.

### adapt.sh integration

`adapt.sh` has an `OMARCHY_PLUGINS=( … )` array near the top: git URLs it
installs + enables on every run, idempotently. The whole step is skipped when
the `omarchy` CLI is absent, so the list stays safe in the shared repo and is a
**no-op on Ubuntu / plain Arch**. Add a URL, re-run `./omarchy/adapt.sh`.

### Wanted

| Plugin | Status | Notes |
|--------|--------|-------|
| **portwatch** (bar widget: watch listening ports) | **URL TBD** | No plugin by this exact name found in the registry as of 2026-09. `techinpark/PortWatch` is a *macOS* menu-bar app and will not run here. Once the real repo is known, drop it into `OMARCHY_PLUGINS`. Linux CLI fallbacks if no widget turns up: `portmon`, `portview`, `portwatcher-tui` (see below). |

CLI port monitors (portable, `yay`/`cargo`, work on Ubuntu too):
`JNC4/portmon` · `Mapika/portview` · `mateusflorez/portwatcher-tui` ·
`mifwar/port-patrol`.

---

## Hyprland / Omarchy desktop

Omarchy **owns** `~/.config/hypr/`. Do not stow the repo's `.config/sway/`
(that's the old Ubuntu WM). User overrides:

- Put personal binds/rules in the Omarchy-sanctioned override files under
  `~/.config/hypr/` (see the `omarchy` docs / `omarchy-menu`). The old sway
  `Mod4 + 1..5` workspace binds already exist in Omarchy's Hyprland defaults.
- Hyprland plugins via `hyprpm` (`hyprexpo`, `hy3` tiling, `hyprscroller`):
  powerful but **can break on Hyprland updates** and Omarchy doesn't expect
  them — adopt only if you're happy to babysit `hyprpm update` after upgrades.
- Theming: use `omarchy-theme-*` / the theme menu rather than hand-editing
  colours, so tmux/nvim/bat/btop stay in sync.

---

## Runtime versions — mise

`mise` **[omarchy]** is already active in bash. Use it instead of nvm/pyenv/rbenv
and instead of the README's manual `curl | sh` installs for kubectl/terraform:

```sh
mise use -g node@lts python@3.12 go@latest
mise use -g kubectl terraform kubectl-krew
mise use -g usage        # completions backend
```

Project pins live in `.mise.toml` (there's already one in `~/Work`).
