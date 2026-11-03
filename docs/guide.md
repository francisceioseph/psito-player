# Psito Player guide

The player plays the music files on your computer. Nothing is sent anywhere.

## Getting started

Press the square button at the top of the side bar and pick a folder. The player
reads it in the background, and what it has found so far can already be played. In
**Folders** you can add more, check for changes and remove them. Files stay where
they are.

## Finding music

- **Home** shows what's playing or where you stopped, what was added recently, what
  you play most, your playlists and artists, and albums to rediscover.
- **Library** filters by albums, artists, songs, folders, playlists and genres.
- **Search** (Ctrl+K) looks through everything as you type.

## Playing

Click a song to play it and the rest of its list. Hover a card to get its play
button. Right-click albums, artists, songs and playlists for everything else, or use
the Menu key or Shift+F10 on the focused item.

The bar at the bottom has the controls. The lyrics and queue buttons open the side
panel. Clicking the cover opens the song page, with large lyrics, the file's details
and the queue.

The search button on album, artist and playlist pages looks only inside that list.

## Pins and mixes

**Pin**, in the menu of an album, artist or playlist, puts it at the top of Home and
Library. **Your mixes**, on Home, are made from your library: the mix of the day
blends what you play with what you haven't heard, and each genre with enough songs
gets its own. They change once a day.

## Playlists

- **New playlist** on the Playlists screen creates one.
- **Add songs**, inside a playlist, searches your library and adds several at once.
- **Add to playlist**, in any song, album, artist or playlist menu, or in the button
  on an album's page, works from anywhere.
- Drag the handle to reorder, or use **Move up** and **Move down** in the menu.
- M3U and M3U8 files can be imported and exported.

The queue can also be reordered by right-clicking a song in it, and saved as a
playlist.

## Lyrics

A `.lrc` or `.srt` file with the same name as the song, next to it, or the lyrics in
the file's tags, show up in the Lyrics panel. Click a line to jump to it. If the
timing is off, the clock button adjusts it for that song.

## Sound

In **Settings, Playback**:

- **Play without gaps** joins songs that were made to run together.
- **ReplayGain** evens out the volume with the values in the tags. **Track** levels
  each song, and **Album** keeps the differences inside an album. The player doesn't
  calculate these values: tag your files with a tool such as `rsgain` first.

## Keyboard

| Key | Action |
|---|---|
| Space | Play or pause |
| Left, Right | Back or forward 5 seconds |
| Ctrl+Left, Ctrl+Right | Previous or next song |
| M | Mute |
| Ctrl+K | Search |
| L | Lyrics |
| Q | Queue |
| Tab, Shift+Tab | Move between controls |
| Enter | Activate the control in focus |
| Menu, Shift+F10 | Open the menu of what's in focus |

These are the defaults. **Settings, Keyboard shortcuts** changes them. Media keys
work through your desktop, over MPRIS.

## Where your data is

The library is in `~/.local/share/psito/player`, and cover thumbnails in
`~/.cache/psito/player`. Your music files are never changed.

Closing the window quits the player and stops the music.
