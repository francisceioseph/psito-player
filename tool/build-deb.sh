#!/bin/bash
# Compila e monta o pacote .deb, sem sudo. O pacote leva o bundle inteiro e pega a
# libmpv e o SQLite do sistema. O Flutter abre o EGL e o GLES na hora de desenhar,
# então o ldd não os mostra: sem eles nas dependências, o app cai ao abrir. O binário
# usa um símbolo da GLib 2.80, que o Ubuntu 24.04 do CI tem e o Debian 12 não.
# Uso: tool/build-deb.sh [pasta de saída, padrão build/deb] [--no-build]
set -e

cd "$(dirname "$0")/.."

OUT="${1:-build/deb}"
VERSION="$(sed -n 's/^version: \([^+]*\).*/\1/p' pubspec.yaml)"
ID=org.psito.player
NAME=psito-player

[ "$2" = "--no-build" ] || flutter build linux --release
BUNDLE=build/linux/x64/release/bundle

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/DEBIAN" "$ROOT/usr/bin" "$ROOT/usr/lib/$NAME" \
    "$ROOT/usr/share/applications" \
    "$ROOT/usr/share/icons/hicolor/scalable/apps" \
    "$ROOT/usr/share/doc/$NAME"

cp -r "$BUNDLE/." "$ROOT/usr/lib/$NAME/"
ln -s "../lib/$NAME/psito_player" "$ROOT/usr/bin/psito_player"
cp "$ID.desktop" "$ROOT/usr/share/applications/"
cp icon.svg "$ROOT/usr/share/icons/hicolor/scalable/apps/$ID.svg"
cp LICENSE THIRD_PARTY_LICENSES.md README.md "$ROOT/usr/share/doc/$NAME/"
cp docs/guide.md docs/guia.md "$ROOT/usr/share/doc/$NAME/"
# Os textos das licenças do que foi compilado, que o Flutter junta no bundle
gunzip -c "$BUNDLE/data/flutter_assets/NOTICES.Z" > "$ROOT/usr/share/doc/$NAME/NOTICES"

cat > "$ROOT/DEBIAN/control" <<CONTROL
Package: $NAME
Version: $VERSION
Section: sound
Priority: optional
Architecture: amd64
Maintainer: Francisco Souza <francisceioseph@users.noreply.github.com>
Homepage: https://github.com/francisceioseph/psito-player
Installed-Size: $(du -sk "$ROOT/usr" | cut -f1)
Depends: libmpv2, libsqlite3-0, libgtk-3-0 | libgtk-3-0t64, libglib2.0-0t64 (>= 2.80) | libglib2.0-0 (>= 2.80), libegl1, libgles2
Recommends: libgl1-mesa-dri
Description: Local music player, with synced lyrics
 Plays the files on your computer: FLAC, MP3, OGG, Opus, M4A, AAC, WMA,
 APE, WavPack, AIFF and WAV. Sends nothing anywhere: no account, no streaming, no telemetry.
CONTROL

mkdir -p "$OUT"
DEB="$OUT/${NAME}_${VERSION}_amd64.deb"
dpkg-deb --root-owner-group --build "$ROOT" "$DEB" >/dev/null
echo "$DEB"
