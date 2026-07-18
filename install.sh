#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${HOME}/.claude"

# Files/dirs in the repo root to never symlink into ~/.claude
SKIP=(".git" ".gitignore" "README.md" "install.sh" "zshrc" ".DS_Store")

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
    echo "  backup $dest -> $backup"
    mv "$dest" "$backup"
  fi

  ln -s "$src" "$dest"
  echo "  linked $dest -> $src"
}

install_zsh_plugins() {
  if command -v brew &>/dev/null; then
    for pkg in zsh-autosuggestions zsh-syntax-highlighting; do
      brew list "$pkg" &>/dev/null || { echo "  installing $pkg via brew"; brew install "$pkg"; }
    done
  elif command -v apt-get &>/dev/null; then
    for pkg in zsh-autosuggestions zsh-syntax-highlighting; do
      dpkg -s "$pkg" &>/dev/null || { echo "  installing $pkg via apt"; sudo apt-get install -y "$pkg"; }
    done
  else
    echo "  skip zsh-autosuggestions/zsh-syntax-highlighting (no brew or apt-get found)"
  fi
}

mkdir -p "$TARGET"

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

echo ""
echo "Checking zsh plugins"
install_zsh_plugins

echo ""
echo "Done."
