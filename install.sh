#!/bin/sh
# Install one look into your home folder: ./install.sh seven|aye3 [--dry-run]
#
# Copies LOOK/.config and LOOK/.local into $HOME. Every file it would replace
# is first copied to ~/.local/state/flickos-dotfiles/backup-DATE/, with the
# same path, so you can put it back. Then it sets the GTK and icon themes
# with gsettings. Nothing else is changed.
set -e

usage() {
    echo "Usage: $0 seven|aye3 [--dry-run]" >&2
    exit 2
}

look=
dry=
for arg; do
    case $arg in
        seven|aye3) look=$arg ;;
        --dry-run) dry=1 ;;
        *) usage ;;
    esac
done
[ -n "$look" ] || usage

here=$(cd "$(dirname "$0")" && pwd)
src=$here/$look
backup=$HOME/.local/state/flickos-dotfiles/backup-$(date +%Y%m%d-%H%M%S)

case $look in
    seven) gtk=Arc; scheme=prefer-light ;;
    aye3) gtk=Arc-Dark; scheme=prefer-dark ;;
esac

run() {
    if [ -n "$dry" ]; then echo "  $*"; else "$@"; fi
}

echo "Installing $look into $HOME"
cd "$src"
find .config .local -type f | sort | while read -r file; do
    target=$HOME/${file#./}
    if [ -e "$target" ] && ! cmp -s "$file" "$target"; then
        echo "backup  ~/${file#./}"
        run mkdir -p "$backup/$(dirname "$file")"
        run cp -p "$target" "$backup/$file"
    fi
    echo "install ~/${file#./}"
    run mkdir -p "$(dirname "$target")"
    run cp "$file" "$target"
done

if command -v gsettings >/dev/null; then
    echo "GTK theme $gtk, icons Numix, $scheme"
    run gsettings set org.gnome.desktop.interface gtk-theme "$gtk"
    run gsettings set org.gnome.desktop.interface icon-theme Numix
    run gsettings set org.gnome.desktop.interface color-scheme "$scheme"
else
    echo "No gsettings: set the GTK theme to $gtk and the icons to Numix yourself (nwg-look)."
fi

[ -d "$backup" ] && echo "Your old files are in $backup"
echo "Done. Log out and back in to labwc (or run: labwc --reconfigure, then restart waybar and mako)."
