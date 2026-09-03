# intent.md — porting these dotfiles from Ubuntu/macOS to Omarchy (Arch)

Status: **living doc**. Captures what broke on this machine, what was patched
by hand, and what the adapt script should automate.

- **`omarchy/adapt.sh`** — the script. Idempotent; non-destructive by default;
  every opinionated step behind a flag. `omarchy/adapt.sh --help`.
- **`omarchy/PLUGINS.md`** — recommended bash/zsh/tmux/nvim/Hyprland plugins.

Machine: Arch Linux + [Omarchy](https://omarchy.org). Interactive shell: **bash**
(Omarchy is bash-first; `zsh` is not installed here). Dotfiles managed with GNU Stow.

---

## 0. Cross-distro compatibility contract

This repo must keep working on **Ubuntu** (and macOS, best-effort). Rules:

- **Shared stow packages stay portable.** `bash/`, `git/`, `tmux/`, `vim/`,
  `zsh/`, `fzf/` must not gain `pacman` / `omarchy` / `hyprland` / Arch-path
  assumptions. Anything OS-specific in them is written as a runtime guard
  (`command -v x`, `[[ -x /path ]]`), never a hard dependency.
- **All Omarchy/Arch-specific logic lives under `omarchy/`.** `adapt.sh` is the
  only file that may assume Arch, and even it *guards* each step: it warns (not
  aborts) when `ID` isn't arch/omarchy, and every Omarchy-only action is behind
  `command -v omarchy` / `command -v pacman` so running it elsewhere is a no-op.
- **Nothing in `omarchy/` is stowed.** It's tooling, not dotfiles.
- The `~/.bashrc` alias-loading patch mirrors what Ubuntu's stock `~/.bashrc`
  already does — it only adds Ubuntu-parity behaviour, nothing Arch-specific.
- `OMARCHY_PLUGINS` in `adapt.sh` is Omarchy-only by construction (skipped
  without the `omarchy` CLI), so listing plugins there is Ubuntu-safe.

Current known non-portable bits, all **pre-existing** and macOS-only (see §3.2,
§3.3): `fzf/.fzf.bash`, `fzf/.fzf.zsh`, `zsh/.zprofile` hard-code
`/opt/homebrew`. They fail silently rather than break a shell, but should be
guarded.

---

## 1. The immediate symptom

Personal shortcuts (`cr`, `ll`, `gs`, `gd`, `gl`, `gic`, `python`, docker aliases…)
did nothing in a fresh shell.

**Root cause:** those aliases live in `bash/.bash_aliases` (stowed to
`~/.bash_aliases`). Ubuntu's stock `~/.bashrc` sources `~/.bash_aliases`
automatically; **Omarchy's `~/.bashrc` does not.** Nothing was sourcing the file.

Secondary issue: `fzf/.fzf.bash` and `fzf/.fzf.zsh` are macOS/Homebrew stubs
(`/opt/homebrew/opt/fzf/bin`, `eval "$(fzf --bash)"`). Omarchy already wires fzf
completion + key-bindings from `/usr/share/fzf/` in
`/usr/share/omarchy/default/bash/init`, so the stub is redundant and pollutes
`PATH` with a non-existent dir.

---

## 2. What was patched on this machine (2026-09-03)

`~/.bashrc` (the real file Omarchy ships in `~`, **not** in this repo) got a
guarded block appended to its user section, between the markers:

```bash
# >>> dotfiles/omarchy: source ~/.bash_aliases >>>
[ -f "$HOME/.bash_aliases" ] && . "$HOME/.bash_aliases"
# <<< dotfiles/omarchy <<<
```

Sourced **last**, on purpose, so personal aliases override Omarchy defaults.
Decision taken: **`g` = `grep`** (personal) wins over Omarchy's `g` = `git`.
`git`, `gcm`, `gcam`, `gcad` etc. still cover git.

`omarchy/adapt.sh` now applies this same block idempotently (marker-guarded) —
re-running it is safe, and it backs up `~/.bashrc` before touching it. The edit
is still **not tracked by the repo** and would be lost if Omarchy resets
`~/.bashrc`; re-run `omarchy/adapt.sh` after any such reset.

Verified working: `cr`, `ll`, `la`, `gs`, `gd`, `gl`, `g`.

---

## 3. Work for the future script

### 3.1 Bash alias loading (durable, repo-managed)  — DONE

`~/.bashrc` is Omarchy-owned; Stow can't own it without clobbering Omarchy
updates. **Resolved:** `adapt.sh` idempotently appends the guarded source line to
`~/.bashrc`'s user section, marker-guarded (`# >>> dotfiles/omarchy ... >>>`) so
re-runs are safe, with a timestamped backup. Sources `~/.bash_aliases` **after**
`$OMARCHY_PATH/default/bash/rc` and does **not** source `~/.fzf.bash`.

Still open: nothing durable-in-repo — if Omarchy ever ships an official user
include dir for bash, switch to that. Re-run `adapt.sh` after an Omarchy
`~/.bashrc` reset.

### 3.2 fzf

- Stop stowing `fzf/.fzf.bash` / `.fzf.zsh` on Omarchy, **or** rewrite them to be
  OS-aware (only add the Homebrew path when it exists; prefer `/usr/share/fzf/`).
- Nothing else needed on Arch — `fzf` is a pacman package and Omarchy sets it up.

### 3.3 zsh (currently dead weight here)

`zsh` isn't installed. `zsh/`, `.oh-my-zsh` (submodule), `.p10k.zsh`,
`.zcompdump-Paweł's MacBook Pro-5.9`, `.zsh_sessions` are all inert. Decide:

- **Keep zsh as a portable option:** script should `pacman -S zsh`, then fix
  `zsh/.zprofile` — it hard-codes `eval "$(/opt/homebrew/bin/brew shellenv)"`
  (macOS only; errors on Arch). Make it conditional on the brew binary existing.
  Also `zsh/.zshrc` already sources `~/.bash_aliases` at the end (good) and
  `~/.fzf.zsh` (same Homebrew problem as 3.2).
- **Or drop zsh from the Omarchy profile entirely** and don't stow `zsh/`.
- Delete the stale macOS `.zcompdump-*` file regardless.

### 3.4 Editor / vim

- `vim` is not installed; `nvim` is. `vim/.vimrc` stows to `~/.vimrc`, which
  Neovim does not read by default.
- `git/.gitconfig` has `core.editor = vim`.
- Options: `pacman -S vim`; or point `core.editor` at `nvim` /
  `omarchy-launch-editor`; and/or add a minimal `~/.config/nvim/init.vim` that
  `source`s `~/.vimrc` for the settings that are still valid.

### 3.5 git config gaps (commit signing will fail as-is)

`git/.gitconfig` sets `commit.gpgsign = true` with `gpg.format = ssh` and:

- `user.signingkey = ~/.ssh/id_ed25519.pub` — script must ensure the key exists
  (keygen prompt) or signing blocks every commit.
- `gpg.ssh.allowedSignersFile = ~/.config/git/allowed_signers` — **this file is
  not in the repo.** Add `.config/git/allowed_signers` to the `.config` stow
  package (or generate it from the pubkey), else `git log --show-signature` and
  some hosts complain.
- `includeIf "gitdir:/Coding/"` and `gitdir:/Work/` use absolute-root paths and
  point at `~/.dotfiles/git/Coding/.gitconfig` / `git/Work/.gitconfig`, which
  don't exist in the repo. Fix the globs to `gitdir:~/Coding/` /
  `gitdir:~/Work/` and add the referenced files (or drop the includes).
- `core.editor = vim` — see 3.4.

### 3.6 Window manager: sway → Hyprland

`.config/sway/config` (a tiny Mod4 + workspace bindings file) targets **Sway**.
Omarchy runs **Hyprland** and owns `~/.config/hypr/`. It is currently **not**
stowed and should stay that way. If those bindings are still wanted, port them
into an Omarchy-sanctioned Hyprland override (per the `omarchy` skill / docs —
`~/.config/hypr/` user config files), not by stowing `sway/`.

### 3.7 Package install / bootstrap (README is Ubuntu-only)

`README.md`'s "Base command set" is all `apt` + manual `curl | sh` installs and
`sudo apt install sway waybar`. On Omarchy/Arch:

- Translate to `pacman` / `yay`; most tools (`git curl jq tmux docker eza zoxide
  fzf bat mise stow neovim`) are already present via Omarchy.
- Drop the manual docker-compose / kubectl / terraform curl blocks in favour of
  `pacman`/`yay` packages or `mise`.
- `cat ~/.ssh/id_ed25519.pub | clip` → `wl-copy` on Wayland.
- Keep a single cross-distro entrypoint: detect `pacman` vs `apt` vs `brew`.

### 3.8 Stow conflict handling

Running `for dir in */; do stow -t ~ "$dir"; done` on Omarchy will conflict on
Omarchy-provided files (`~/.bashrc`, possibly others). The script should
`stow -n` (dry-run) first, report conflicts, and either back up + adopt or skip
per-package. Never blindly overwrite Omarchy-managed files.

### 3.9 Misc cleanup

- `.claude/` stow package (CLAUDE.md, settings.json, skills) is **not** stowed;
  `~/.claude` is a real dir. Decide whether to merge.
- `git/.gitignore` (`.zsh_history`, `.viminfo`) is stowed to `~/.gitignore` but no
  `core.excludesFile` points at it — wire it up or move to
  `~/.config/git/ignore`.
- Delete `zsh/.zcompdump-Paweł's MacBook Pro-5.9` and `zsh/.zsh_sessions`.

### 3.10 Omarchy shell plugins  (`adapt.sh` + `omarchy/PLUGINS.md`)

Wired up: `adapt.sh` has `OMARCHY_PLUGINS=( git-url … )` — installed + enabled
every run via `omarchy plugin add … --enable --yes`, idempotent, skipped when
there's no `omarchy` CLI (so Ubuntu-safe, per §0).

- **portwatch** — wanted (bar widget: watch listening ports). **No repo URL
  yet** — no Omarchy plugin by that exact name is in the registry as of
  2026-09; `techinpark/PortWatch` is macOS-only. Action: confirm the repo, add
  its URL to `OMARCHY_PLUGINS`, re-run. Fallback if no widget exists: a portable
  CLI monitor (`portmon` / `portview`) as an `--install` extra.
- Plugin security: `omarchy plugin add` validates the manifest but does **not**
  vet the code — plugins run unsandboxed in `omarchy-shell`. Review before
  listing.

---

## 4. Omarchy-vs-personal alias conflicts (reference)

Personal `bash/.bash_aliases` is sourced last, so it wins. Known overlaps with
`/usr/share/omarchy/default/bash/aliases`:

| alias | Omarchy default | personal | resolution |
|-------|-----------------|----------|------------|
| `g`   | `git`           | `grep`   | personal wins (chosen) |
| `ll`  | *(none)*        | `ls -lah`| fine; `ls` is `eza`, `ll` → `eza -lh … -lah`, works |
| `la`  | *(none; has `lsa`)* | `ls -A` | fine |
| `python` | *(none)*     | `python3`| fine |

Non-conflicting personal aliases: `cr`, `gs`, `gd`, `gl`, `gic`, `gitrev`,
`docke`, `docks`, `dockh`.

---

## 5. Open decisions (need a human)

1. Keep zsh as a supported shell on Omarchy, or drop it? (3.3)
2. Install `vim`, or retarget everything to `nvim`? (3.4)
3. Port the sway keybindings into Hyprland, or abandon them? (3.6)
4. Merge the repo's `.claude/` into `~/.claude`? (3.9)
