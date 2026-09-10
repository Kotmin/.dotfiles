alias ll='ls -lah'
alias la='ls -A'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias gic='git clone'
alias gitrev='git diff @{1} @{0}'
alias python='python3'
alias g='grep'
alias cr='claude --dangerously-skip-permissions'
alias docke='docker events --filter type=container -- container=alpine --format "{{.Time}} {{.Actor.Attributes.name}} "'
alias docks='docker system df -v'
alias dockh='docker buildx history trace'

# Fall back to Neovim (LazyVim config) when no real vi/vim is installed.
if ! command -v vim >/dev/null 2>&1 && command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'
  command -v vi >/dev/null 2>&1 || alias vi='nvim'
fi
