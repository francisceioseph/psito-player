# Psito Player

A local music player for Linux, built with Flutter. It plays the files on your
computer and sends nothing anywhere: no account, no streaming, no telemetry.

## Features

- FLAC, MP3, OGG, Opus, M4A and WAV, played by [mpv](https://mpv.io/)
- A library of albums, artists, genres and folders, kept up to date as files change
- Instant search, favorites, and playlists with M3U import and export
- Synced lyrics from `.lrc`, `.srt` or the file's tags, with a per-track delay
- A queue you can reorder and save as a playlist
- English and Portuguese

## Install

You need Flutter 3.47 and the system libraries. On Debian, Ubuntu or Mint:

```bash
sudo apt install libmpv2 libsqlite3-0 libgtk-3-dev ninja-build cmake clang pkg-config
```

Then build and install it for your account, without `sudo`:

```bash
tool/install-local.sh
```

It shows up in your applications menu. `tool/install-local.sh --uninstall` removes
it and keeps your library, in `~/.local/share/psito/player`.

## Develop

```bash
flutter run -d linux
flutter analyze
flutter test
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
to the two together when distributed. On Debian the binaries are GPL-3+.
