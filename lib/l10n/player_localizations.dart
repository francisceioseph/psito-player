import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'player_localizations_en.dart';
import 'player_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of PlayerLocalizations
/// returned by `PlayerLocalizations.of(context)`.
///
/// Applications need to include `PlayerLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/player_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PlayerLocalizations.localizationsDelegates,
///   supportedLocales: PlayerLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the PlayerLocalizations.supportedLocales
/// property.
abstract class PlayerLocalizations {
  PlayerLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PlayerLocalizations of(BuildContext context) {
    return Localizations.of<PlayerLocalizations>(context, PlayerLocalizations)!;
  }

  static const LocalizationsDelegate<PlayerLocalizations> delegate =
      _PlayerLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Music Player'**
  String get appName;

  /// No description provided for @noTrack.
  ///
  /// In en, this message translates to:
  /// **'No track'**
  String get noTrack;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @engineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The audio engine is unavailable: {error}'**
  String engineUnavailable(Object error);

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play this file'**
  String get openFailed;

  /// No description provided for @addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add folder'**
  String get addFolder;

  /// No description provided for @addMusicFolder.
  ///
  /// In en, this message translates to:
  /// **'Add music folder'**
  String get addMusicFolder;

  /// No description provided for @folderNotVisible.
  ///
  /// In en, this message translates to:
  /// **'The player can\'t see this folder. Choose one in your home or on an external disk.'**
  String get folderNotVisible;

  /// No description provided for @folderAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This folder is already in the library.'**
  String get folderAlreadyAdded;

  /// No description provided for @libraryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open the library: {error}'**
  String libraryUnavailable(String error);

  /// No description provided for @albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// No description provided for @playAlbum.
  ///
  /// In en, this message translates to:
  /// **'Play {album}'**
  String playAlbum(String album);

  /// No description provided for @hasLyrics.
  ///
  /// In en, this message translates to:
  /// **'Has lyrics'**
  String get hasLyrics;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get playNext;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get addToQueue;

  /// No description provided for @removeFromQueue.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get removeFromQueue;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'The queue is empty'**
  String get queueEmpty;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @previousTrack.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get previousTrack;

  /// No description provided for @nextTrack.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get nextTrack;

  /// No description provided for @repeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat: off'**
  String get repeatOff;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat: all'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat: one'**
  String get repeatOne;

  /// No description provided for @continueListening.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off'**
  String get continueListening;

  /// No description provided for @continuePlaying.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continuePlaying;

  /// No description provided for @stoppedAt.
  ///
  /// In en, this message translates to:
  /// **'{artist} · stopped at {position} of {duration}'**
  String stoppedAt(String artist, String position, String duration);

  /// No description provided for @shuffleAll.
  ///
  /// In en, this message translates to:
  /// **'Shuffle everything'**
  String get shuffleAll;

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get recentlyAdded;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @mostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get mostPlayed;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Point to the folder where your music is. The player reads the files directly from your computer and sends nothing out.'**
  String get emptyBody;

  /// No description provided for @useFolder.
  ///
  /// In en, this message translates to:
  /// **'Use {folder}'**
  String useFolder(String folder);

  /// No description provided for @acceptedFormats.
  ///
  /// In en, this message translates to:
  /// **'Accepted formats'**
  String get acceptedFormats;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Reading your library'**
  String get scanning;

  /// No description provided for @scanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reading in progress: you can already listen to what was found'**
  String get scanSubtitle;

  /// No description provided for @scanFiles.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} files'**
  String scanFiles(int done, int total);

  /// No description provided for @scanLessThanMinute.
  ///
  /// In en, this message translates to:
  /// **'less than a minute left'**
  String get scanLessThanMinute;

  /// No description provided for @scanMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'about {n} min left'**
  String scanMinutesLeft(int n);

  /// No description provided for @pauseScan.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseScan;

  /// No description provided for @resumeScan.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeScan;

  /// No description provided for @cancelScan.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelScan;

  /// No description provided for @scanKeepsGoing.
  ///
  /// In en, this message translates to:
  /// **'Reading continues if you leave this screen'**
  String get scanKeepsGoing;

  /// No description provided for @foundSoFar.
  ///
  /// In en, this message translates to:
  /// **'Found so far'**
  String get foundSoFar;

  /// No description provided for @updateAll.
  ///
  /// In en, this message translates to:
  /// **'Update all'**
  String get updateAll;

  /// No description provided for @updateFolder.
  ///
  /// In en, this message translates to:
  /// **'Update folder'**
  String get updateFolder;

  /// No description provided for @removeFolder.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get removeFolder;

  /// No description provided for @folderMissing.
  ///
  /// In en, this message translates to:
  /// **'Disk not found'**
  String get folderMissing;

  /// No description provided for @notScanned.
  ///
  /// In en, this message translates to:
  /// **'Not read yet'**
  String get notScanned;

  /// No description provided for @scannedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get scannedJustNow;

  /// No description provided for @scannedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Updated {n} min ago'**
  String scannedMinutes(int n);

  /// No description provided for @scannedHours.
  ///
  /// In en, this message translates to:
  /// **'Updated {n} h ago'**
  String scannedHours(int n);

  /// No description provided for @scannedDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Updated today} =1{Updated yesterday} other{Updated {n} days ago}}'**
  String scannedDays(int n);

  /// No description provided for @lengthMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String lengthMinutes(int n);

  /// No description provided for @lengthHours.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String lengthHours(int h, int m);

  /// No description provided for @albumCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{0 albums} =1{1 album} other{{n} albums}}'**
  String albumCount(int n);

  /// No description provided for @trackCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{0 tracks} =1{1 track} other{{n} tracks}}'**
  String trackCount(int n);

  /// No description provided for @folderCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{0 folders} =1{1 folder} other{{n} folders}}'**
  String folderCount(int n);

  /// No description provided for @coversFound.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{0 covers found} =1{1 cover found} other{{n} covers found}}'**
  String coversFound(int n);

  /// No description provided for @filesSkipped.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{0 files skipped} =1{1 file skipped} other{{n} files skipped}}'**
  String filesSkipped(int n);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @songs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songs;

  /// No description provided for @artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// No description provided for @genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @allSongs.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allSongs;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @mineFilter.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get mineFilter;

  /// No description provided for @automaticFilter.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automaticFilter;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sortRecent;

  /// No description provided for @sortAZ.
  ///
  /// In en, this message translates to:
  /// **'A to Z'**
  String get sortAZ;

  /// No description provided for @sortArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get sortArtist;

  /// No description provided for @sortYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get sortYear;

  /// No description provided for @sortMostTracks.
  ///
  /// In en, this message translates to:
  /// **'Most songs'**
  String get sortMostTracks;

  /// No description provided for @columnTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get columnTitle;

  /// No description provided for @columnAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get columnAlbum;

  /// No description provided for @columnDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get columnDuration;

  /// No description provided for @columnFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get columnFormat;

  /// No description provided for @viewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get viewGrid;

  /// No description provided for @viewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get viewList;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search the library'**
  String get searchHint;

  /// No description provided for @searchSongsHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs'**
  String get searchSongsHint;

  /// No description provided for @searchArtistsHint.
  ///
  /// In en, this message translates to:
  /// **'Search artists'**
  String get searchArtistsHint;

  /// No description provided for @searchGenresHint.
  ///
  /// In en, this message translates to:
  /// **'Search genres'**
  String get searchGenresHint;

  /// No description provided for @searchAlbumsHint.
  ///
  /// In en, this message translates to:
  /// **'Search albums'**
  String get searchAlbumsHint;

  /// No description provided for @searchFoldersHint.
  ///
  /// In en, this message translates to:
  /// **'Search folders'**
  String get searchFoldersHint;

  /// No description provided for @searchAllHint.
  ///
  /// In en, this message translates to:
  /// **'Songs, albums, artists or folders'**
  String get searchAllHint;

  /// No description provided for @searchShortcut.
  ///
  /// In en, this message translates to:
  /// **'Ctrl K'**
  String get searchShortcut;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found for \"{query}\"'**
  String noResults(String query);

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type to search your library.'**
  String get searchPrompt;

  /// No description provided for @bestResult.
  ///
  /// In en, this message translates to:
  /// **'Best result'**
  String get bestResult;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get playAll;

  /// No description provided for @kindArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get kindArtist;

  /// No description provided for @kindAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get kindAlbum;

  /// No description provided for @kindSong.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get kindSong;

  /// No description provided for @nothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get nothingHere;

  /// No description provided for @noGenre.
  ///
  /// In en, this message translates to:
  /// **'No genre'**
  String get noGenre;

  /// No description provided for @fileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This file is not available right now'**
  String get fileUnavailable;

  /// No description provided for @nothingAvailable.
  ///
  /// In en, this message translates to:
  /// **'These songs are not available. Is the disk connected?'**
  String get nothingAvailable;

  /// No description provided for @watchFolders.
  ///
  /// In en, this message translates to:
  /// **'Watch folders for changes'**
  String get watchFolders;

  /// No description provided for @watchFoldersBody.
  ///
  /// In en, this message translates to:
  /// **'Detects new, changed and removed files while the player is open.'**
  String get watchFoldersBody;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylist;

  /// No description provided for @importPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Import playlist'**
  String get importPlaylist;

  /// No description provided for @exportPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Export playlist'**
  String get exportPlaylist;

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renamePlaylist;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? The music files stay where they are.'**
  String deletePlaylistBody(String name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistName;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist;

  /// No description provided for @removeFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get removeFromPlaylist;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get dragToReorder;

  /// No description provided for @autoFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get autoFavorites;

  /// No description provided for @autoMostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get autoMostPlayed;

  /// No description provided for @autoRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get autoRecent;

  /// No description provided for @automaticSuffix.
  ///
  /// In en, this message translates to:
  /// **'automatic'**
  String get automaticSuffix;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not write the file: {error}'**
  String exportFailed(String error);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file: {error}'**
  String importFailed(String error);

  /// No description provided for @lengthDays.
  ///
  /// In en, this message translates to:
  /// **'{d} d {h} h'**
  String lengthDays(int d, int h);

  /// No description provided for @artistCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 artist} other{{n} artists}}'**
  String artistCount(int n);

  /// No description provided for @genreCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 genre} other{{n} genres}}'**
  String genreCount(int n);

  /// No description provided for @playlistCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 playlist} other{{n} playlists}}'**
  String playlistCount(int n);

  /// No description provided for @fileCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 file} other{{n} files}}'**
  String fileCount(int n);

  /// No description provided for @folderChanges.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 change} other{{n} changes}}'**
  String folderChanges(int n);

  /// No description provided for @imported.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 song imported} other{{n} songs imported}}'**
  String imported(int n);

  /// No description provided for @importedRemote.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 network address skipped} other{{n} network addresses skipped}}'**
  String importedRemote(int n);

  /// No description provided for @lyricsTab.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyricsTab;

  /// No description provided for @coverTab.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get coverTab;

  /// No description provided for @noLyrics.
  ///
  /// In en, this message translates to:
  /// **'This track has no lyrics'**
  String get noLyrics;

  /// No description provided for @lyricsSynced.
  ///
  /// In en, this message translates to:
  /// **'synced'**
  String get lyricsSynced;

  /// No description provided for @lyricsUnsynced.
  ///
  /// In en, this message translates to:
  /// **'not synced'**
  String get lyricsUnsynced;

  /// No description provided for @lyricsEmbedded.
  ///
  /// In en, this message translates to:
  /// **'In the tags'**
  String get lyricsEmbedded;

  /// No description provided for @lyricsTiming.
  ///
  /// In en, this message translates to:
  /// **'Adjust the lyrics timing'**
  String get lyricsTiming;

  /// No description provided for @lyricsEarlier.
  ///
  /// In en, this message translates to:
  /// **'Show the lyrics earlier'**
  String get lyricsEarlier;

  /// No description provided for @lyricsLater.
  ///
  /// In en, this message translates to:
  /// **'Show the lyrics later'**
  String get lyricsLater;

  /// No description provided for @lyricsResetTiming.
  ///
  /// In en, this message translates to:
  /// **'Reset the timing'**
  String get lyricsResetTiming;

  /// No description provided for @withLyrics.
  ///
  /// In en, this message translates to:
  /// **'With lyrics'**
  String get withLyrics;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// No description provided for @clearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearQueue;

  /// No description provided for @saveAsPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Save as playlist'**
  String get saveAsPlaylist;

  /// No description provided for @detailAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get detailAlbum;

  /// No description provided for @detailGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get detailGenre;

  /// No description provided for @detailFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get detailFile;

  /// No description provided for @detailCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get detailCover;

  /// No description provided for @detailFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get detailFolder;

  /// No description provided for @coverEmbedded.
  ///
  /// In en, this message translates to:
  /// **'Embedded'**
  String get coverEmbedded;

  /// No description provided for @coverGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get coverGenerated;

  /// No description provided for @secondsOffset.
  ///
  /// In en, this message translates to:
  /// **'{value} s'**
  String secondsOffset(String value);

  /// No description provided for @playlistSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as “{name}”'**
  String playlistSaved(String name);

  /// No description provided for @settingsPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get settingsPlayback;

  /// No description provided for @settingsEqualizer.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get settingsEqualizer;

  /// No description provided for @equalizerOn.
  ///
  /// In en, this message translates to:
  /// **'Use the equalizer'**
  String get equalizerOn;

  /// No description provided for @equalizerHint.
  ///
  /// In en, this message translates to:
  /// **'Lowers the overall volume a little to make room for the boosted bands, so the sound doesn\'t distort.'**
  String get equalizerHint;

  /// No description provided for @equalizerPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get equalizerPresets;

  /// No description provided for @equalizerCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get equalizerCustom;

  /// No description provided for @equalizerFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get equalizerFlat;

  /// No description provided for @equalizerRock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get equalizerRock;

  /// No description provided for @equalizerPop.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get equalizerPop;

  /// No description provided for @equalizerJazz.
  ///
  /// In en, this message translates to:
  /// **'Jazz'**
  String get equalizerJazz;

  /// No description provided for @equalizerClassical.
  ///
  /// In en, this message translates to:
  /// **'Classical'**
  String get equalizerClassical;

  /// No description provided for @equalizerElectronic.
  ///
  /// In en, this message translates to:
  /// **'Electronic'**
  String get equalizerElectronic;

  /// No description provided for @equalizerBass.
  ///
  /// In en, this message translates to:
  /// **'More bass'**
  String get equalizerBass;

  /// No description provided for @equalizerTreble.
  ///
  /// In en, this message translates to:
  /// **'More treble'**
  String get equalizerTreble;

  /// No description provided for @equalizerVocal.
  ///
  /// In en, this message translates to:
  /// **'Vocals'**
  String get equalizerVocal;

  /// No description provided for @equalizerHz.
  ///
  /// In en, this message translates to:
  /// **'{value} Hz'**
  String equalizerHz(String value);

  /// No description provided for @equalizerKhz.
  ///
  /// In en, this message translates to:
  /// **'{value} kHz'**
  String equalizerKhz(String value);

  /// No description provided for @equalizerGain.
  ///
  /// In en, this message translates to:
  /// **'{value} dB'**
  String equalizerGain(String value);

  /// No description provided for @settingsLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsLibrary;

  /// No description provided for @settingsLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get settingsLyrics;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get settingsShortcuts;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @rememberSession.
  ///
  /// In en, this message translates to:
  /// **'Remember the last track'**
  String get rememberSession;

  /// No description provided for @rememberSessionHint.
  ///
  /// In en, this message translates to:
  /// **'Reopen the queue where it stopped, paused.'**
  String get rememberSessionHint;

  /// No description provided for @playWholeList.
  ///
  /// In en, this message translates to:
  /// **'Play the whole list when choosing a track'**
  String get playWholeList;

  /// No description provided for @playWholeListHint.
  ///
  /// In en, this message translates to:
  /// **'Turned off, only the chosen track plays.'**
  String get playWholeListHint;

  /// No description provided for @closeNote.
  ///
  /// In en, this message translates to:
  /// **'Closing the window quits the player and stops the music.'**
  String get closeNote;

  /// No description provided for @stopAfterTrack.
  ///
  /// In en, this message translates to:
  /// **'Stop after this track'**
  String get stopAfterTrack;

  /// No description provided for @cancelStopAfter.
  ///
  /// In en, this message translates to:
  /// **'Keep playing after this track'**
  String get cancelStopAfter;

  /// No description provided for @showInFiles.
  ///
  /// In en, this message translates to:
  /// **'Show in file manager'**
  String get showInFiles;

  /// No description provided for @keepAwake.
  ///
  /// In en, this message translates to:
  /// **'Keep the computer awake while playing'**
  String get keepAwake;

  /// No description provided for @keepAwakeHint.
  ///
  /// In en, this message translates to:
  /// **'The screen stays on and the computer doesn\'t suspend by itself. Paused, it goes back to normal.'**
  String get keepAwakeHint;

  /// No description provided for @keepAwakeReason.
  ///
  /// In en, this message translates to:
  /// **'Playing music'**
  String get keepAwakeReason;

  /// No description provided for @notifyTrack.
  ///
  /// In en, this message translates to:
  /// **'Notify when the track changes'**
  String get notifyTrack;

  /// No description provided for @notifyTrackHint.
  ///
  /// In en, this message translates to:
  /// **'Shows the title and artist in a system notification.'**
  String get notifyTrackHint;

  /// No description provided for @shuffleOrder.
  ///
  /// In en, this message translates to:
  /// **'Shuffle the order'**
  String get shuffleOrder;

  /// No description provided for @playlistShuffled.
  ///
  /// In en, this message translates to:
  /// **'Order shuffled'**
  String get playlistShuffled;

  /// No description provided for @removeDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Remove duplicates'**
  String get removeDuplicates;

  /// No description provided for @duplicatesRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 duplicate removed} other{{count} duplicates removed}}'**
  String duplicatesRemoved(int count);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @gapless.
  ///
  /// In en, this message translates to:
  /// **'Play without gaps between tracks'**
  String get gapless;

  /// No description provided for @gaplessHint.
  ///
  /// In en, this message translates to:
  /// **'Turned off, the sound output closes and opens between tracks.'**
  String get gaplessHint;

  /// No description provided for @replayGain.
  ///
  /// In en, this message translates to:
  /// **'ReplayGain'**
  String get replayGain;

  /// No description provided for @replayGainOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get replayGainOff;

  /// No description provided for @replayGainTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get replayGainTrack;

  /// No description provided for @replayGainAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get replayGainAlbum;

  /// No description provided for @replayGainHint.
  ///
  /// In en, this message translates to:
  /// **'Evens out the volume using the values in the file\'s tags. Album keeps the differences within an album. Files without those tags play unchanged.'**
  String get replayGainHint;

  /// No description provided for @libraryFolders.
  ///
  /// In en, this message translates to:
  /// **'Library folders'**
  String get libraryFolders;

  /// No description provided for @watchFoldersSetting.
  ///
  /// In en, this message translates to:
  /// **'Watch folders for changes'**
  String get watchFoldersSetting;

  /// No description provided for @watchFoldersHint.
  ///
  /// In en, this message translates to:
  /// **'New, changed and removed files show up while the player is open.'**
  String get watchFoldersHint;

  /// No description provided for @refreshOnOpen.
  ///
  /// In en, this message translates to:
  /// **'Update when opening'**
  String get refreshOnOpen;

  /// No description provided for @refreshOnOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Check the folders each time the player opens.'**
  String get refreshOnOpenHint;

  /// No description provided for @refreshNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get refreshNow;

  /// No description provided for @lyricsFiles.
  ///
  /// In en, this message translates to:
  /// **'Look for .lrc and .srt files'**
  String get lyricsFiles;

  /// No description provided for @lyricsFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Next to the music, with the same name.'**
  String get lyricsFilesHint;

  /// No description provided for @lyricsEmbeddedSetting.
  ///
  /// In en, this message translates to:
  /// **'Use embedded lyrics'**
  String get lyricsEmbeddedSetting;

  /// No description provided for @lyricsEmbeddedHint.
  ///
  /// In en, this message translates to:
  /// **'From the file\'s tags, when there is no lyrics file.'**
  String get lyricsEmbeddedHint;

  /// No description provided for @themeSetting.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSetting;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @dynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic system color'**
  String get dynamicColor;

  /// No description provided for @dynamicColorHint.
  ///
  /// In en, this message translates to:
  /// **'Uses the wallpaper colors, when the system offers them.'**
  String get dynamicColorHint;

  /// No description provided for @accentSetting.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentSetting;

  /// No description provided for @accentDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get accentDefault;

  /// No description provided for @accentCoral.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get accentCoral;

  /// No description provided for @accentAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get accentAmber;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get accentGreen;

  /// No description provided for @accentTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get accentTeal;

  /// No description provided for @accentBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get accentBlue;

  /// No description provided for @accentPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get accentPurple;

  /// No description provided for @densitySetting.
  ///
  /// In en, this message translates to:
  /// **'List density'**
  String get densitySetting;

  /// No description provided for @densityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get densityComfortable;

  /// No description provided for @densityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get densityCompact;

  /// No description provided for @textSizeSetting.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeSetting;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce animations'**
  String get reduceMotion;

  /// No description provided for @reduceMotionHint.
  ///
  /// In en, this message translates to:
  /// **'Turns off the lyrics scrolling and other animations.'**
  String get reduceMotionHint;

  /// No description provided for @resetShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get resetShortcuts;

  /// No description provided for @mediaKeysNote.
  ///
  /// In en, this message translates to:
  /// **'The keyboard\'s media keys (play, pause, next, previous) work without any setup.'**
  String get mediaKeysNote;

  /// No description provided for @commandPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play and pause'**
  String get commandPlayPause;

  /// No description provided for @commandSeekBack.
  ///
  /// In en, this message translates to:
  /// **'Back 5 seconds'**
  String get commandSeekBack;

  /// No description provided for @commandSeekForward.
  ///
  /// In en, this message translates to:
  /// **'Forward 5 seconds'**
  String get commandSeekForward;

  /// No description provided for @commandPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get commandPrevious;

  /// No description provided for @commandNext.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get commandNext;

  /// No description provided for @commandMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get commandMute;

  /// No description provided for @commandSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commandSearch;

  /// No description provided for @commandLyrics.
  ///
  /// In en, this message translates to:
  /// **'Open and close the lyrics'**
  String get commandLyrics;

  /// No description provided for @commandQueue.
  ///
  /// In en, this message translates to:
  /// **'Open and close the queue'**
  String get commandQueue;

  /// No description provided for @keySpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get keySpace;

  /// No description provided for @changeShortcut.
  ///
  /// In en, this message translates to:
  /// **'Change the shortcut: {command}'**
  String changeShortcut(String command);

  /// No description provided for @pressKeys.
  ///
  /// In en, this message translates to:
  /// **'Press the new keys. Esc cancels.'**
  String get pressKeys;

  /// No description provided for @shortcutInUse.
  ///
  /// In en, this message translates to:
  /// **'Already used by: {command}'**
  String shortcutInUse(String command);

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Plays the files on your computer. No account, no streaming and no tracking: what you listen to stays with you.'**
  String get aboutDescription;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @licenseLabel.
  ///
  /// In en, this message translates to:
  /// **'License: Apache 2.0'**
  String get licenseLabel;

  /// No description provided for @thirdPartyLicenses.
  ///
  /// In en, this message translates to:
  /// **'Full license texts'**
  String get thirdPartyLicenses;

  /// No description provided for @builtWithClaude.
  ///
  /// In en, this message translates to:
  /// **'Developed with the help of Claude Code.'**
  String get builtWithClaude;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report a problem on GitHub'**
  String get reportIssue;

  /// No description provided for @designInspiration.
  ///
  /// In en, this message translates to:
  /// **'Design inspiration'**
  String get designInspiration;

  /// No description provided for @dartPackagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Licenses: Dart packages'**
  String get dartPackagesLabel;

  /// No description provided for @systemLibrariesLabel.
  ///
  /// In en, this message translates to:
  /// **'Licenses: system libraries'**
  String get systemLibrariesLabel;

  /// No description provided for @interfaceAssetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Licenses: icons'**
  String get interfaceAssetsLabel;

  /// No description provided for @keepLogs.
  ///
  /// In en, this message translates to:
  /// **'Write logs'**
  String get keepLogs;

  /// No description provided for @keepLogsHint.
  ///
  /// In en, this message translates to:
  /// **'To investigate a problem. They include song names and paths, and stay on this computer.'**
  String get keepLogsHint;

  /// No description provided for @aboutSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get aboutSupport;

  /// No description provided for @openDataFolder.
  ///
  /// In en, this message translates to:
  /// **'Open the data folder'**
  String get openDataFolder;

  /// No description provided for @copySupportInfo.
  ///
  /// In en, this message translates to:
  /// **'Copy information for support'**
  String get copySupportInfo;

  /// No description provided for @supportInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get supportInfoCopied;

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to “{name}”'**
  String addedToPlaylist(String name);

  /// No description provided for @addTracks.
  ///
  /// In en, this message translates to:
  /// **'Add songs'**
  String get addTracks;

  /// No description provided for @addTracksConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add {n}'**
  String addTracksConfirm(int n);

  /// No description provided for @alreadyInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Already in this playlist'**
  String get alreadyInPlaylist;

  /// No description provided for @searchTracksHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs'**
  String get searchTracksHint;

  /// No description provided for @playlistEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'This playlist is empty. Use Add songs to fill it.'**
  String get playlistEmptyHint;

  /// No description provided for @tracksAdded.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 song added} other{{n} songs added}}'**
  String tracksAdded(int n);

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @yourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your library'**
  String get yourLibrary;

  /// No description provided for @rediscover.
  ///
  /// In en, this message translates to:
  /// **'Rediscover'**
  String get rediscover;

  /// No description provided for @yourPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Your playlists'**
  String get yourPlaylists;

  /// No description provided for @filterList.
  ///
  /// In en, this message translates to:
  /// **'Search in this list'**
  String get filterList;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// No description provided for @clearRecent.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearRecent;

  /// No description provided for @removeRecent.
  ///
  /// In en, this message translates to:
  /// **'Remove from recent searches'**
  String get removeRecent;

  /// No description provided for @browseGenres.
  ///
  /// In en, this message translates to:
  /// **'Browse by genre'**
  String get browseGenres;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @pinnedHeading.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinnedHeading;

  /// No description provided for @yourMixes.
  ///
  /// In en, this message translates to:
  /// **'Your mixes'**
  String get yourMixes;

  /// No description provided for @dailyMix.
  ///
  /// In en, this message translates to:
  /// **'Mix of the day'**
  String get dailyMix;

  /// No description provided for @genreMix.
  ///
  /// In en, this message translates to:
  /// **'{genre} mix'**
  String genreMix(String genre);

  /// No description provided for @openTrackPage.
  ///
  /// In en, this message translates to:
  /// **'Open the song page'**
  String get openTrackPage;

  /// No description provided for @trackDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get trackDetails;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @singles.
  ///
  /// In en, this message translates to:
  /// **'Single tracks'**
  String get singles;

  /// No description provided for @singlesHint.
  ///
  /// In en, this message translates to:
  /// **'{tracks} that are alone in their album'**
  String singlesHint(String tracks);

  /// No description provided for @expandRail.
  ///
  /// In en, this message translates to:
  /// **'Show names'**
  String get expandRail;

  /// No description provided for @collapseRail.
  ///
  /// In en, this message translates to:
  /// **'Hide names'**
  String get collapseRail;

  /// No description provided for @playerSize.
  ///
  /// In en, this message translates to:
  /// **'Player size'**
  String get playerSize;

  /// No description provided for @modeFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get modeFull;

  /// No description provided for @modeCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get modeCompact;

  /// No description provided for @modeMini.
  ///
  /// In en, this message translates to:
  /// **'Mini player'**
  String get modeMini;

  /// No description provided for @exitMini.
  ///
  /// In en, this message translates to:
  /// **'Leave the mini player'**
  String get exitMini;

  /// No description provided for @autoTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get autoTopRated;

  /// No description provided for @rateTrack.
  ///
  /// In en, this message translates to:
  /// **'Rate…'**
  String get rateTrack;

  /// No description provided for @ratingStars.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String ratingStars(int count);

  /// No description provided for @clearRating.
  ///
  /// In en, this message translates to:
  /// **'Remove the rating'**
  String get clearRating;

  /// No description provided for @dynamicMixStart.
  ///
  /// In en, this message translates to:
  /// **'Start dynamic mix'**
  String get dynamicMixStart;

  /// No description provided for @dynamicMixStop.
  ///
  /// In en, this message translates to:
  /// **'Stop dynamic mix'**
  String get dynamicMixStop;

  /// No description provided for @columnRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get columnRating;

  /// No description provided for @useRatings.
  ///
  /// In en, this message translates to:
  /// **'Use star ratings'**
  String get useRatings;

  /// No description provided for @useRatingsHint.
  ///
  /// In en, this message translates to:
  /// **'Shows stars next to the heart. Turned off, the ratings you gave stay saved, and songs with one star stay out of the mixes.'**
  String get useRatingsHint;
}

class _PlayerLocalizationsDelegate
    extends LocalizationsDelegate<PlayerLocalizations> {
  const _PlayerLocalizationsDelegate();

  @override
  Future<PlayerLocalizations> load(Locale locale) {
    return SynchronousFuture<PlayerLocalizations>(
      lookupPlayerLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_PlayerLocalizationsDelegate old) => false;
}

PlayerLocalizations lookupPlayerLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return PlayerLocalizationsEn();
    case 'pt':
      return PlayerLocalizationsPt();
  }

  throw FlutterError(
    'PlayerLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
