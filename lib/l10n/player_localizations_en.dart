// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'player_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PlayerLocalizationsEn extends PlayerLocalizations {
  PlayerLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Music Player';

  @override
  String get noTrack => 'No track';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get progress => 'Progress';

  @override
  String get volume => 'Volume';

  @override
  String get home => 'Home';

  @override
  String get library => 'Library';

  @override
  String get playlists => 'Playlists';

  @override
  String get folders => 'Folders';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String engineUnavailable(Object error) {
    return 'The audio engine is unavailable: $error';
  }

  @override
  String get openFailed => 'Could not play this file';

  @override
  String get addFolder => 'Add folder';

  @override
  String get addMusicFolder => 'Add music folder';

  @override
  String get folderNotVisible =>
      'The player can\'t see this folder. Choose one in your home or on an external disk.';

  @override
  String get folderAlreadyAdded => 'This folder is already in the library.';

  @override
  String libraryUnavailable(String error) {
    return 'Could not open the library: $error';
  }

  @override
  String get albums => 'Albums';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String playAlbum(String album) {
    return 'Play $album';
  }

  @override
  String get hasLyrics => 'Has lyrics';

  @override
  String get moreOptions => 'More options';

  @override
  String get playNext => 'Play next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get removeFromQueue => 'Remove from queue';

  @override
  String get queue => 'Queue';

  @override
  String get queueEmpty => 'The queue is empty';

  @override
  String get close => 'Close';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get previousTrack => 'Previous track';

  @override
  String get nextTrack => 'Next track';

  @override
  String get repeatOff => 'Repeat: off';

  @override
  String get repeatAll => 'Repeat: all';

  @override
  String get repeatOne => 'Repeat: one';

  @override
  String get continueListening => 'Continue where you left off';

  @override
  String get continuePlaying => 'Continue';

  @override
  String stoppedAt(String artist, String position, String duration) {
    return '$artist · stopped at $position of $duration';
  }

  @override
  String get shuffleAll => 'Shuffle everything';

  @override
  String get recentlyAdded => 'Recently added';

  @override
  String get seeAll => 'See all';

  @override
  String get mostPlayed => 'Most played';

  @override
  String get emptyTitle => 'Your library is empty';

  @override
  String get emptyBody =>
      'Point to the folder where your music is. The player reads the files directly from your computer and sends nothing out.';

  @override
  String useFolder(String folder) {
    return 'Use $folder';
  }

  @override
  String get acceptedFormats => 'Accepted formats';

  @override
  String get scanning => 'Reading your library';

  @override
  String get scanSubtitle =>
      'Reading in progress: you can already listen to what was found';

  @override
  String scanFiles(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString of $totalString files';
  }

  @override
  String get scanLessThanMinute => 'less than a minute left';

  @override
  String scanMinutesLeft(int n) {
    return 'about $n min left';
  }

  @override
  String get pauseScan => 'Pause';

  @override
  String get resumeScan => 'Resume';

  @override
  String get cancelScan => 'Cancel';

  @override
  String get scanKeepsGoing => 'Reading continues if you leave this screen';

  @override
  String get foundSoFar => 'Found so far';

  @override
  String get updateAll => 'Update all';

  @override
  String get updateFolder => 'Update folder';

  @override
  String get removeFolder => 'Remove from library';

  @override
  String get folderMissing => 'Disk not found';

  @override
  String get notScanned => 'Not read yet';

  @override
  String get scannedJustNow => 'Updated just now';

  @override
  String scannedMinutes(int n) {
    return 'Updated $n min ago';
  }

  @override
  String scannedHours(int n) {
    return 'Updated $n h ago';
  }

  @override
  String scannedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Updated $n days ago',
      one: 'Updated yesterday',
      zero: 'Updated today',
    );
    return '$_temp0';
  }

  @override
  String lengthMinutes(int n) {
    return '$n min';
  }

  @override
  String lengthHours(int h, int m) {
    return '$h h $m min';
  }

  @override
  String albumCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString albums',
      one: '1 album',
      zero: '0 albums',
    );
    return '$_temp0';
  }

  @override
  String trackCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString tracks',
      one: '1 track',
      zero: '0 tracks',
    );
    return '$_temp0';
  }

  @override
  String folderCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString folders',
      one: '1 folder',
      zero: '0 folders',
    );
    return '$_temp0';
  }

  @override
  String coversFound(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString covers found',
      one: '1 cover found',
      zero: '0 covers found',
    );
    return '$_temp0';
  }

  @override
  String filesSkipped(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString files skipped',
      one: '1 file skipped',
      zero: '0 files skipped',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Back';

  @override
  String get songs => 'Songs';

  @override
  String get artists => 'Artists';

  @override
  String get genres => 'Genres';

  @override
  String get allFilter => 'All';

  @override
  String get allSongs => 'All';

  @override
  String get favorites => 'Favorites';

  @override
  String get mineFilter => 'Mine';

  @override
  String get automaticFilter => 'Automatic';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortRecent => 'Recent';

  @override
  String get sortAZ => 'A to Z';

  @override
  String get sortArtist => 'Artist';

  @override
  String get sortYear => 'Year';

  @override
  String get sortMostTracks => 'Most songs';

  @override
  String get columnTitle => 'Title';

  @override
  String get columnAlbum => 'Album';

  @override
  String get columnDuration => 'Duration';

  @override
  String get columnFormat => 'Format';

  @override
  String get viewGrid => 'Grid';

  @override
  String get viewList => 'List';

  @override
  String get searchHint => 'Search the library';

  @override
  String get searchSongsHint => 'Search songs';

  @override
  String get searchArtistsHint => 'Search artists';

  @override
  String get searchGenresHint => 'Search genres';

  @override
  String get searchAlbumsHint => 'Search albums';

  @override
  String get searchFoldersHint => 'Search folders';

  @override
  String get searchAllHint => 'Songs, albums, artists or folders';

  @override
  String get searchShortcut => 'Ctrl K';

  @override
  String get clearSearch => 'Clear search';

  @override
  String noResults(String query) {
    return 'Nothing found for \"$query\"';
  }

  @override
  String get searchPrompt => 'Type to search your library.';

  @override
  String get bestResult => 'Best result';

  @override
  String get playAll => 'Play all';

  @override
  String get kindArtist => 'Artist';

  @override
  String get kindAlbum => 'Album';

  @override
  String get kindSong => 'Song';

  @override
  String get nothingHere => 'Nothing here yet.';

  @override
  String get noGenre => 'No genre';

  @override
  String get fileUnavailable => 'This file is not available right now';

  @override
  String get nothingAvailable =>
      'These songs are not available. Is the disk connected?';

  @override
  String get watchFolders => 'Watch folders for changes';

  @override
  String get watchFoldersBody =>
      'Detects new, changed and removed files while the player is open.';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get importPlaylist => 'Import playlist';

  @override
  String get exportPlaylist => 'Export playlist';

  @override
  String get smartRuleField => 'Field';

  @override
  String get smartRuleCompare => 'Comparison';

  @override
  String get newSmartPlaylist => 'Smart playlist';

  @override
  String get editSmartRules => 'Edit rules';

  @override
  String get smartSuffix => 'smart';

  @override
  String get ruleGenre => 'Genre';

  @override
  String get ruleYear => 'Year';

  @override
  String get ruleRating => 'Rating';

  @override
  String get ruleIs => 'is';

  @override
  String get ruleIsNot => 'is not';

  @override
  String get ruleAtLeast => 'at least';

  @override
  String get ruleAtMost => 'at most';

  @override
  String get matchAllRules => 'All rules';

  @override
  String get matchAnyRule => 'Any rule';

  @override
  String get addRule => 'Add rule';

  @override
  String get removeRule => 'Remove rule';

  @override
  String get smartOrder => 'Order';

  @override
  String get orderTitle => 'Title';

  @override
  String get orderRecent => 'Recently added';

  @override
  String get orderRating => 'Highest rated';

  @override
  String get orderYear => 'Newest';

  @override
  String get smartLimit => 'Maximum songs';

  @override
  String get noLimit => 'No limit';

  @override
  String get choosePlaylistCover => 'Choose cover';

  @override
  String get removePlaylistCover => 'Remove cover';

  @override
  String get coverUnreadable => 'Couldn\'t read that image';

  @override
  String get renamePlaylist => 'Rename';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String deletePlaylistBody(String name) {
    return 'Delete \"$name\"? The music files stay where they are.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get playlistName => 'Playlist name';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get dragToReorder => 'Drag to reorder';

  @override
  String get autoFavorites => 'Favorites';

  @override
  String get autoMostPlayed => 'Most played';

  @override
  String get autoRecent => 'Recently added';

  @override
  String get automaticSuffix => 'automatic';

  @override
  String exportFailed(String error) {
    return 'Could not write the file: $error';
  }

  @override
  String importFailed(String error) {
    return 'Could not read the file: $error';
  }

  @override
  String lengthDays(int d, int h) {
    return '$d d $h h';
  }

  @override
  String artistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n artists',
      one: '1 artist',
    );
    return '$_temp0';
  }

  @override
  String genreCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n genres',
      one: '1 genre',
    );
    return '$_temp0';
  }

  @override
  String playlistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n playlists',
      one: '1 playlist',
    );
    return '$_temp0';
  }

  @override
  String fileCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String folderChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n changes',
      one: '1 change',
    );
    return '$_temp0';
  }

  @override
  String imported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n songs imported',
      one: '1 song imported',
    );
    return '$_temp0';
  }

  @override
  String importedRemote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n network addresses skipped',
      one: '1 network address skipped',
    );
    return '$_temp0';
  }

  @override
  String get lyricsTab => 'Lyrics';

  @override
  String get coverTab => 'Cover';

  @override
  String get noLyrics => 'This track has no lyrics';

  @override
  String get lyricsSynced => 'synced';

  @override
  String get lyricsUnsynced => 'not synced';

  @override
  String get lyricsEmbedded => 'In the tags';

  @override
  String get lyricsTiming => 'Adjust the lyrics timing';

  @override
  String get lyricsEarlier => 'Show the lyrics earlier';

  @override
  String get lyricsLater => 'Show the lyrics later';

  @override
  String get lyricsResetTiming => 'Reset the timing';

  @override
  String get withLyrics => 'With lyrics';

  @override
  String get upNext => 'Up next';

  @override
  String get clearQueue => 'Clear';

  @override
  String get saveAsPlaylist => 'Save as playlist';

  @override
  String get detailAlbum => 'Album';

  @override
  String get detailGenre => 'Genre';

  @override
  String get detailFile => 'File';

  @override
  String get detailCover => 'Cover';

  @override
  String get detailFolder => 'Folder';

  @override
  String get coverEmbedded => 'Embedded';

  @override
  String get coverGenerated => 'Generated';

  @override
  String secondsOffset(String value) {
    return '$value s';
  }

  @override
  String playlistSaved(String name) {
    return 'Saved as “$name”';
  }

  @override
  String get settingsPlayback => 'Playback';

  @override
  String get settingsEqualizer => 'Equalizer';

  @override
  String get equalizerOn => 'Use the equalizer';

  @override
  String get equalizerHint =>
      'Lowers the overall volume a little to make room for the boosted bands, so the sound doesn\'t distort.';

  @override
  String get equalizerPresets => 'Presets';

  @override
  String get equalizerCustom => 'Custom';

  @override
  String get equalizerFlat => 'Flat';

  @override
  String get equalizerRock => 'Rock';

  @override
  String get equalizerPop => 'Pop';

  @override
  String get equalizerJazz => 'Jazz';

  @override
  String get equalizerClassical => 'Classical';

  @override
  String get equalizerElectronic => 'Electronic';

  @override
  String get equalizerBass => 'More bass';

  @override
  String get equalizerTreble => 'More treble';

  @override
  String get equalizerVocal => 'Vocals';

  @override
  String equalizerHz(String value) {
    return '$value Hz';
  }

  @override
  String equalizerKhz(String value) {
    return '$value kHz';
  }

  @override
  String equalizerGain(String value) {
    return '$value dB';
  }

  @override
  String get settingsLibrary => 'Library';

  @override
  String get settingsLyrics => 'Lyrics';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsShortcuts => 'Keyboard shortcuts';

  @override
  String get settingsAbout => 'About';

  @override
  String get rememberSession => 'Remember the last track';

  @override
  String get rememberSessionHint =>
      'Reopen the queue where it stopped, paused.';

  @override
  String get playWholeList => 'Play the whole list when choosing a track';

  @override
  String get playWholeListHint => 'Turned off, only the chosen track plays.';

  @override
  String get closeNote =>
      'Closing the window quits the player and stops the music.';

  @override
  String get stopAfterTrack => 'Stop after this track';

  @override
  String get cancelStopAfter => 'Keep playing after this track';

  @override
  String get showInFiles => 'Show in file manager';

  @override
  String get keepAwake => 'Keep the computer awake while playing';

  @override
  String get keepAwakeHint =>
      'The screen stays on and the computer doesn\'t suspend by itself. Paused, it goes back to normal.';

  @override
  String get keepAwakeReason => 'Playing music';

  @override
  String get notifyTrack => 'Notify when the track changes';

  @override
  String get notifyTrackHint =>
      'Shows the title and artist in a system notification.';

  @override
  String get shuffleOrder => 'Shuffle the order';

  @override
  String get playlistShuffled => 'Order shuffled';

  @override
  String get removeDuplicates => 'Remove duplicates';

  @override
  String duplicatesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicates removed',
      one: '1 duplicate removed',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Undo';

  @override
  String get gapless => 'Play without gaps between tracks';

  @override
  String get gaplessHint =>
      'Turned off, the sound output closes and opens between tracks.';

  @override
  String get crossfade => 'Crossfade';

  @override
  String get crossfadeOff => 'Off';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get crossfadeHint =>
      'Songs overlap as they change. Songs in a row from the same album stay seamless.';

  @override
  String get fadeOnPause => 'Fade when pausing';

  @override
  String get fadeOnPauseHint =>
      'The sound fades out and back in when you pause and resume.';

  @override
  String get replayGain => 'ReplayGain';

  @override
  String get replayGainOff => 'Off';

  @override
  String get replayGainTrack => 'Track';

  @override
  String get replayGainAlbum => 'Album';

  @override
  String get replayGainHint =>
      'Evens out the volume using the values in the file\'s tags. Album keeps the differences within an album. Files without those tags play unchanged.';

  @override
  String get libraryFolders => 'Library folders';

  @override
  String get watchFoldersSetting => 'Watch folders for changes';

  @override
  String get watchFoldersHint =>
      'New, changed and removed files show up while the player is open.';

  @override
  String get refreshOnOpen => 'Update when opening';

  @override
  String get refreshOnOpenHint =>
      'Check the folders each time the player opens.';

  @override
  String get refreshNow => 'Update now';

  @override
  String get lyricsFiles => 'Look for .lrc and .srt files';

  @override
  String get lyricsFilesHint => 'Next to the music, with the same name.';

  @override
  String get lyricsEmbeddedSetting => 'Use embedded lyrics';

  @override
  String get lyricsEmbeddedHint =>
      'From the file\'s tags, when there is no lyrics file.';

  @override
  String get themeSetting => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get dynamicColor => 'Dynamic system color';

  @override
  String get dynamicColorHint =>
      'Uses the wallpaper colors, when the system offers them.';

  @override
  String get accentSetting => 'Accent color';

  @override
  String get accentDefault => 'Default';

  @override
  String get accentCoral => 'Coral';

  @override
  String get accentAmber => 'Amber';

  @override
  String get accentGreen => 'Green';

  @override
  String get accentTeal => 'Teal';

  @override
  String get accentBlue => 'Blue';

  @override
  String get accentPurple => 'Purple';

  @override
  String get densitySetting => 'List density';

  @override
  String get densityComfortable => 'Comfortable';

  @override
  String get densityCompact => 'Compact';

  @override
  String get textSizeSetting => 'Text size';

  @override
  String get reduceMotion => 'Reduce animations';

  @override
  String get reduceMotionHint =>
      'Turns off the lyrics scrolling and other animations.';

  @override
  String get resetShortcuts => 'Restore defaults';

  @override
  String get mediaKeysNote =>
      'The keyboard\'s media keys (play, pause, next, previous) work without any setup.';

  @override
  String get commandPlayPause => 'Play and pause';

  @override
  String get commandSeekBack => 'Back 5 seconds';

  @override
  String get commandSeekForward => 'Forward 5 seconds';

  @override
  String get commandPrevious => 'Previous track';

  @override
  String get commandNext => 'Next track';

  @override
  String get commandMute => 'Mute';

  @override
  String get commandSearch => 'Search';

  @override
  String get commandLyrics => 'Open and close the lyrics';

  @override
  String get commandQueue => 'Open and close the queue';

  @override
  String get keySpace => 'Space';

  @override
  String changeShortcut(String command) {
    return 'Change the shortcut: $command';
  }

  @override
  String get pressKeys => 'Press the new keys. Esc cancels.';

  @override
  String shortcutInUse(String command) {
    return 'Already used by: $command';
  }

  @override
  String get aboutDescription =>
      'Plays the files on your computer. No account, no streaming and no tracking: what you listen to stays with you.';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get licenseLabel => 'License: Apache 2.0';

  @override
  String get thirdPartyLicenses => 'Full license texts';

  @override
  String get builtWithClaude => 'Developed with the help of Claude Code.';

  @override
  String get reportIssue => 'Report a problem on GitHub';

  @override
  String get designInspiration => 'Design inspiration';

  @override
  String get dartPackagesLabel => 'Licenses: Dart packages';

  @override
  String get systemLibrariesLabel => 'Licenses: system libraries';

  @override
  String get interfaceAssetsLabel => 'Licenses: icons';

  @override
  String get keepLogs => 'Write logs';

  @override
  String get keepLogsHint =>
      'To investigate a problem. They include song names and paths, and stay on this computer.';

  @override
  String get aboutSupport => 'Support';

  @override
  String get openDataFolder => 'Open the data folder';

  @override
  String get copySupportInfo => 'Copy information for support';

  @override
  String get supportInfoCopied => 'Copied';

  @override
  String addedToPlaylist(String name) {
    return 'Added to “$name”';
  }

  @override
  String get addTracks => 'Add songs';

  @override
  String addTracksConfirm(int n) {
    return 'Add $n';
  }

  @override
  String get alreadyInPlaylist => 'Already in this playlist';

  @override
  String get searchTracksHint => 'Search songs';

  @override
  String get playlistEmptyHint =>
      'This playlist is empty. Use Add songs to fill it.';

  @override
  String tracksAdded(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n songs added',
      one: '1 song added',
    );
    return '$_temp0';
  }

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get yourLibrary => 'Your library';

  @override
  String get rediscover => 'Rediscover';

  @override
  String get yourPlaylists => 'Your playlists';

  @override
  String get filterList => 'Search in this list';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearRecent => 'Clear';

  @override
  String get removeRecent => 'Remove from recent searches';

  @override
  String get browseGenres => 'Browse by genre';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get pinned => 'Pinned';

  @override
  String get pinnedHeading => 'Pinned';

  @override
  String get yourMixes => 'Your mixes';

  @override
  String get dailyMix => 'Mix of the day';

  @override
  String genreMix(String genre) {
    return '$genre mix';
  }

  @override
  String get openTrackPage => 'Open the song page';

  @override
  String get trackDetails => 'Details';

  @override
  String get overview => 'Overview';

  @override
  String get singles => 'Single tracks';

  @override
  String singlesHint(String tracks) {
    return '$tracks that are alone in their album';
  }

  @override
  String get expandRail => 'Show names';

  @override
  String get collapseRail => 'Hide names';

  @override
  String get playerSize => 'Player size';

  @override
  String get modeFull => 'Full';

  @override
  String get modeCompact => 'Compact';

  @override
  String get modeMini => 'Mini player';

  @override
  String get exitMini => 'Leave the mini player';

  @override
  String get autoTopRated => 'Top rated';

  @override
  String get rateTrack => 'Rate…';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get clearRating => 'Remove the rating';

  @override
  String get dynamicMixStart => 'Start dynamic mix';

  @override
  String get dynamicMixStop => 'Stop dynamic mix';

  @override
  String get columnRating => 'Rating';

  @override
  String get useRatings => 'Use star ratings';

  @override
  String get useRatingsHint =>
      'Shows stars next to the heart. Turned off, the ratings you gave stay saved, and songs with one star stay out of the mixes.';

  @override
  String markAll(int n) {
    return 'Select all ($n)';
  }

  @override
  String get clearSelection => 'Clear selection';

  @override
  String createWithTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Create with $n songs',
      one: 'Create with 1 song',
    );
    return '$_temp0';
  }
}
