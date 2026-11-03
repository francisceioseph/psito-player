# Psito Player

A local music player for Linux, built with Flutter. It plays the files on your
computer and sends nothing anywhere: no account, no streaming, no telemetry.

## Features

- FLAC, MP3, OGG, Opus, M4A, AAC, WMA, APE, WavPack, AIFF and WAV, played by [mpv](https://mpv.io/), without gaps
  between tracks, with ReplayGain and a ten-band equalizer
- A library of albums, artists, genres and folders, kept up to date as files change
- Instant search, favorites, optional star ratings, and playlists with M3U, XSPF and PLS import and export
- A menu on the right mouse button for albums, artists, songs and playlists
- Synced lyrics from `.lrc`, `.srt` or the file's tags, with a per-track delay
- A queue you can reorder and save as a playlist
- A full song page, with large lyrics, file details and the queue
- Compact and mini player modes, and a side bar with or without names
- Pins, mixes that change every day and an endless dynamic mix, made only from your library
- Media keys and desktop sound applets, through MPRIS
- Opening audio files from your file manager, in the player that's already open
- Settings for theme, accent color, density, text size, animations and editable
  keyboard shortcuts
- English and Portuguese

## Install

### From the APT repository

On Debian 13 or newer, Ubuntu 24.04 or newer, or Mint 22 or newer. It updates along with the system:

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://francisceioseph.github.io/psito-player/psito-player.asc | sudo tee /etc/apt/keyrings/psito-player.asc >/dev/null
printf 'Types: deb\nURIs: https://francisceioseph.github.io/psito-player\nSuites: stable\nComponents: main\nSigned-By: /etc/apt/keyrings/psito-player.asc\n' | sudo tee /etc/apt/sources.list.d/psito-player.sources >/dev/null
sudo apt update
sudo apt install psito-player
```

### From the source

You need Flutter 3.47 and the system libraries. On Debian, Ubuntu or Mint:

```bash
sudo apt install libmpv2 libsqlite3-0 libgles2 libegl1 libgtk-3-dev ninja-build cmake clang pkg-config
```

Then build and install it for your account, without `sudo`:

```bash
tool/install-local.sh
```

It shows up in your applications menu. `tool/install-local.sh --uninstall` removes
it and keeps your library, in `~/.local/share/psito/player`.

Or build a package that installs for everyone, and needs no Flutter to run:

```bash
tool/build-deb.sh
sudo apt install ./build/deb/psito-player_*_amd64.deb
```

[The guide](docs/guide.md) ([em português](docs/guia.md)) explains how to use it.

## Develop

```bash
flutter run -d linux
flutter analyze
flutter test
flutter test --update-goldens test/golden_test.dart
flutter test test/bench/library_bench.dart
```

`tool/gen_test_library.py` generates a test library of synthetic tones, with tags,
covers and lyrics. It needs `ffmpeg`.

The widgets in `lib/src/ui/` follow atomic design: `atoms`, `molecules`, `organisms`,
`templates` and `pages`. Texts live in the `.arb` files in `lib/l10n/`, in both
languages.

## Psito OS

The player started in [Psito OS](https://github.com/francisceioseph/psito-os), which
ships it as a system app, but it doesn't depend on it.

## License

The code is under the [Apache License 2.0](LICENSE). The player loads
[libmpv](https://github.com/mpv-player/mpv) at run time. Depending on how your
distribution builds it, that library may be under the GPL, and then those terms apply
to the two together when distributed. On Debian the binaries are GPL-3+. See
[the third-party licenses](THIRD_PARTY_LICENSES.md).
