#!/bin/bash
# Compila e monta o pacote .rpm para o Fedora, sem sudo. Leva o mesmo bundle do .deb e
# pega a libmpv e o SQLite do sistema. As dependências vão à mão, sem o AutoReq, porque
# o Flutter abre o EGL e o GLES na hora de desenhar e porque o rpm procuraria dentro do
# bundle por bibliotecas que já vêm nele.
# Uso: tool/build-rpm.sh [pasta de saída, padrão build/rpm] [--no-build]
set -e

cd "$(dirname "$0")/.."

OUT="$(realpath -m "${1:-build/rpm}")"
VERSION="$(sed -n 's/^version: \([^+]*\).*/\1/p' pubspec.yaml)"
NAME=psito-player

[ "$2" = "--no-build" ] || flutter build linux --release

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
tool/stage-package.sh "$WORK/stage"

cat > "$WORK/$NAME.spec" <<SPEC
%global debug_package %{nil}
%global __os_install_post %{nil}
%global _build_id_links none

Name: $NAME
Version: $VERSION
Release: 1
Summary: Local music player, with synced lyrics
License: Apache-2.0
URL: https://github.com/francisceioseph/psito-player
AutoReqProv: no
Requires: mpv-libs
Requires: sqlite-libs
Requires: gtk3
Requires: glib2 >= 2.80
Requires: mesa-libEGL
Requires: mesa-libGLES
Recommends: mesa-dri-drivers

%description
Plays the files on your computer: FLAC, MP3, OGG, Opus, M4A, AAC, WMA,
APE, WavPack, AIFF and WAV. Sends nothing anywhere: no account, no streaming,
no telemetry.

%install
cp -a "$WORK/stage/." %{buildroot}/

%files
/usr/bin/psito_player
/usr/lib/$NAME
/usr/share/applications/org.psito.player.desktop
/usr/share/icons/hicolor/scalable/apps/org.psito.player.svg
/usr/share/doc/$NAME
SPEC

mkdir -p "$OUT"
rpmbuild -bb "$WORK/$NAME.spec" --target x86_64 \
    --define "_topdir $WORK/rpmbuild" \
    --define "_rpmdir $OUT" \
    --define "_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" >/dev/null 2>&1
echo "$OUT/$NAME-$VERSION-1.x86_64.rpm"
