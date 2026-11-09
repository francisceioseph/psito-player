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

In the menu of the song that's playing, **Stop after this track** stops when it ends,
and an icon in the bar shows it's on. **Show in file manager** works for any song.

The search button on album, artist and playlist pages looks only inside that list.

**Skip in lists**, in a song's menu, leaves it out when a list plays, on shuffle and in
mixes. It still appears, with a mark, and plays if you click it. In **Songs**, the
**Skipped** filter shows the marked ones, and **Duplicates** groups songs with the same
title and artist and nearly the same length.

Turn on star ratings in Settings, under Library, to rate a song from 1 to 5 stars on its page or in its menu. Clicking the current star removes the rating. Songs with 4 or 5 stars form the Top rated playlist, and songs with 1 star stay out of the mixes.

## Sizes

The button with a frame, in the bar, changes the player's size. **Compact** looks like
a phone app, with navigation at the bottom. **Mini player** is a small window with only
the cover and the controls, which stays above other windows. The button in the side
bar shows or hides its names.

## Pins and mixes

**Pin**, in the menu of an album, artist or playlist, puts it at the top of Home and
Library. **Your mixes**, on Home, are made from your library: the mix of the day
blends what you play with what you haven't heard, and each genre with enough songs
gets its own. They change once a day.

The infinity button, on Home and in the queue, starts a dynamic mix: it keeps adding songs from your library, leaning toward the ones you rate and favorite, until you turn it off or choose something else to play.

## Playlists

- **New playlist** on the Playlists screen creates one: type the name and, if you
  want, already pick the songs, one by one, all the search results or whole folders.
  Picking a folder also suggests its name.
- **Add songs**, inside a playlist, picks songs the same way.
- **Smart playlist**, on the Playlists screen, builds itself from rules on genre, year
  and rating: all of them or any, with an order and a maximum of songs. It updates when
  the library changes. **Edit rules** is inside it.
- **The cover** comes from the playlist's albums: one, or a grid of up to four. The
  image icon in its corner, or **Choose cover** in the menu, uses a picture of your own,
  and **Remove cover** goes back to the albums' covers.
- **Add to playlist**, in any song, album, artist or playlist menu, or in the button
  on an album's page, works from anywhere.
- Drag the handle to reorder, or use **Move up** and **Move down** in the menu.
- **Shuffle the order** and **Remove duplicates**, in the playlist's menu, change the
  list, and the message that appears has **Undo**.
- M3U, M3U8, XSPF and PLS files can be imported and exported.

The queue can also be reordered by right-clicking a song in it, and saved as a
playlist.

## Lyrics

A `.lrc` or `.srt` file with the same name as the song, next to it, or the lyrics in
the file's tags, show up in the Lyrics panel. Click a line to jump to it. If the
timing is off, the clock button adjusts it for that song. An `.lrc` with a time for each word (`<00:12.40>`)
lights the words up as they are sung.

An album in a single file, with a `.cue` of the same name next to it, shows up as separate tracks.
A FLAC can also carry the cue sheet text in a `CUESHEET` tag. These tracks don't have the tag editor,
and organizing keeps the pair together, under its usual name.

## Editing tags

In a song's menu, **Edit tags…** (or Ctrl+E on the focused row) opens title, artist, album,
number, genre, composer, comment, embedded lyrics and cover. The arrows move along the list,
and if something changed it asks before leaving the song.

In an album's menu, **Edit album…** changes what applies to every track and fixes number,
title and artist in a table. Drag the rows and use **Number in order**.

For several songs, mark them with Ctrl+click or Shift+click, or **Select** in the menu, and
use **Edit tags** in the bar that appears. Only what you touch is written.

The player writes only the edited fields: ReplayGain, ratings from other programs and
anything else in the file stay as they are. The notice at the end has **Undo**. WMA files and
files on read-only disks can't be edited. Favorites and stars stay in the library only.

## Organizing files

From an album's menu, a folder in **Folders** or the selection bar, **Organize files…** puts songs
where their tags say. Build the pattern with the buttons, like
`{albumArtist}/{year} - {album}/{disc}{track} {title}`, and see the list of what changes before
confirming. Anything that would get the same name, or land on another file, is marked and stays
where it is. So does the song playing.

The lyrics file with the same name goes along, and the folder's cover when the whole folder moves.
Play counts, ratings, favorites and playlists keep working, and the notice at the end has **Undo**.

**Copy to a folder…** uses the same pattern to take an album, a playlist or a selection to a USB
drive: the originals stay, the preview shows free space and what doesn't fit, and names follow what
the disk accepts. What was already copied isn't copied again.

## Sound

In **Settings, Playback**:

- **Play without gaps** joins songs that were made to run together.
- **Crossfade** overlaps the end of a song and the start of the next, for 3 to 12
  seconds. Songs in a row from the same album stay seamless.
- **Fade when pausing** lowers and brings back the sound gradually.
- **ReplayGain** evens out the volume with the values in the tags. **Track** levels
  each song, and **Album** keeps the differences inside an album. The player doesn't
  calculate these values: tag your files with a tool such as `rsgain` first.
- **Keep the computer awake while playing** leaves the screen on and prevents automatic
  suspend. **Notify when the track changes** shows a notification. Both start off.

In **Settings, Equalizer**, turn on the switch and pick a preset or move the ten bands: the
change applies while the music plays, right after you let go of the band. The overall volume drops a
little when a band goes up, so the sound doesn't distort.

## Keyboard

| Key | Action |
|---|---|
| Space | Play or pause |
| Left, Right | Back or forward 5 seconds |
| Ctrl+Left, Ctrl+Right | Previous or next song |
| M | Mute |
| Ctrl+K | Search |
| Ctrl+E | Edit the tags of the focused row |
| L | Lyrics |
| Q | Queue |
| Tab, Shift+Tab | Move between controls |
| Enter | Activate the control in focus |
| Menu, Shift+F10 | Open the menu of what's in focus |

These are the defaults. **Settings, Keyboard shortcuts** changes them. Media keys
work through your desktop, over MPRIS.

## Where your data is

The library is in `~/.local/share/psito/player`, and cover thumbnails in
`~/.cache/psito/player`. The player only changes your music files when you edit their tags or organize them. What undoes that is kept in `tag-undo` and `organize-undo`, in the library folder, for 7 days.

On Windows, the library is in `%APPDATA%\Psito Player` and the thumbnails in `%LOCALAPPDATA%\Psito Player`. Uninstalling the player doesn't delete those folders.

Closing the window quits the player and stops the music.
