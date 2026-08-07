#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${HOME}/.claude"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

# Files/dirs in the repo root to never symlink into ~/.claude
SKIP=(".git" ".gitignore" "README.md" "install.sh" "zshrc" "gitconfig" "aliases" ".DS_Store")

is_skipped() {
  local name="$1"
  for skip in "${SKIP[@]}"; do
    [[ "$name" == "$skip" ]] && return 0
  done
  return 1
}

link() {
  local src="$1"
  local dest="$2"

  if [[ -L "$dest" ]]; then
    echo "  skip   $dest (already a symlink)"
    return
  fi

  if [[ -e "$dest" ]]; then
    local backup="${dest}.bak"
    (( DRY_RUN )) && echo "  would back up $dest -> $backup" || { echo "  backup $dest -> $backup"; mv "$dest" "$backup"; }
  fi

  (( DRY_RUN )) && echo "  would link $dest -> $src" || { ln -s "$src" "$dest"; echo "  linked $dest -> $src"; }
}

install_zsh_plugins() {
  if command -v brew &>/dev/null; then
    for pkg in zsh-autosuggestions zsh-syntax-highlighting; do
      brew list "$pkg" &>/dev/null && continue
      (( DRY_RUN )) && echo "  would install $pkg via brew" || { echo "  installing $pkg via brew"; brew install "$pkg"; }
    done
  elif command -v apt-get &>/dev/null; then
    for pkg in zsh-autosuggestions zsh-syntax-highlighting; do
      dpkg -s "$pkg" &>/dev/null && continue
      (( DRY_RUN )) && echo "  would install $pkg via apt" || { echo "  installing $pkg via apt"; sudo apt-get install -y "$pkg"; }
    done
  else
    echo "  skip zsh-autosuggestions/zsh-syntax-highlighting (no brew or apt-get found)"
  fi
}

(( DRY_RUN )) && echo "-- dry run: no changes will be made --" && echo ""
(( DRY_RUN )) || mkdir -p "$TARGET"

echo "Linking dotfiles into $TARGET"
echo ""

for src in "$REPO"/* "$REPO"/.[^.]*; do
  name="$(basename "$src")"
  is_skipped "$name" && continue
  [[ -e "$src" ]] || continue  # skip globs that didn't expand
  link "$src" "$TARGET/$name"
done

echo ""
echo "Linking shell config into $HOME"
link "$REPO/zshrc" "$HOME/.zshrc"
link "$REPO/gitconfig" "$HOME/.gitconfig"
link "$REPO/aliases" "$HOME/.aliases"

echo ""
echo "Checking zsh plugins"
install_zsh_plugins

echo ""
echo "Done."
