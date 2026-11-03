// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'player_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class PlayerLocalizationsFr extends PlayerLocalizations {
  PlayerLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Lecteur de musique';

  @override
  String get noTrack => 'Aucun morceau';

  @override
  String get play => 'Lire';

  @override
  String get pause => 'Pause';

  @override
  String get progress => 'Progression';

  @override
  String get volume => 'Volume';

  @override
  String get home => 'Accueil';

  @override
  String get library => 'Bibliothèque';

  @override
  String get playlists => 'Playlists';

  @override
  String get folders => 'Dossiers';

  @override
  String get search => 'Rechercher';

  @override
  String get settings => 'Réglages';

  @override
  String engineUnavailable(Object error) {
    return 'Le moteur audio n’est pas disponible : $error';
  }

  @override
  String get openFailed => 'Impossible de lire ce fichier';

  @override
  String get addFolder => 'Ajouter un dossier';

  @override
  String get addMusicFolder => 'Ajouter un dossier de musique';

  @override
  String get folderNotVisible =>
      'Le lecteur ne voit pas ce dossier. Choisissez-en un dans votre dossier personnel ou sur un disque externe.';

  @override
  String get folderAlreadyAdded => 'Ce dossier est déjà dans la bibliothèque.';

  @override
  String libraryUnavailable(String error) {
    return 'Impossible d’ouvrir la bibliothèque : $error';
  }

  @override
  String get albums => 'Albums';

  @override
  String get unknownArtist => 'Artiste inconnu';

  @override
  String playAlbum(String album) {
    return 'Lire $album';
  }

  @override
  String get hasLyrics => 'Avec paroles';

  @override
  String get moreOptions => 'Plus d’options';

  @override
  String get playNext => 'Lire ensuite';

  @override
  String get addToQueue => 'Ajouter à la file';

  @override
  String get removeFromQueue => 'Retirer de la file';

  @override
  String get queue => 'File d’attente';

  @override
  String get queueEmpty => 'La file d’attente est vide';

  @override
  String get close => 'Fermer';

  @override
  String get shuffle => 'Lecture aléatoire';

  @override
  String get previousTrack => 'Morceau précédent';

  @override
  String get nextTrack => 'Morceau suivant';

  @override
  String get repeatOff => 'Répéter : non';

  @override
  String get repeatAll => 'Répéter : tout';

  @override
  String get repeatOne => 'Répéter : un';

  @override
  String get continueListening => 'Reprenez là où vous vous êtes arrêté';

  @override
  String get continuePlaying => 'Reprendre';

  @override
  String stoppedAt(String artist, String position, String duration) {
    return '$artist · arrêté à $position sur $duration';
  }

  @override
  String get shuffleAll => 'Tout lire au hasard';

  @override
  String get recentlyAdded => 'Ajouts récents';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get mostPlayed => 'Les plus écoutés';

  @override
  String get emptyTitle => 'Votre bibliothèque est vide';

  @override
  String get emptyBody =>
      'Indiquez le dossier où se trouve votre musique. Le lecteur lit les fichiers directement sur votre ordinateur et n’envoie rien à l’extérieur.';

  @override
  String useFolder(String folder) {
    return 'Utiliser $folder';
  }

  @override
  String get acceptedFormats => 'Formats acceptés';

  @override
  String get scanning => 'Lecture de votre bibliothèque';

  @override
  String get scanSubtitle =>
      'Lecture en cours : vous pouvez déjà écouter ce qui a été trouvé';

  @override
  String scanFiles(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString fichiers sur $totalString';
  }

  @override
  String get scanLessThanMinute => 'moins d’une minute restante';

  @override
  String scanMinutesLeft(int n) {
    return 'environ $n min restantes';
  }

  @override
  String get pauseScan => 'Suspendre';

  @override
  String get resumeScan => 'Reprendre';

  @override
  String get cancelScan => 'Annuler';

  @override
  String get scanKeepsGoing => 'La lecture continue si vous quittez cet écran';

  @override
  String get foundSoFar => 'Trouvé jusqu’ici';

  @override
  String get updateAll => 'Tout mettre à jour';

  @override
  String get updateFolder => 'Mettre à jour le dossier';

  @override
  String get removeFolder => 'Retirer de la bibliothèque';

  @override
  String get folderMissing => 'Disque introuvable';

  @override
  String get notScanned => 'Pas encore lu';

  @override
  String get scannedJustNow => 'Mis à jour à l’instant';

  @override
  String scannedMinutes(int n) {
    return 'Mis à jour il y a $n min';
  }

  @override
  String scannedHours(int n) {
    return 'Mis à jour il y a $n h';
  }

  @override
  String scannedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Mis à jour il y a $n jours',
      one: 'Mis à jour hier',
      zero: 'Mis à jour aujourd’hui',
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
      zero: '0 album',
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
      other: '$nString morceaux',
      one: '1 morceau',
      zero: '0 morceau',
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
      other: '$nString dossiers',
      one: '1 dossier',
      zero: '0 dossier',
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
      other: '$nString pochettes trouvées',
      one: '1 pochette trouvée',
      zero: '0 pochette trouvée',
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
      other: '$nString fichiers ignorés',
      one: '1 fichier ignoré',
      zero: '0 fichier ignoré',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Retour';

  @override
  String get songs => 'Morceaux';

  @override
  String get artists => 'Artistes';

  @override
  String get genres => 'Genres';

  @override
  String get allFilter => 'Tout';

  @override
  String get allSongs => 'Tous';

  @override
  String get favorites => 'Favoris';

  @override
  String get mineFilter => 'Les miennes';

  @override
  String get automaticFilter => 'Automatiques';

  @override
  String get addFavorite => 'Ajouter aux favoris';

  @override
  String get removeFavorite => 'Retirer des favoris';

  @override
  String get sortBy => 'Trier par';

  @override
  String get sortRecent => 'Récents';

  @override
  String get sortAZ => 'De A à Z';

  @override
  String get sortArtist => 'Artiste';

  @override
  String get sortYear => 'Année';

  @override
  String get sortMostTracks => 'Le plus de morceaux';

  @override
  String get columnTitle => 'Titre';

  @override
  String get columnAlbum => 'Album';

  @override
  String get columnDuration => 'Durée';

  @override
  String get columnFormat => 'Format';

  @override
  String get viewGrid => 'Grille';

  @override
  String get viewList => 'Liste';

  @override
  String get searchHint => 'Rechercher dans la bibliothèque';

  @override
  String get searchSongsHint => 'Rechercher des morceaux';

  @override
  String get searchArtistsHint => 'Rechercher des artistes';

  @override
  String get searchGenresHint => 'Rechercher des genres';

  @override
  String get searchAlbumsHint => 'Rechercher des albums';

  @override
  String get searchFoldersHint => 'Rechercher des dossiers';

  @override
  String get searchAllHint => 'Morceaux, albums, artistes ou dossiers';

  @override
  String get searchShortcut => 'Ctrl K';

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String noResults(String query) {
    return 'Rien trouvé pour « $query »';
  }

  @override
  String get searchPrompt =>
      'Saisissez du texte pour chercher dans votre bibliothèque.';

  @override
  String get bestResult => 'Meilleur résultat';

  @override
  String get playAll => 'Tout lire';

  @override
  String get kindArtist => 'Artiste';

  @override
  String get kindAlbum => 'Album';

  @override
  String get kindSong => 'Morceau';

  @override
  String get nothingHere => 'Rien ici pour l’instant.';

  @override
  String get noGenre => 'Sans genre';

  @override
  String get fileUnavailable =>
      'Ce fichier n’est pas disponible pour le moment';

  @override
  String get nothingAvailable =>
      'Ces morceaux ne sont pas disponibles. Le disque est-il connecté ?';

  @override
  String get watchFolders => 'Surveiller les changements dans les dossiers';

  @override
  String get watchFoldersBody =>
      'Détecte les fichiers nouveaux, modifiés et supprimés pendant que le lecteur est ouvert.';

  @override
  String get newPlaylist => 'Nouvelle playlist';

  @override
  String get importPlaylist => 'Importer une playlist';

  @override
  String get exportPlaylist => 'Exporter la playlist';

  @override
  String get smartRuleField => 'Champ';

  @override
  String get smartRuleCompare => 'Comparaison';

  @override
  String get newSmartPlaylist => 'Playlist intelligente';

  @override
  String get editSmartRules => 'Modifier les règles';

  @override
  String get smartSuffix => 'intelligente';

  @override
  String get ruleGenre => 'Genre';

  @override
  String get ruleYear => 'Année';

  @override
  String get ruleRating => 'Note';

  @override
  String get ruleIs => 'est';

  @override
  String get ruleIsNot => 'n’est pas';

  @override
  String get ruleAtLeast => 'au moins';

  @override
  String get ruleAtMost => 'au plus';

  @override
  String get matchAllRules => 'Toutes les règles';

  @override
  String get matchAnyRule => 'N’importe quelle règle';

  @override
  String get addRule => 'Ajouter une règle';

  @override
  String get removeRule => 'Retirer la règle';

  @override
  String get smartOrder => 'Ordre';

  @override
  String get orderTitle => 'Titre';

  @override
  String get orderRecent => 'Ajoutés récemment';

  @override
  String get orderRating => 'Mieux notés';

  @override
  String get orderYear => 'Plus récents';

  @override
  String get smartLimit => 'Nombre maximal de morceaux';

  @override
  String get noLimit => 'Sans limite';

  @override
  String get choosePlaylistCover => 'Choisir une pochette';

  @override
  String get removePlaylistCover => 'Retirer la pochette';

  @override
  String get coverUnreadable => 'Impossible de lire cette image';

  @override
  String get renamePlaylist => 'Renommer';

  @override
  String get deletePlaylist => 'Supprimer la playlist';

  @override
  String deletePlaylistBody(String name) {
    return 'Supprimer « $name » ? Les fichiers de musique restent à leur place.';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get create => 'Créer';

  @override
  String get playlistName => 'Nom de la playlist';

  @override
  String get addToPlaylist => 'Ajouter à une playlist';

  @override
  String get removeFromPlaylist => 'Retirer de la playlist';

  @override
  String get moveUp => 'Monter';

  @override
  String get moveDown => 'Descendre';

  @override
  String get dragToReorder => 'Glisser pour réordonner';

  @override
  String get autoFavorites => 'Favoris';

  @override
  String get autoMostPlayed => 'Les plus écoutés';

  @override
  String get autoRecent => 'Ajouts récents';

  @override
  String get automaticSuffix => 'automatique';

  @override
  String exportFailed(String error) {
    return 'Impossible d’écrire le fichier : $error';
  }

  @override
  String importFailed(String error) {
    return 'Impossible de lire le fichier : $error';
  }

  @override
  String lengthDays(int d, int h) {
    return '$d j $h h';
  }

  @override
  String artistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n artistes',
      one: '1 artiste',
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
      other: '$n fichiers',
      one: '1 fichier',
    );
    return '$_temp0';
  }

  @override
  String folderChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n changements',
      one: '1 changement',
    );
    return '$_temp0';
  }

  @override
  String imported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n morceaux importés',
      one: '1 morceau importé',
    );
    return '$_temp0';
  }

  @override
  String importedRemote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n adresses réseau ignorées',
      one: '1 adresse réseau ignorée',
    );
    return '$_temp0';
  }

  @override
  String get lyricsTab => 'Paroles';

  @override
  String get coverTab => 'Pochette';

  @override
  String get noLyrics => 'Ce morceau n’a pas de paroles';

  @override
  String get lyricsSynced => 'synchronisées';

  @override
  String get lyricsUnsynced => 'non synchronisées';

  @override
  String get lyricsEmbedded => 'Dans les tags';

  @override
  String get lyricsTiming => 'Ajuster le décalage des paroles';

  @override
  String get lyricsEarlier => 'Afficher les paroles plus tôt';

  @override
  String get lyricsLater => 'Afficher les paroles plus tard';

  @override
  String get lyricsResetTiming => 'Réinitialiser le décalage';

  @override
  String get withLyrics => 'Avec paroles';

  @override
  String get upNext => 'À suivre';

  @override
  String get clearQueue => 'Vider';

  @override
  String get saveAsPlaylist => 'Enregistrer comme playlist';

  @override
  String get detailAlbum => 'Album';

  @override
  String get detailGenre => 'Genre';

  @override
  String get detailFile => 'Fichier';

  @override
  String get detailCover => 'Pochette';

  @override
  String get detailFolder => 'Dossier';

  @override
  String get coverEmbedded => 'Intégrée';

  @override
  String get coverGenerated => 'Générée';

  @override
  String secondsOffset(String value) {
    return '$value s';
  }

  @override
  String playlistSaved(String name) {
    return 'Enregistrée sous « $name »';
  }

  @override
  String get settingsPlayback => 'Lecture';

  @override
  String get settingsEqualizer => 'Égaliseur';

  @override
  String get equalizerOn => 'Utiliser l’égaliseur';

  @override
  String get equalizerHint =>
      'Baisse un peu le volume général pour laisser de la place aux bandes renforcées, afin que le son ne sature pas.';

  @override
  String get equalizerPresets => 'Préréglages';

  @override
  String get equalizerCustom => 'Personnalisé';

  @override
  String get equalizerFlat => 'Neutre';

  @override
  String get equalizerRock => 'Rock';

  @override
  String get equalizerPop => 'Pop';

  @override
  String get equalizerJazz => 'Jazz';

  @override
  String get equalizerClassical => 'Classique';

  @override
  String get equalizerElectronic => 'Électronique';

  @override
  String get equalizerBass => 'Plus de graves';

  @override
  String get equalizerTreble => 'Plus d’aigus';

  @override
  String get equalizerVocal => 'Voix';

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
  String get settingsLibrary => 'Bibliothèque';

  @override
  String get settingsLyrics => 'Paroles';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsShortcuts => 'Raccourcis clavier';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get rememberSession => 'Se souvenir du dernier morceau';

  @override
  String get rememberSessionHint =>
      'Rouvre la file là où elle s’est arrêtée, en pause.';

  @override
  String get playWholeList => 'Lire toute la liste au choix d’un morceau';

  @override
  String get playWholeListHint => 'Désactivé, seul le morceau choisi est lu.';

  @override
  String get closeNote =>
      'Fermer la fenêtre quitte le lecteur et arrête la musique.';

  @override
  String get stopAfterTrack => 'Arrêter après ce morceau';

  @override
  String get cancelStopAfter => 'Continuer après ce morceau';

  @override
  String get showInFiles => 'Afficher dans le gestionnaire de fichiers';

  @override
  String get keepAwake => 'Garder l’ordinateur éveillé pendant la lecture';

  @override
  String get keepAwakeHint =>
      'L’écran reste allumé et l’ordinateur ne se met pas en veille tout seul. En pause, tout redevient normal.';

  @override
  String get keepAwakeReason => 'Lecture de musique';

  @override
  String get notifyTrack => 'Prévenir au changement de morceau';

  @override
  String get notifyTrackHint =>
      'Affiche le titre et l’artiste dans une notification du système.';

  @override
  String get shuffleOrder => 'Mélanger l’ordre';

  @override
  String get playlistShuffled => 'Ordre mélangé';

  @override
  String get removeDuplicates => 'Retirer les doublons';

  @override
  String duplicatesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doublons retirés',
      one: '1 doublon retiré',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Annuler';

  @override
  String get gapless => 'Lire sans blanc entre les morceaux';

  @override
  String get gaplessHint =>
      'Désactivé, la sortie audio se ferme et se rouvre entre les morceaux.';

  @override
  String get crossfade => 'Fondu enchaîné';

  @override
  String get crossfadeOff => 'Désactivé';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get crossfadeHint =>
      'Les morceaux se chevauchent au changement. Ceux qui se suivent dans un même album restent enchaînés sans coupure.';

  @override
  String get fadeOnPause => 'Adoucir la pause';

  @override
  String get fadeOnPauseHint =>
      'Le son baisse et revient progressivement à la pause et à la reprise.';

  @override
  String get replayGain => 'ReplayGain';

  @override
  String get replayGainOff => 'Désactivé';

  @override
  String get replayGainTrack => 'Morceau';

  @override
  String get replayGainAlbum => 'Album';

  @override
  String get replayGainHint =>
      'Égalise le volume à partir des valeurs dans les tags du fichier. Album conserve les écarts au sein d’un album. Les fichiers sans ces tags sont lus sans changement.';

  @override
  String get libraryFolders => 'Dossiers de la bibliothèque';

  @override
  String get watchFoldersSetting =>
      'Surveiller les changements dans les dossiers';

  @override
  String get watchFoldersHint =>
      'Les fichiers nouveaux, modifiés et supprimés apparaissent pendant que le lecteur est ouvert.';

  @override
  String get refreshOnOpen => 'Mettre à jour à l’ouverture';

  @override
  String get refreshOnOpenHint =>
      'Vérifie les dossiers à chaque ouverture du lecteur.';

  @override
  String get refreshNow => 'Mettre à jour maintenant';

  @override
  String get lyricsFiles => 'Chercher les fichiers .lrc et .srt';

  @override
  String get lyricsFilesHint => 'À côté de la musique, avec le même nom.';

  @override
  String get lyricsEmbeddedSetting => 'Utiliser les paroles intégrées';

  @override
  String get lyricsEmbeddedHint =>
      'Depuis les tags du fichier, en l’absence de fichier de paroles.';

  @override
  String get themeSetting => 'Thème';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeSystem => 'Système';

  @override
  String get dynamicColor => 'Couleur dynamique du système';

  @override
  String get dynamicColorHint =>
      'Utilise les couleurs du fond d’écran, quand le système les propose.';

  @override
  String get accentSetting => 'Couleur d’accent';

  @override
  String get accentDefault => 'Par défaut';

  @override
  String get accentCoral => 'Corail';

  @override
  String get accentAmber => 'Ambre';

  @override
  String get accentGreen => 'Vert';

  @override
  String get accentTeal => 'Sarcelle';

  @override
  String get accentBlue => 'Bleu';

  @override
  String get accentPurple => 'Violet';

  @override
  String get densitySetting => 'Densité des listes';

  @override
  String get densityComfortable => 'Confortable';

  @override
  String get densityCompact => 'Compacte';

  @override
  String get textSizeSetting => 'Taille du texte';

  @override
  String get reduceMotion => 'Réduire les animations';

  @override
  String get reduceMotionHint =>
      'Désactive le défilement des paroles et d’autres animations.';

  @override
  String get resetShortcuts => 'Rétablir les valeurs par défaut';

  @override
  String get mediaKeysNote =>
      'Les touches multimédia du clavier (lecture, pause, suivant, précédent) fonctionnent sans configuration.';

  @override
  String get commandPlayPause => 'Lecture et pause';

  @override
  String get commandSeekBack => 'Reculer de 5 secondes';

  @override
  String get commandSeekForward => 'Avancer de 5 secondes';

  @override
  String get commandPrevious => 'Morceau précédent';

  @override
  String get commandNext => 'Morceau suivant';

  @override
  String get commandMute => 'Couper le son';

  @override
  String get commandSearch => 'Rechercher';

  @override
  String get commandLyrics => 'Ouvrir et fermer les paroles';

  @override
  String get commandQueue => 'Ouvrir et fermer la file';

  @override
  String get keySpace => 'Espace';

  @override
  String changeShortcut(String command) {
    return 'Changer le raccourci : $command';
  }

  @override
  String get pressKeys => 'Appuyez sur les nouvelles touches. Échap annule.';

  @override
  String shortcutInUse(String command) {
    return 'Déjà utilisé par : $command';
  }

  @override
  String get aboutDescription =>
      'Lit les fichiers de votre ordinateur. Sans compte, sans streaming et sans pistage : ce que vous écoutez reste chez vous.';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get licenseLabel => 'Licence : Apache 2.0';

  @override
  String get thirdPartyLicenses => 'Textes complets des licences';

  @override
  String get builtWithClaude => 'Développé avec l’aide de Claude Code.';

  @override
  String get reportIssue => 'Signaler un problème sur GitHub';

  @override
  String get designInspiration => 'Inspiration du design';

  @override
  String get dartPackagesLabel => 'Licences : paquets Dart';

  @override
  String get systemLibrariesLabel => 'Licences : bibliothèques système';

  @override
  String get interfaceAssetsLabel => 'Licences : icônes';

  @override
  String get keepLogs => 'Écrire des journaux';

  @override
  String get keepLogsHint =>
      'Pour enquêter sur un problème. Ils contiennent des noms de morceaux et des chemins, et restent sur cet ordinateur.';

  @override
  String get aboutSupport => 'Assistance';

  @override
  String get openDataFolder => 'Ouvrir le dossier des données';

  @override
  String get copySupportInfo => 'Copier les informations pour l’assistance';

  @override
  String get supportInfoCopied => 'Copié';

  @override
  String addedToPlaylist(String name) {
    return 'Ajouté à « $name »';
  }

  @override
  String get addTracks => 'Ajouter des morceaux';

  @override
  String addTracksConfirm(int n) {
    return 'Ajouter $n';
  }

  @override
  String get alreadyInPlaylist => 'Déjà dans cette playlist';

  @override
  String get searchTracksHint => 'Rechercher des morceaux';

  @override
  String get playlistEmptyHint =>
      'Cette playlist est vide. Utilisez Ajouter des morceaux pour la remplir.';

  @override
  String tracksAdded(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n morceaux ajoutés',
      one: '1 morceau ajouté',
    );
    return '$_temp0';
  }

  @override
  String get nowPlaying => 'En cours de lecture';

  @override
  String get yourLibrary => 'Votre bibliothèque';

  @override
  String get rediscover => 'À redécouvrir';

  @override
  String get yourPlaylists => 'Vos playlists';

  @override
  String get filterList => 'Chercher dans cette liste';

  @override
  String get recentSearches => 'Recherches récentes';

  @override
  String get clearRecent => 'Effacer';

  @override
  String get removeRecent => 'Retirer des recherches récentes';

  @override
  String get browseGenres => 'Parcourir par genre';

  @override
  String get pin => 'Épingler';

  @override
  String get unpin => 'Détacher';

  @override
  String get pinned => 'Épinglé';

  @override
  String get pinnedHeading => 'Épinglés';

  @override
  String get yourMixes => 'Vos mix';

  @override
  String get dailyMix => 'Mix du jour';

  @override
  String genreMix(String genre) {
    return 'Mix $genre';
  }

  @override
  String get openTrackPage => 'Ouvrir la page du morceau';

  @override
  String get trackDetails => 'Détails';

  @override
  String get overview => 'Aperçu';

  @override
  String get singles => 'Morceaux isolés';

  @override
  String singlesHint(String tracks) {
    return '$tracks, seuls dans leur album';
  }

  @override
  String get expandRail => 'Afficher les noms';

  @override
  String get collapseRail => 'Masquer les noms';

  @override
  String get playerSize => 'Taille du lecteur';

  @override
  String get modeFull => 'Complet';

  @override
  String get modeCompact => 'Compact';

  @override
  String get modeMini => 'Mini-lecteur';

  @override
  String get exitMini => 'Quitter le mini-lecteur';

  @override
  String get autoTopRated => 'Les mieux notés';

  @override
  String get rateTrack => 'Noter…';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étoiles',
      one: '1 étoile',
    );
    return '$_temp0';
  }

  @override
  String get clearRating => 'Retirer la note';

  @override
  String get dynamicMixStart => 'Lancer le mix dynamique';

  @override
  String get dynamicMixStop => 'Arrêter le mix dynamique';

  @override
  String get columnRating => 'Note';

  @override
  String get useRatings => 'Utiliser les notes par étoiles';

  @override
  String get useRatingsHint =>
      'Affiche des étoiles à côté du cœur. Désactivé, vos notes restent enregistrées, et les morceaux à une étoile restent hors des mix.';

  @override
  String markAll(int n) {
    return 'Tout cocher ($n)';
  }

  @override
  String get clearSelection => 'Effacer la sélection';

  @override
  String createWithTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Créer avec $n morceaux',
      one: 'Créer avec 1 morceau',
    );
    return '$_temp0';
  }
}
