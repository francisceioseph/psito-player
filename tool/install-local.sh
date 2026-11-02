#!/bin/bash
# Compila o player e instala só para esta conta, sem pacote e sem sudo.
# Precisa da libmpv2 e da libsqlite3-0 no sistema.
# Uso: tool/install-local.sh [--uninstall]
set -e

cd "$(dirname "$0")/.."

ID=org.psito.player
DEST="$HOME/.local/lib/psito-player"
ENTRY="$HOME/.local/share/applications/$ID.desktop"
ICON="$HOME/.local/share/icons/hicolor/scalable/apps/$ID.svg"

if [ "$1" = "--uninstall" ]; then
    # A biblioteca e as capas ficam: é só tocar de novo para continuar
    rm -rf "$DEST"
    rm -f "$ENTRY" "$ICON"
    update-desktop-database -q "$(dirname "$ENTRY")" 2>/dev/null || true
    echo "Removido."
    exit 0
fi

for lib in libmpv.so.2 libsqlite3.so.0; do
    ldconfig -p | grep -q "$lib" || { echo "Falta a $lib no sistema." >&2; exit 1; }
done

flutter build linux --release
rm -rf "$DEST"
mkdir -p "$DEST" "$(dirname "$ENTRY")" "$(dirname "$ICON")"
cp -r build/linux/x64/release/bundle/. "$DEST/"
cp icon.svg "$ICON"
sed "s|^Exec=psito_player|Exec=$DEST/psito_player|" "$ID.desktop" > "$ENTRY"
update-desktop-database -q "$(dirname "$ENTRY")" 2>/dev/null || true
gtk-update-icon-cache -q -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
echo "Instalado em $DEST. O player aparece no menu."
