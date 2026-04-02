#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${HOME}/.claude"

# Files/dirs in the repo root to never symlink
SKIP=(".git" ".gitignore" "README.md" "install.sh")

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
echo "Done."
