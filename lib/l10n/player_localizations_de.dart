// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'player_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class PlayerLocalizationsDe extends PlayerLocalizations {
  PlayerLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Musikplayer';

  @override
  String get noTrack => 'Kein Titel';

  @override
  String get play => 'Abspielen';

  @override
  String get pause => 'Pause';

  @override
  String get progress => 'Fortschritt';

  @override
  String get volume => 'Lautstärke';

  @override
  String get home => 'Start';

  @override
  String get library => 'Mediathek';

  @override
  String get playlists => 'Playlists';

  @override
  String get folders => 'Ordner';

  @override
  String get search => 'Suchen';

  @override
  String get settings => 'Einstellungen';

  @override
  String engineUnavailable(Object error) {
    return 'Die Audio-Engine ist nicht verfügbar: $error';
  }

  @override
  String get openFailed => 'Diese Datei konnte nicht abgespielt werden';

  @override
  String get addFolder => 'Ordner hinzufügen';

  @override
  String get addMusicFolder => 'Musikordner hinzufügen';

  @override
  String get folderNotVisible =>
      'Der Player kann diesen Ordner nicht sehen. Wähle einen aus deinem Benutzerordner oder von einem externen Laufwerk.';

  @override
  String get folderAlreadyAdded =>
      'Dieser Ordner ist bereits in der Mediathek.';

  @override
  String libraryUnavailable(String error) {
    return 'Die Mediathek konnte nicht geöffnet werden: $error';
  }

  @override
  String get albums => 'Alben';

  @override
  String get unknownArtist => 'Unbekannter Künstler';

  @override
  String playAlbum(String album) {
    return '$album abspielen';
  }

  @override
  String get hasLyrics => 'Hat Liedtext';

  @override
  String get moreOptions => 'Weitere Optionen';

  @override
  String get playNext => 'Als Nächstes abspielen';

  @override
  String get addToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String get removeFromQueue => 'Aus der Warteschlange entfernen';

  @override
  String get queue => 'Warteschlange';

  @override
  String get queueEmpty => 'Die Warteschlange ist leer';

  @override
  String get close => 'Schließen';

  @override
  String get shuffle => 'Zufallswiedergabe';

  @override
  String get previousTrack => 'Vorheriger Titel';

  @override
  String get nextTrack => 'Nächster Titel';

  @override
  String get repeatOff => 'Wiederholen: aus';

  @override
  String get repeatAll => 'Wiederholen: alle';

  @override
  String get repeatOne => 'Wiederholen: einer';

  @override
  String get continueListening => 'Dort weitermachen, wo du aufgehört hast';

  @override
  String get continuePlaying => 'Fortsetzen';

  @override
  String stoppedAt(String artist, String position, String duration) {
    return '$artist · angehalten bei $position von $duration';
  }

  @override
  String get shuffleAll => 'Alles zufällig abspielen';

  @override
  String get recentlyAdded => 'Kürzlich hinzugefügt';

  @override
  String get seeAll => 'Alle anzeigen';

  @override
  String get mostPlayed => 'Am häufigsten gehört';

  @override
  String get emptyTitle => 'Deine Mediathek ist leer';

  @override
  String get emptyBody =>
      'Gib den Ordner an, in dem deine Musik liegt. Der Player liest die Dateien direkt von deinem Computer und sendet nichts nach außen.';

  @override
  String useFolder(String folder) {
    return '$folder verwenden';
  }

  @override
  String get acceptedFormats => 'Unterstützte Formate';

  @override
  String get scanning => 'Deine Mediathek wird gelesen';

  @override
  String get scanSubtitle =>
      'Wird gelesen: Was schon gefunden wurde, kannst du bereits hören';

  @override
  String scanFiles(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString von $totalString Dateien';
  }

  @override
  String get scanLessThanMinute => 'noch weniger als eine Minute';

  @override
  String scanMinutesLeft(int n) {
    return 'noch etwa $n Min.';
  }

  @override
  String get pauseScan => 'Anhalten';

  @override
  String get resumeScan => 'Fortsetzen';

  @override
  String get cancelScan => 'Abbrechen';

  @override
  String get scanKeepsGoing =>
      'Das Lesen läuft weiter, wenn du diese Ansicht verlässt';

  @override
  String get foundSoFar => 'Bisher gefunden';

  @override
  String get updateAll => 'Alle aktualisieren';

  @override
  String get updateFolder => 'Ordner aktualisieren';

  @override
  String get removeFolder => 'Aus der Mediathek entfernen';

  @override
  String get folderMissing => 'Laufwerk nicht gefunden';

  @override
  String get notScanned => 'Noch nicht gelesen';

  @override
  String get scannedJustNow => 'Gerade aktualisiert';

  @override
  String scannedMinutes(int n) {
    return 'Vor $n Min. aktualisiert';
  }

  @override
  String scannedHours(int n) {
    return 'Vor $n Std. aktualisiert';
  }

  @override
  String scannedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Vor $n Tagen aktualisiert',
      one: 'Gestern aktualisiert',
      zero: 'Heute aktualisiert',
    );
    return '$_temp0';
  }

  @override
  String lengthMinutes(int n) {
    return '$n Min.';
  }

  @override
  String lengthHours(int h, int m) {
    return '$h Std. $m Min.';
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
      other: '$nString Alben',
      one: '1 Album',
      zero: '0 Alben',
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
      other: '$nString Titel',
      one: '1 Titel',
      zero: '0 Titel',
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
      other: '$nString Ordner',
      one: '1 Ordner',
      zero: '0 Ordner',
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
      other: '$nString Cover gefunden',
      one: '1 Cover gefunden',
      zero: '0 Cover gefunden',
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
      other: '$nString Dateien übersprungen',
      one: '1 Datei übersprungen',
      zero: '0 Dateien übersprungen',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Zurück';

  @override
  String get songs => 'Titel';

  @override
  String get artists => 'Künstler';

  @override
  String get genres => 'Genres';

  @override
  String get allFilter => 'Alle';

  @override
  String get allSongs => 'Alle';

  @override
  String get favorites => 'Favoriten';

  @override
  String get mineFilter => 'Meine';

  @override
  String get automaticFilter => 'Automatisch';

  @override
  String get addFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get removeFavorite => 'Aus Favoriten entfernen';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get sortRecent => 'Neueste';

  @override
  String get sortAZ => 'A bis Z';

  @override
  String get sortArtist => 'Künstler';

  @override
  String get sortYear => 'Jahr';

  @override
  String get sortMostTracks => 'Meiste Titel';

  @override
  String get columnTitle => 'Titel';

  @override
  String get columnAlbum => 'Album';

  @override
  String get columnDuration => 'Dauer';

  @override
  String get columnFormat => 'Format';

  @override
  String get viewGrid => 'Raster';

  @override
  String get viewList => 'Liste';

  @override
  String get searchHint => 'Mediathek durchsuchen';

  @override
  String get searchSongsHint => 'Titel suchen';

  @override
  String get searchArtistsHint => 'Künstler suchen';

  @override
  String get searchGenresHint => 'Genres suchen';

  @override
  String get searchAlbumsHint => 'Alben suchen';

  @override
  String get searchFoldersHint => 'Ordner suchen';

  @override
  String get searchAllHint => 'Titel, Alben, Künstler oder Ordner';

  @override
  String get searchShortcut => 'Strg K';

  @override
  String get clearSearch => 'Suche löschen';

  @override
  String noResults(String query) {
    return 'Nichts gefunden für „$query“';
  }

  @override
  String get searchPrompt => 'Tippe, um deine Mediathek zu durchsuchen.';

  @override
  String get bestResult => 'Bester Treffer';

  @override
  String get playAll => 'Alle abspielen';

  @override
  String get kindArtist => 'Künstler';

  @override
  String get kindAlbum => 'Album';

  @override
  String get kindSong => 'Titel';

  @override
  String get nothingHere => 'Hier ist noch nichts.';

  @override
  String get noGenre => 'Kein Genre';

  @override
  String get fileUnavailable => 'Diese Datei ist gerade nicht verfügbar';

  @override
  String get nothingAvailable =>
      'Diese Titel sind nicht verfügbar. Ist das Laufwerk angeschlossen?';

  @override
  String get watchFolders => 'Ordner auf Änderungen überwachen';

  @override
  String get watchFoldersBody =>
      'Erkennt neue, geänderte und entfernte Dateien, während der Player geöffnet ist.';

  @override
  String get newPlaylist => 'Neue Playlist';

  @override
  String get importPlaylist => 'Playlist importieren';

  @override
  String get exportPlaylist => 'Playlist exportieren';

  @override
  String get skipTrack => 'In Listen überspringen';

  @override
  String get unskipTrack => 'Nicht mehr überspringen';

  @override
  String get skippedTrack => 'Wird in Listen übersprungen';

  @override
  String get skippedFilter => 'Übersprungen';

  @override
  String get duplicatesFilter => 'Duplikate';

  @override
  String get smartRuleField => 'Feld';

  @override
  String get smartRuleCompare => 'Vergleich';

  @override
  String get newSmartPlaylist => 'Intelligente Playlist';

  @override
  String get editSmartRules => 'Regeln bearbeiten';

  @override
  String get smartSuffix => 'intelligent';

  @override
  String get ruleGenre => 'Genre';

  @override
  String get ruleYear => 'Jahr';

  @override
  String get ruleRating => 'Bewertung';

  @override
  String get ruleIs => 'ist';

  @override
  String get ruleIsNot => 'ist nicht';

  @override
  String get ruleAtLeast => 'mindestens';

  @override
  String get ruleAtMost => 'höchstens';

  @override
  String get matchAllRules => 'Alle Regeln';

  @override
  String get matchAnyRule => 'Eine beliebige Regel';

  @override
  String get addRule => 'Regel hinzufügen';

  @override
  String get removeRule => 'Regel entfernen';

  @override
  String get smartOrder => 'Reihenfolge';

  @override
  String get orderTitle => 'Titel';

  @override
  String get orderRecent => 'Zuletzt hinzugefügt';

  @override
  String get orderRating => 'Beste Bewertung';

  @override
  String get orderYear => 'Neueste';

  @override
  String get smartLimit => 'Maximale Titelzahl';

  @override
  String get noLimit => 'Kein Limit';

  @override
  String get choosePlaylistCover => 'Cover auswählen';

  @override
  String get removePlaylistCover => 'Cover entfernen';

  @override
  String get coverUnreadable => 'Dieses Bild konnte nicht gelesen werden';

  @override
  String get renamePlaylist => 'Umbenennen';

  @override
  String get deletePlaylist => 'Playlist löschen';

  @override
  String deletePlaylistBody(String name) {
    return '„$name“ löschen? Die Musikdateien bleiben, wo sie sind.';
  }

  @override
  String get delete => 'Löschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get create => 'Erstellen';

  @override
  String get playlistName => 'Name der Playlist';

  @override
  String get addToPlaylist => 'Zu Playlist hinzufügen';

  @override
  String get removeFromPlaylist => 'Aus Playlist entfernen';

  @override
  String get moveUp => 'Nach oben';

  @override
  String get moveDown => 'Nach unten';

  @override
  String get dragToReorder => 'Zum Umsortieren ziehen';

  @override
  String get autoFavorites => 'Favoriten';

  @override
  String get autoMostPlayed => 'Am häufigsten gehört';

  @override
  String get autoRecent => 'Kürzlich hinzugefügt';

  @override
  String get automaticSuffix => 'automatisch';

  @override
  String exportFailed(String error) {
    return 'Die Datei konnte nicht geschrieben werden: $error';
  }

  @override
  String importFailed(String error) {
    return 'Die Datei konnte nicht gelesen werden: $error';
  }

  @override
  String lengthDays(int d, int h) {
    return '$d T. $h Std.';
  }

  @override
  String artistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Künstler',
      one: '1 Künstler',
    );
    return '$_temp0';
  }

  @override
  String genreCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Genres',
      one: '1 Genre',
    );
    return '$_temp0';
  }

  @override
  String playlistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Playlists',
      one: '1 Playlist',
    );
    return '$_temp0';
  }

  @override
  String fileCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Dateien',
      one: '1 Datei',
    );
    return '$_temp0';
  }

  @override
  String folderChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Änderungen',
      one: '1 Änderung',
    );
    return '$_temp0';
  }

  @override
  String imported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Titel importiert',
      one: '1 Titel importiert',
    );
    return '$_temp0';
  }

  @override
  String importedRemote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Netzwerkadressen übersprungen',
      one: '1 Netzwerkadresse übersprungen',
    );
    return '$_temp0';
  }

  @override
  String get lyricsTab => 'Liedtext';

  @override
  String get coverTab => 'Cover';

  @override
  String get noLyrics => 'Dieser Titel hat keinen Liedtext';

  @override
  String get lyricsSynced => 'synchronisiert';

  @override
  String get lyricsUnsynced => 'nicht synchronisiert';

  @override
  String get lyricsEmbedded => 'In den Tags';

  @override
  String get lyricsTiming => 'Zeitpunkt des Liedtexts anpassen';

  @override
  String get lyricsEarlier => 'Liedtext früher anzeigen';

  @override
  String get lyricsLater => 'Liedtext später anzeigen';

  @override
  String get lyricsResetTiming => 'Zeitpunkt zurücksetzen';

  @override
  String get withLyrics => 'Mit Liedtext';

  @override
  String get upNext => 'Als Nächstes';

  @override
  String get clearQueue => 'Leeren';

  @override
  String get saveAsPlaylist => 'Als Playlist speichern';

  @override
  String get detailAlbum => 'Album';

  @override
  String get detailGenre => 'Genre';

  @override
  String get detailFile => 'Datei';

  @override
  String get detailCover => 'Cover';

  @override
  String get detailFolder => 'Ordner';

  @override
  String get coverEmbedded => 'Eingebettet';

  @override
  String get coverGenerated => 'Erzeugt';

  @override
  String secondsOffset(String value) {
    return '$value s';
  }

  @override
  String playlistSaved(String name) {
    return 'Als „$name“ gespeichert';
  }

  @override
  String get settingsPlayback => 'Wiedergabe';

  @override
  String get settingsEqualizer => 'Equalizer';

  @override
  String get equalizerOn => 'Equalizer verwenden';

  @override
  String get equalizerHint =>
      'Senkt die Gesamtlautstärke etwas, um Platz für die angehobenen Bänder zu schaffen, damit der Klang nicht verzerrt.';

  @override
  String get equalizerPresets => 'Voreinstellungen';

  @override
  String get equalizerCustom => 'Benutzerdefiniert';

  @override
  String get equalizerFlat => 'Neutral';

  @override
  String get equalizerRock => 'Rock';

  @override
  String get equalizerPop => 'Pop';

  @override
  String get equalizerJazz => 'Jazz';

  @override
  String get equalizerClassical => 'Klassik';

  @override
  String get equalizerElectronic => 'Elektronisch';

  @override
  String get equalizerBass => 'Mehr Bass';

  @override
  String get equalizerTreble => 'Mehr Höhen';

  @override
  String get equalizerVocal => 'Gesang';

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
  String get settingsLibrary => 'Mediathek';

  @override
  String get settingsLyrics => 'Liedtexte';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsShortcuts => 'Tastenkürzel';

  @override
  String get settingsAbout => 'Über';

  @override
  String get rememberSession => 'Letzten Titel merken';

  @override
  String get rememberSessionHint =>
      'Öffnet die Warteschlange dort wieder, wo sie angehalten hat, pausiert.';

  @override
  String get playWholeList =>
      'Beim Auswählen eines Titels die ganze Liste abspielen';

  @override
  String get playWholeListHint =>
      'Wenn aus, wird nur der gewählte Titel abgespielt.';

  @override
  String get closeNote =>
      'Das Schließen des Fensters beendet den Player und stoppt die Musik.';

  @override
  String get stopAfterTrack => 'Nach diesem Titel anhalten';

  @override
  String get cancelStopAfter => 'Nach diesem Titel weiterspielen';

  @override
  String get showInFiles => 'Im Dateimanager anzeigen';

  @override
  String get keepAwake => 'Computer während der Wiedergabe wach halten';

  @override
  String get keepAwakeHint =>
      'Der Bildschirm bleibt an und der Computer geht nicht von selbst in den Ruhezustand. Bei Pause läuft alles wieder normal.';

  @override
  String get keepAwakeReason => 'Musik wird abgespielt';

  @override
  String get notifyTrack => 'Bei Titelwechsel benachrichtigen';

  @override
  String get notifyTrackHint =>
      'Zeigt Titel und Künstler in einer Systembenachrichtigung.';

  @override
  String get shuffleOrder => 'Reihenfolge mischen';

  @override
  String get playlistShuffled => 'Reihenfolge gemischt';

  @override
  String get removeDuplicates => 'Duplikate entfernen';

  @override
  String duplicatesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Duplikate entfernt',
      one: '1 Duplikat entfernt',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Rückgängig';

  @override
  String get gapless => 'Ohne Pausen zwischen Titeln abspielen';

  @override
  String get gaplessHint =>
      'Wenn aus, wird die Tonausgabe zwischen den Titeln geschlossen und wieder geöffnet.';

  @override
  String get crossfade => 'Überblenden';

  @override
  String get crossfadeOff => 'Aus';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get crossfadeHint =>
      'Titel überlappen beim Wechsel. Aufeinanderfolgende Titel desselben Albums bleiben lückenlos.';

  @override
  String get fadeOnPause => 'Sanft pausieren';

  @override
  String get fadeOnPauseHint =>
      'Der Ton wird beim Pausieren und Fortsetzen langsam leiser und wieder lauter.';

  @override
  String get replayGain => 'ReplayGain';

  @override
  String get replayGainOff => 'Aus';

  @override
  String get replayGainTrack => 'Titel';

  @override
  String get replayGainAlbum => 'Album';

  @override
  String get replayGainHint =>
      'Gleicht die Lautstärke anhand der Werte in den Tags der Datei an. Album erhält die Unterschiede innerhalb eines Albums. Dateien ohne diese Tags werden unverändert abgespielt.';

  @override
  String get libraryFolders => 'Ordner der Mediathek';

  @override
  String get watchFoldersSetting => 'Ordner auf Änderungen überwachen';

  @override
  String get watchFoldersHint =>
      'Neue, geänderte und entfernte Dateien erscheinen, während der Player geöffnet ist.';

  @override
  String get refreshOnOpen => 'Beim Öffnen aktualisieren';

  @override
  String get refreshOnOpenHint =>
      'Prüft die Ordner bei jedem Öffnen des Players.';

  @override
  String get refreshNow => 'Jetzt aktualisieren';

  @override
  String get lyricsFiles => 'Nach .lrc- und .srt-Dateien suchen';

  @override
  String get lyricsFilesHint => 'Neben der Musik, mit demselben Namen.';

  @override
  String get lyricsEmbeddedSetting => 'Eingebettete Liedtexte verwenden';

  @override
  String get lyricsEmbeddedHint =>
      'Aus den Tags der Datei, wenn es keine Liedtextdatei gibt.';

  @override
  String get themeSetting => 'Design';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeSystem => 'System';

  @override
  String get dynamicColor => 'Dynamische Systemfarbe';

  @override
  String get dynamicColorHint =>
      'Verwendet die Farben des Hintergrundbilds, wenn das System sie anbietet.';

  @override
  String get accentSetting => 'Akzentfarbe';

  @override
  String get accentDefault => 'Standard';

  @override
  String get accentCoral => 'Koralle';

  @override
  String get accentAmber => 'Bernstein';

  @override
  String get accentGreen => 'Grün';

  @override
  String get accentTeal => 'Blaugrün';

  @override
  String get accentBlue => 'Blau';

  @override
  String get accentPurple => 'Violett';

  @override
  String get densitySetting => 'Listendichte';

  @override
  String get densityComfortable => 'Bequem';

  @override
  String get densityCompact => 'Kompakt';

  @override
  String get textSizeSetting => 'Textgröße';

  @override
  String get reduceMotion => 'Animationen reduzieren';

  @override
  String get reduceMotionHint =>
      'Schaltet das Scrollen der Liedtexte und andere Animationen aus.';

  @override
  String get resetShortcuts => 'Standard wiederherstellen';

  @override
  String get mediaKeysNote =>
      'Die Medientasten der Tastatur (Abspielen, Pause, Weiter, Zurück) funktionieren ohne Einrichtung.';

  @override
  String get commandPlayPause => 'Abspielen und Pause';

  @override
  String get commandSeekBack => '5 Sekunden zurück';

  @override
  String get commandSeekForward => '5 Sekunden vor';

  @override
  String get commandPrevious => 'Vorheriger Titel';

  @override
  String get commandNext => 'Nächster Titel';

  @override
  String get commandMute => 'Stumm';

  @override
  String get commandSearch => 'Suchen';

  @override
  String get commandLyrics => 'Liedtext öffnen und schließen';

  @override
  String get commandQueue => 'Warteschlange öffnen und schließen';

  @override
  String get keySpace => 'Leertaste';

  @override
  String changeShortcut(String command) {
    return 'Tastenkürzel ändern: $command';
  }

  @override
  String get pressKeys => 'Drücke die neuen Tasten. Esc bricht ab.';

  @override
  String shortcutInUse(String command) {
    return 'Bereits belegt von: $command';
  }

  @override
  String get aboutDescription =>
      'Spielt die Dateien auf deinem Computer ab. Kein Konto, kein Streaming und kein Tracking: Was du hörst, bleibt bei dir.';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get licenseLabel => 'Lizenz: Apache 2.0';

  @override
  String get thirdPartyLicenses => 'Vollständige Lizenztexte';

  @override
  String get builtWithClaude => 'Mit Hilfe von Claude Code entwickelt.';

  @override
  String get reportIssue => 'Problem auf GitHub melden';

  @override
  String get designInspiration => 'Design-Inspiration';

  @override
  String get dartPackagesLabel => 'Lizenzen: Dart-Pakete';

  @override
  String get systemLibrariesLabel => 'Lizenzen: Systembibliotheken';

  @override
  String get interfaceAssetsLabel => 'Lizenzen: Symbole';

  @override
  String get keepLogs => 'Protokolle schreiben';

  @override
  String get keepLogsHint =>
      'Um ein Problem zu untersuchen. Sie enthalten Titelnamen und Pfade und bleiben auf diesem Computer.';

  @override
  String get aboutSupport => 'Support';

  @override
  String get openDataFolder => 'Datenordner öffnen';

  @override
  String get copySupportInfo => 'Informationen für den Support kopieren';

  @override
  String get supportInfoCopied => 'Kopiert';

  @override
  String addedToPlaylist(String name) {
    return 'Zu „$name“ hinzugefügt';
  }

  @override
  String get addTracks => 'Titel hinzufügen';

  @override
  String addTracksConfirm(int n) {
    return '$n hinzufügen';
  }

  @override
  String get alreadyInPlaylist => 'Bereits in dieser Playlist';

  @override
  String get searchTracksHint => 'Titel suchen';

  @override
  String get playlistEmptyHint =>
      'Diese Playlist ist leer. Fülle sie mit „Titel hinzufügen“.';

  @override
  String tracksAdded(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Titel hinzugefügt',
      one: '1 Titel hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String get nowPlaying => 'Aktuelle Wiedergabe';

  @override
  String get yourLibrary => 'Deine Mediathek';

  @override
  String get rediscover => 'Wiederentdecken';

  @override
  String get yourPlaylists => 'Deine Playlists';

  @override
  String get filterList => 'In dieser Liste suchen';

  @override
  String get recentSearches => 'Letzte Suchen';

  @override
  String get clearRecent => 'Löschen';

  @override
  String get removeRecent => 'Aus den letzten Suchen entfernen';

  @override
  String get browseGenres => 'Nach Genre stöbern';

  @override
  String get pin => 'Anheften';

  @override
  String get unpin => 'Lösen';

  @override
  String get pinned => 'Angeheftet';

  @override
  String get pinnedHeading => 'Angeheftet';

  @override
  String get yourMixes => 'Deine Mixe';

  @override
  String get dailyMix => 'Mix des Tages';

  @override
  String genreMix(String genre) {
    return '$genre-Mix';
  }

  @override
  String get openTrackPage => 'Titelseite öffnen';

  @override
  String get trackDetails => 'Details';

  @override
  String get overview => 'Übersicht';

  @override
  String get singles => 'Einzelne Titel';

  @override
  String singlesHint(String tracks) {
    return '$tracks, allein in ihrem Album';
  }

  @override
  String get expandRail => 'Namen anzeigen';

  @override
  String get collapseRail => 'Namen ausblenden';

  @override
  String get playerSize => 'Playergröße';

  @override
  String get modeFull => 'Voll';

  @override
  String get modeCompact => 'Kompakt';

  @override
  String get modeMini => 'Miniplayer';

  @override
  String get exitMini => 'Miniplayer verlassen';

  @override
  String get autoTopRated => 'Bestbewertet';

  @override
  String get rateTrack => 'Bewerten…';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne',
      one: '1 Stern',
    );
    return '$_temp0';
  }

  @override
  String get clearRating => 'Bewertung entfernen';

  @override
  String get dynamicMixStart => 'Dynamischen Mix starten';

  @override
  String get dynamicMixStop => 'Dynamischen Mix beenden';

  @override
  String get columnRating => 'Bewertung';

  @override
  String get useRatings => 'Sternebewertung verwenden';

  @override
  String get useRatingsHint =>
      'Zeigt Sterne neben dem Herz. Wenn aus, bleiben deine Bewertungen gespeichert, und Titel mit einem Stern bleiben aus den Mixen heraus.';

  @override
  String markAll(int n) {
    return 'Alle auswählen ($n)';
  }

  @override
  String get clearSelection => 'Auswahl aufheben';

  @override
  String createWithTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Mit $n Titeln erstellen',
      one: 'Mit 1 Titel erstellen',
    );
    return '$_temp0';
  }

  @override
  String get tagEditMenu => 'Tags bearbeiten…';

  @override
  String get tagEditAlbumMenu => 'Album bearbeiten…';

  @override
  String get tagEditTitle => 'Tags bearbeiten';

  @override
  String get tagEditAlbumTitle => 'Album bearbeiten';

  @override
  String get tagsReadOnlyTitle => 'Tags';

  @override
  String get tagDetails => 'Details';

  @override
  String get tagTitle => 'Titel';

  @override
  String get tagArtist => 'Interpret';

  @override
  String get tagAlbum => 'Album';

  @override
  String get tagAlbumArtist => 'Album-Interpret';

  @override
  String get tagYear => 'Jahr';

  @override
  String get tagGenre => 'Genre';

  @override
  String get tagComposer => 'Komponist';

  @override
  String get tagComment => 'Kommentar';

  @override
  String get tagTrack => 'Titel-Nr.';

  @override
  String get tagDisc => 'CD';

  @override
  String get tagTrackNumber => 'Titelnummer';

  @override
  String get tagTrackTotal => 'Titel gesamt';

  @override
  String get tagDiscNumber => 'CD-Nummer';

  @override
  String get tagDiscTotal => 'CDs gesamt';

  @override
  String get tagPairOf => 'von';

  @override
  String get tagChanged => 'geändert';

  @override
  String tagChangedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Felder geändert',
      one: '$n Feld geändert',
    );
    return '$_temp0';
  }

  @override
  String tagPosition(int index, int total) {
    return '$index von $total';
  }

  @override
  String get tagPreviousTrack => 'Vorheriger Titel';

  @override
  String get tagNextTrack => 'Nächster Titel';

  @override
  String get tagSaveChangesTitle => 'Änderungen an diesem Titel speichern?';

  @override
  String tagSaveChangesBody(String fields, String title) {
    return 'Du hast $fields bei $title geändert. Speichere oder verwirf diese Änderungen zuerst.';
  }

  @override
  String get tagDiscard => 'Verwerfen';

  @override
  String get tagDiscardBatchTitle => 'Änderungen verwerfen?';

  @override
  String get tagSaveAndNext => 'Speichern und weiter';

  @override
  String get tagSaveAndPrevious => 'Speichern und zurück';

  @override
  String get tagSaveAndClose => 'Speichern und schließen';

  @override
  String get tagLyricsFileNote =>
      'Das ändert den Liedtext in der Musikdatei. Die Liedtextdatei daneben bleibt unverändert und hat weiter Vorrang.';

  @override
  String get tagCoverCurrent => 'Aktuelles Cover';

  @override
  String get tagCoverNew => 'Neu';

  @override
  String get tagCoverBefore => 'Vorher';

  @override
  String get tagCoverChange => 'Bild ändern';

  @override
  String tagCoverFromFolder(String name) {
    return 'Cover des Ordners verwenden ($name)';
  }

  @override
  String get tagCoverRemove => 'Eingebettetes Cover entfernen';

  @override
  String get tagCoverKeep => 'Die der Datei behalten';

  @override
  String get tagCoverChoose => 'Cover auswählen';

  @override
  String tagReadOnlyFormat(String format) {
    return '$format-Dateien können noch nicht bearbeitet werden. Die Tags werden nur angezeigt.';
  }

  @override
  String get tagReadOnlyDisk =>
      'Diese Datei liegt auf einem schreibgeschützten Datenträger. Binde ihn zum Bearbeiten beschreibbar ein.';

  @override
  String get tagReadOnlyPermission => 'Du darfst diese Datei nicht ändern.';

  @override
  String get tagReadOnlyMissing => 'Diese Datei ist gerade nicht verfügbar.';

  @override
  String get tagVariousValues => 'Verschiedene Werte';

  @override
  String get tagBatchNote =>
      'Nur was du änderst, wird geschrieben; der Rest bleibt. Titel und Titelnummer sind ausgenommen, weil jeder Titel eigene hat.';

  @override
  String get tagKeepField => 'Dieses Feld behalten';

  @override
  String tagEraseField(int count, String label) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$label bei allen $count Titeln löschen',
      one: '$label bei $count Titel löschen',
    );
    return '$_temp0';
  }

  @override
  String tagWillErase(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Wird bei $n Titeln gelöscht',
      one: 'Wird bei $n Titel gelöscht',
    );
    return '$_temp0';
  }

  @override
  String tagArtistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Interpreten',
      one: '$n Interpret',
    );
    return '$_temp0';
  }

  @override
  String tagBatchSkipped(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Dateien können nicht bearbeitet werden und bleiben außen vor.',
      one: '$n Datei kann nicht bearbeitet werden und bleibt außen vor.',
    );
    return '$_temp0';
  }

  @override
  String tagBatchSummary(int fields, int files) {
    return 'Geänderte Felder: $fields · Dateien: $files';
  }

  @override
  String tagSaveIn(int n) {
    return 'In $n speichern';
  }

  @override
  String get tagAlbumFields => 'Albumdaten und Cover';

  @override
  String get tagColumnNumber => 'Nr.';

  @override
  String get tagNumberInOrder => 'Der Reihe nach nummerieren';

  @override
  String get tagTitleFromFile => 'Titel aus Dateiname';

  @override
  String get tagAlbumDragHint =>
      'Am Griff ziehen oder im Zeilenmenü nach oben und unten verschieben. Nummerieren vergibt 1, 2, 3… in Tabellenreihenfolge.';

  @override
  String tagFilesToWrite(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Dateien werden geschrieben',
      one: '$n Datei wird geschrieben',
    );
    return '$_temp0';
  }

  @override
  String tagsWriting(int done, int total) {
    return 'Schreibe $done von $total';
  }

  @override
  String get tagsHideProgress => 'Ausblenden; das Schreiben läuft weiter';

  @override
  String tagsWritten(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tags in $n Dateien geschrieben',
      one: 'Tags in $n Datei geschrieben',
    );
    return '$_temp0';
  }

  @override
  String tagsPartly(int ok, int failed) {
    return '$ok geschrieben, $failed nicht';
  }

  @override
  String get tagFailuresDetails => 'Details';

  @override
  String tagsRestored(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tags in $n Dateien wiederhergestellt',
      one: 'Tags in $n Datei wiederhergestellt',
    );
    return '$_temp0';
  }

  @override
  String tagsPartlyRestored(int ok, int failed) {
    return '$ok wiederhergestellt, $failed seitdem geändert';
  }

  @override
  String tagFailuresTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Dateien wurden nicht geschrieben',
      one: '$n Datei wurde nicht geschrieben',
    );
    return '$_temp0';
  }

  @override
  String tagFailureFormat(String format) {
    return '$format-Dateien können noch nicht bearbeitet werden';
  }

  @override
  String get tagFailureReadOnly => 'Der Datenträger ist schreibgeschützt';

  @override
  String get tagFailurePermission => 'Keine Berechtigung, die Datei zu ändern';

  @override
  String get tagFailureMissing => 'Datei oder Datenträger ist nicht mehr da';

  @override
  String get tagFailureInUse =>
      'Ein anderes Programm verwendet die Datei. Wechsle den Titel oder schließe es und versuche es erneut';

  @override
  String get tagFailureNoSpace => 'Nicht genug Speicherplatz';

  @override
  String get tagFailureChanged => 'Die Datei wurde seitdem geändert';

  @override
  String get tagFailureDamaged =>
      'Die Dateistruktur ließ sich nicht sicher schreiben; die Datei bleibt unverändert';

  @override
  String get selectionAdd => 'Auswählen';

  @override
  String get selectionRemove => 'Abwählen';

  @override
  String get selectionClear => 'Auswahl aufheben';

  @override
  String selectionCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ausgewählt',
      one: '$n ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get tagColumnFile => 'Datei';

  @override
  String get organizeMenu => 'Dateien ordnen…';

  @override
  String get organizeCopyMenu => 'In einen Ordner kopieren…';

  @override
  String get organizeTitle => 'Dateien ordnen';

  @override
  String get organizeCopyTitle => 'In einen Ordner kopieren';

  @override
  String get organizeAction => 'Ordnen';

  @override
  String get organizeCopyAction => 'Kopieren';

  @override
  String get organizePattern => 'Namensmuster';

  @override
  String get organizePatternInvalid =>
      'Nutze die Schaltflächen unten; das Muster braucht den Titel';

  @override
  String get organizeUnknown => 'Unbekannt';

  @override
  String get organizeChooseFolder => 'Ordner wählen';

  @override
  String get organizeNoFolder => 'Wähle das Ziel';

  @override
  String organizeFreeSpace(String free, String needed) {
    return '$free frei · $needed zu kopieren';
  }

  @override
  String get organizeNothing => 'Nichts zu tun: Alles ist schon am Platz.';

  @override
  String get organizeBusy => 'Warte, bis die Bibliothek gelesen ist.';

  @override
  String get organizeSameTarget => 'Gleicher Name wie andere';

  @override
  String get organizeTargetExists => 'Eine Datei heißt schon so';

  @override
  String get organizePlaying => 'Wird gerade gespielt';

  @override
  String get organizeNoSpace => 'Passt nicht';

  @override
  String organizeWillMove(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Dateien werden verschoben',
      one: '$n Datei wird verschoben',
    );
    return '$_temp0';
  }

  @override
  String organizeWillCopy(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Dateien werden kopiert',
      one: '$n Datei wird kopiert',
    );
    return '$_temp0';
  }

  @override
  String organizeUnchanged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n schon am Platz',
      one: '$n schon am Platz',
    );
    return '$_temp0';
  }

  @override
  String organizeProblems(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mit Problem',
      one: '$n mit Problem',
    );
    return '$_temp0';
  }

  @override
  String organizeMoving(int done, int total) {
    return 'Verschiebe $done von $total';
  }

  @override
  String organizeCopying(int done, int total) {
    return 'Kopiere $done von $total';
  }

  @override
  String organizeMoved(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Dateien verschoben',
      one: '$n Datei verschoben',
    );
    return '$_temp0';
  }

  @override
  String organizeCopied(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Dateien kopiert',
      one: '$n Datei kopiert',
    );
    return '$_temp0';
  }

  @override
  String organizeRestored(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Dateien wieder am Platz',
      one: '$n Datei wieder am Platz',
    );
    return '$_temp0';
  }

  @override
  String get tagCueReadOnly =>
      'Titel aus einem Cue-Sheet lassen sich hier nicht bearbeiten.';
}
