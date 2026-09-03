#!/usr/bin/env bash
#
# adapt.sh — make these Ubuntu/macOS dotfiles work on Omarchy (Arch + Hyprland).
#
# Idempotent. Safe to re-run. Non-destructive by default: it backs up before it
# edits and gates every opinionated / repo-modifying step behind a flag.
#
# Always runs (all guarded, all no-ops when not applicable):
#   - patch ~/.bashrc to source ~/.bash_aliases (Omarchy doesn't; Ubuntu does)
#   - install + enable the Omarchy shell plugins in OMARCHY_PLUGINS (Omarchy only)
#
# Background + full task list: ../intent.md
# Plugin / tooling recommendations: ./PLUGINS.md
#
# Usage:
#   ./omarchy/adapt.sh [options]
#
# Options:
#   -n, --dry-run        print what would happen, change nothing
#   -y, --yes            don't prompt, assume yes
#       --stow           (re)stow the portable packages via GNU Stow
#       --unstow-fzf     remove the macOS fzf stub symlinks (Omarchy wires fzf itself)
#       --install        pacman/yay-install missing baseline CLI tools
#       --with-zsh       also set up zsh (install, fix brew guard, bootstrap oh-my-zsh)
#       --fix-git-editor rewrite git/.gitconfig core.editor vim -> nvim (edits the repo)
#       --git-signers    generate ~/.config/git/allowed_signers from the ssh pubkey
#       --all            --stow --unstow-fzf --install --git-signers (not the repo-editing ones)
#   -h, --help           this help
#
set -euo pipefail

# ---------------------------------------------------------------------------
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKER="# >>> dotfiles/omarchy: source ~/.bash_aliases >>>"
TS="$(date +%Y%m%d-%H%M%S)"
DRY=0; YES=0
DO_STOW=0; DO_UNSTOW_FZF=0; DO_INSTALL=0; DO_ZSH=0; DO_GIT_EDITOR=0; DO_GIT_SIGNERS=0

c_info(){ printf '\033[36m::\033[0m %s\n' "$*"; }
c_ok(){   printf '\033[32m ok\033[0m %s\n' "$*"; }
c_skip(){ printf '\033[33m --\033[0m %s\n' "$*"; }
c_warn(){ printf '\033[31m!!\033[0m %s\n' "$*" >&2; }
run(){ if (( DRY )); then printf '\033[90m  would run:\033[0m %s\n' "$*"; else eval "$*"; fi; }
ask(){ (( YES )) && return 0; read -rp "$1 [y/N] " a; [[ ${a,,} == y* ]]; }

# ---------------------------------------------------------------------------
parse_args(){
  while (( $# )); do
    case "$1" in
      -n|--dry-run) DRY=1 ;;
      -y|--yes) YES=1 ;;
      --stow) DO_STOW=1 ;;
      --unstow-fzf) DO_UNSTOW_FZF=1 ;;
      --install) DO_INSTALL=1 ;;
      --with-zsh) DO_ZSH=1 ;;
      --fix-git-editor) DO_GIT_EDITOR=1 ;;
      --git-signers) DO_GIT_SIGNERS=1 ;;
      --all) DO_STOW=1; DO_UNSTOW_FZF=1; DO_INSTALL=1; DO_GIT_SIGNERS=1 ;;
      -h|--help) awk 'NR>2 && !/^#/{exit} NR>2{sub(/^# ?/,"");print}' "${BASH_SOURCE[0]}"; exit 0 ;;
      *) c_warn "unknown option: $1"; exit 2 ;;
    esac
    shift
  done
  return 0
}

preflight(){
  [[ -r /etc/os-release ]] && . /etc/os-release
  case " ${ID:-} ${ID_LIKE:-} " in
    *" arch "*|*" omarchy "*) : ;;
    *) c_warn "not Arch/Omarchy (ID=${ID:-?}) — proceeding anyway" ;;
  esac
  [[ -d /usr/share/omarchy ]] || c_warn "no /usr/share/omarchy — is this Omarchy?"
  command -v stow >/dev/null || c_warn "GNU stow not installed (needed for --stow)"
  c_info "dotfiles repo: $DOTFILES"
  (( DRY )) && c_info "DRY RUN — nothing will change"
  return 0
}

# --- 1. always: make ~/.bashrc load ~/.bash_aliases -------------------------
# Omarchy's ~/.bashrc (unlike Ubuntu's) never sources ~/.bash_aliases, so cr/ll/
# gs/... never load. Append a guarded block to the user section, sourced LAST so
# personal aliases deliberately win over Omarchy defaults (e.g. g -> grep).
fix_bashrc(){
  local rc="$HOME/.bashrc"
  if [[ ! -f $rc ]]; then c_warn "no $rc — skipping"; return; fi
  if grep -qF "$MARKER" "$rc"; then c_ok "~/.bashrc already loads ~/.bash_aliases"; return; fi
  c_info "patching ~/.bashrc to source ~/.bash_aliases"
  if (( DRY )); then c_skip "would append guarded block to $rc"; return; fi
  cp -a "$rc" "$rc.bak-$TS"
  cat >> "$rc" <<EOF

$MARKER
# Ubuntu's stock bashrc auto-sourced ~/.bash_aliases; Omarchy's does not.
# Sourced last on purpose: personal aliases override Omarchy defaults.
[ -f "\$HOME/.bash_aliases" ] && . "\$HOME/.bash_aliases"
# Do NOT source ~/.fzf.bash — macOS/Homebrew stub; Omarchy wires fzf from /usr/share/fzf/.
# <<< dotfiles/omarchy <<<
EOF
  c_ok "patched (backup: $rc.bak-$TS)"
}

# --- 2. --stow: restow the portable packages ------------------------------
# sway/ is intentionally excluded (Omarchy owns Hyprland). fzf/ excluded too
# (see --unstow-fzf). .config here only carries sway, so it's skipped as well.
STOW_PKGS=(bash git tmux vim)
stow_pkgs(){
  command -v stow >/dev/null || { c_warn "stow missing — run with --install first"; return; }
  (( DO_ZSH )) && STOW_PKGS+=(zsh) || true
  c_info "stow dry-run (conflict check)"
  local p out
  for p in "${STOW_PKGS[@]}"; do
    [[ -d $DOTFILES/$p ]] || { c_skip "no package: $p"; continue; }
    # stow -n always prints "WARNING: in simulation mode" — that's not a conflict.
    out=$(stow -n -d "$DOTFILES" -t "$HOME" "$p" 2>&1 | grep -v 'WARNING: in simulation mode' || true)
    if [[ -n $out ]]; then
      c_warn "conflicts in '$p':"; sed 's/^/    /' <<<"$out"
      ask "  adopt/restow '$p' anyway?" || { c_skip "$p"; continue; }
    fi
    run "stow --restow -d '$DOTFILES' -t '$HOME' '$p'"
    c_ok "stowed $p"
  done
  c_warn "note: ~/.bashrc is Omarchy-owned and NOT stowed — step 1 patches it in place"
}

# --- 3. --unstow-fzf: drop the macOS fzf stub ---------------------------------
unstow_fzf(){
  local f
  for f in "$HOME/.fzf.bash" "$HOME/.fzf.zsh"; do
    if [[ -L $f ]]; then run "rm -v '$f'"; c_ok "removed stub $f";
    else c_skip "no stub $f"; fi
  done
  command -v stow >/dev/null && [[ -d $DOTFILES/fzf ]] && \
    run "stow -D -d '$DOTFILES' -t '$HOME' fzf" || true
}

# --- 3b. always (Omarchy only): install + enable shell plugins -------------
# Quickshell bar/panel/service plugins, given as git URLs. The whole step is a
# no-op when the `omarchy` CLI is absent (Ubuntu, plain Arch), so this list is
# safe to keep in the shared repo. `omarchy plugin add` clones to a temp dir,
# runs omarchy-plugin-validate, refuses symlinks / reserved ids / duplicates,
# then enables. Re-running on an already-installed plugin just no-ops with a
# message — we don't treat that as fatal.
#
# ⚠️  Plugins run as unsandboxed code inside the long-lived omarchy-shell
#    process. Only list repos you have reviewed and trust. See PLUGINS.md.
OMARCHY_PLUGINS=(
  # portwatch — bar widget that watches listening ports. Repo URL not yet
  # known; fill it in once confirmed (see PLUGINS.md "Omarchy shell plugins").
  # "https://github.com/OWNER/omarchy-portwatch.git"
)
install_omarchy_plugins(){
  command -v omarchy >/dev/null 2>&1 || { c_skip "no omarchy CLI — skipping shell plugins"; return 0; }
  (( ${#OMARCHY_PLUGINS[@]} )) || { c_skip "OMARCHY_PLUGINS empty — nothing to install"; return 0; }
  local url id installed
  installed=$(omarchy plugin list 2>/dev/null || true)
  for url in "${OMARCHY_PLUGINS[@]}"; do
    [[ -n $url && $url != \#* ]] || continue
    id="${url##*/}"; id="${id%.git}"
    if grep -qiE "(^|[^[:alnum:]])${id}([^[:alnum:]]|$)" <<<"$installed"; then
      c_ok "omarchy plugin looks installed: $id"; continue
    fi
    c_info "omarchy plugin add $url --enable --yes"
    if (( DRY )); then
      printf '\033[90m  would run:\033[0m omarchy plugin add %q --enable --yes\n' "$url"
    else
      omarchy plugin add "$url" --enable --yes || c_skip "add skipped (already present or failed): $url"
    fi
  done
  return 0
}

# --- 4. --install: baseline CLI tools --------------------------------------
# Most are already in Omarchy. zsh/vim only if you opt in.
BASELINE=(git curl jq tmux ripgrep fd bat eza zoxide fzf stow neovim mise)
# pkg name -> binary name where they differ
declare -A BIN=( [neovim]=nvim [ripgrep]=rg [fd]=fd )
install_tools(){
  local missing=() t bin
  for t in "${BASELINE[@]}"; do
    bin="${BIN[$t]:-$t}"
    command -v "$bin" >/dev/null 2>&1 || missing+=("$t")
  done
  (( DO_ZSH )) && ! command -v zsh >/dev/null && missing+=(zsh)
  if (( ${#missing[@]} == 0 )); then c_ok "baseline tools present"; return; fi
  c_info "missing: ${missing[*]}"
  if command -v yay >/dev/null; then run "yay -S --needed --noconfirm ${missing[*]}"
  else run "sudo pacman -S --needed --noconfirm ${missing[*]}"; fi
}

# --- 5. --with-zsh: zsh setup -------------------------------------------------
setup_zsh(){
  command -v zsh >/dev/null || { c_warn "zsh not installed — run with --install --with-zsh"; return; }
  # 5a. brew guard: .zprofile hard-codes macOS Homebrew and errors on Arch
  local zp="$DOTFILES/zsh/.zprofile"
  if [[ -f $zp ]] && grep -q '/opt/homebrew/bin/brew shellenv' "$zp" && ! grep -q 'command -v brew' "$zp"; then
    c_info "guarding Homebrew line in zsh/.zprofile"
    if (( ! DRY )); then
      cp -a "$zp" "$zp.bak-$TS"
      printf '\n# guard: brew only exists on macOS\n[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"\n' > "$zp.new"
      grep -v 'brew shellenv' "$zp" > "$zp.tmp" && cat "$zp.tmp" "$zp.new" > "$zp" && rm -f "$zp.tmp" "$zp.new"
    fi
    c_ok "guarded (backup: $zp.bak-$TS)"
  fi
  # 5b. oh-my-zsh dir in the repo is empty — bootstrap it + the custom plugins
  local omz="$DOTFILES/zsh/.oh-my-zsh"
  if [[ ! -e $omz/oh-my-zsh.sh ]]; then
    c_info "bootstrapping oh-my-zsh into repo (zsh/.oh-my-zsh)"
    run "git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git '$omz'"
    run "git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions '$omz/custom/plugins/zsh-autosuggestions'"
    run "git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting '$omz/custom/plugins/zsh-syntax-highlighting'"
    c_warn "add 'zsh-syntax-highlighting' to plugins=() in zsh/.zshrc (must be last)"
  else c_ok "oh-my-zsh already present"; fi
  # 5c. stale macOS zcompdump
  local dump; dump=$(find "$DOTFILES/zsh" -maxdepth 1 -name '.zcompdump-*' 2>/dev/null || true)
  [[ -n $dump ]] && { c_info "removing stale macOS zcompdump"; run "rm -v $dump"; }
  return 0
}

# --- 6. --fix-git-editor: vim -> nvim in the tracked gitconfig --------------
fix_git_editor(){
  local gc="$DOTFILES/git/.gitconfig"
  command -v nvim >/dev/null || { c_warn "nvim not installed"; return; }
  grep -q 'editor = vim' "$gc" || { c_ok "git core.editor not 'vim'"; return; }
  c_info "git/.gitconfig: core.editor vim -> nvim  (this edits the tracked repo)"
  ask "proceed?" || { c_skip "git editor"; return; }
  if (( ! DRY )); then cp -a "$gc" "$gc.bak-$TS"; sed -i 's/editor = vim/editor = nvim/' "$gc"; fi
  c_ok "done (commit the change yourself)"
}

# --- 7. --git-signers: allowed_signers from ssh pubkey ---------------------
# gitconfig sets commit.gpgsign=true + gpg.format=ssh but the allowedSignersFile
# is not in the repo, so signature verification is broken until it exists.
git_signers(){
  local pub="$HOME/.ssh/id_ed25519.pub" out="$HOME/.config/git/allowed_signers"
  [[ -f $pub ]] || { c_warn "no $pub — generate a key first"; return; }
  [[ -f $out ]] && { c_ok "allowed_signers already exists"; return; }
  local email; email=$(git config --file "$DOTFILES/git/.gitconfig" user.email || echo "")
  c_info "writing $out"
  if (( ! DRY )); then
    mkdir -p "$(dirname "$out")"
    printf '%s %s\n' "${email:-*}" "$(cat "$pub")" > "$out"
  fi
  c_ok "created (consider tracking it under .config/ in the repo)"
}

# ---------------------------------------------------------------------------
main(){
  parse_args "$@"
  preflight
  fix_bashrc
  install_omarchy_plugins
  if (( DO_INSTALL ));     then install_tools;   fi
  if (( DO_STOW ));        then stow_pkgs;       fi
  if (( DO_UNSTOW_FZF ));  then unstow_fzf;      fi
  if (( DO_ZSH ));         then setup_zsh;       fi
  if (( DO_GIT_EDITOR ));  then fix_git_editor;  fi
  if (( DO_GIT_SIGNERS )); then git_signers;     fi
  echo
  c_ok "done. Open a new terminal or: source ~/.bashrc"
  c_info "see omarchy/PLUGINS.md for recommended shell/tmux/nvim plugins"
}
main "$@"
