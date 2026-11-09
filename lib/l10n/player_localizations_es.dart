// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'player_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class PlayerLocalizationsEs extends PlayerLocalizations {
  PlayerLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Reproductor de música';

  @override
  String get noTrack => 'Sin pista';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausar';

  @override
  String get progress => 'Progreso';

  @override
  String get volume => 'Volumen';

  @override
  String get home => 'Inicio';

  @override
  String get library => 'Biblioteca';

  @override
  String get playlists => 'Listas';

  @override
  String get folders => 'Carpetas';

  @override
  String get search => 'Buscar';

  @override
  String get settings => 'Ajustes';

  @override
  String engineUnavailable(Object error) {
    return 'El motor de audio no está disponible: $error';
  }

  @override
  String get openFailed => 'No se pudo reproducir este archivo';

  @override
  String get addFolder => 'Añadir carpeta';

  @override
  String get addMusicFolder => 'Añadir carpeta de música';

  @override
  String get folderNotVisible =>
      'El reproductor no puede ver esta carpeta. Elige una de tu carpeta personal o de un disco externo.';

  @override
  String get folderAlreadyAdded => 'Esta carpeta ya está en la biblioteca.';

  @override
  String libraryUnavailable(String error) {
    return 'No se pudo abrir la biblioteca: $error';
  }

  @override
  String get albums => 'Álbumes';

  @override
  String get unknownArtist => 'Artista desconocido';

  @override
  String playAlbum(String album) {
    return 'Reproducir $album';
  }

  @override
  String get hasLyrics => 'Tiene letra';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get playNext => 'Reproducir a continuación';

  @override
  String get addToQueue => 'Añadir a la cola';

  @override
  String get removeFromQueue => 'Quitar de la cola';

  @override
  String get queue => 'Cola';

  @override
  String get queueEmpty => 'La cola está vacía';

  @override
  String get close => 'Cerrar';

  @override
  String get shuffle => 'Aleatorio';

  @override
  String get previousTrack => 'Pista anterior';

  @override
  String get nextTrack => 'Pista siguiente';

  @override
  String get repeatOff => 'Repetir: no';

  @override
  String get repeatAll => 'Repetir: todo';

  @override
  String get repeatOne => 'Repetir: una';

  @override
  String get continueListening => 'Continúa donde lo dejaste';

  @override
  String get continuePlaying => 'Continuar';

  @override
  String stoppedAt(String artist, String position, String duration) {
    return '$artist · detenido en $position de $duration';
  }

  @override
  String get shuffleAll => 'Mezclar todo';

  @override
  String get recentlyAdded => 'Añadido recientemente';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get mostPlayed => 'Más escuchado';

  @override
  String get emptyTitle => 'Tu biblioteca está vacía';

  @override
  String get emptyBody =>
      'Indica la carpeta donde está tu música. El reproductor lee los archivos directamente de tu ordenador y no envía nada fuera.';

  @override
  String useFolder(String folder) {
    return 'Usar $folder';
  }

  @override
  String get acceptedFormats => 'Formatos admitidos';

  @override
  String get scanning => 'Leyendo tu biblioteca';

  @override
  String get scanSubtitle =>
      'Lectura en curso: ya puedes escuchar lo que se ha encontrado';

  @override
  String scanFiles(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString de $totalString archivos';
  }

  @override
  String get scanLessThanMinute => 'queda menos de un minuto';

  @override
  String scanMinutesLeft(int n) {
    return 'quedan unos $n min';
  }

  @override
  String get pauseScan => 'Pausar';

  @override
  String get resumeScan => 'Reanudar';

  @override
  String get cancelScan => 'Cancelar';

  @override
  String get scanKeepsGoing => 'La lectura continúa si sales de esta pantalla';

  @override
  String get foundSoFar => 'Encontrado hasta ahora';

  @override
  String get updateAll => 'Actualizar todo';

  @override
  String get updateFolder => 'Actualizar carpeta';

  @override
  String get removeFolder => 'Quitar de la biblioteca';

  @override
  String get folderMissing => 'Disco no encontrado';

  @override
  String get notScanned => 'Aún sin leer';

  @override
  String get scannedJustNow => 'Actualizado ahora mismo';

  @override
  String scannedMinutes(int n) {
    return 'Actualizado hace $n min';
  }

  @override
  String scannedHours(int n) {
    return 'Actualizado hace $n h';
  }

  @override
  String scannedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Actualizado hace $n días',
      one: 'Actualizado ayer',
      zero: 'Actualizado hoy',
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
      other: '$nString álbumes',
      one: '1 álbum',
      zero: '0 álbumes',
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
      other: '$nString pistas',
      one: '1 pista',
      zero: '0 pistas',
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
      other: '$nString carpetas',
      one: '1 carpeta',
      zero: '0 carpetas',
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
      other: '$nString carátulas encontradas',
      one: '1 carátula encontrada',
      zero: '0 carátulas encontradas',
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
      other: '$nString archivos omitidos',
      one: '1 archivo omitido',
      zero: '0 archivos omitidos',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Atrás';

  @override
  String get songs => 'Canciones';

  @override
  String get artists => 'Artistas';

  @override
  String get genres => 'Géneros';

  @override
  String get allFilter => 'Todo';

  @override
  String get allSongs => 'Todas';

  @override
  String get favorites => 'Favoritos';

  @override
  String get mineFilter => 'Mías';

  @override
  String get automaticFilter => 'Automáticas';

  @override
  String get addFavorite => 'Añadir a favoritos';

  @override
  String get removeFavorite => 'Quitar de favoritos';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortRecent => 'Recientes';

  @override
  String get sortAZ => 'De la A a la Z';

  @override
  String get sortArtist => 'Artista';

  @override
  String get sortYear => 'Año';

  @override
  String get sortMostTracks => 'Más canciones';

  @override
  String get columnTitle => 'Título';

  @override
  String get columnAlbum => 'Álbum';

  @override
  String get columnDuration => 'Duración';

  @override
  String get columnFormat => 'Formato';

  @override
  String get viewGrid => 'Cuadrícula';

  @override
  String get viewList => 'Lista';

  @override
  String get searchHint => 'Buscar en la biblioteca';

  @override
  String get searchSongsHint => 'Buscar canciones';

  @override
  String get searchArtistsHint => 'Buscar artistas';

  @override
  String get searchGenresHint => 'Buscar géneros';

  @override
  String get searchAlbumsHint => 'Buscar álbumes';

  @override
  String get searchFoldersHint => 'Buscar carpetas';

  @override
  String get searchAllHint => 'Canciones, álbumes, artistas o carpetas';

  @override
  String get searchShortcut => 'Ctrl K';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String noResults(String query) {
    return 'No se encontró nada para «$query»';
  }

  @override
  String get searchPrompt => 'Escribe para buscar en tu biblioteca.';

  @override
  String get bestResult => 'Mejor resultado';

  @override
  String get playAll => 'Reproducir todo';

  @override
  String get kindArtist => 'Artista';

  @override
  String get kindAlbum => 'Álbum';

  @override
  String get kindSong => 'Canción';

  @override
  String get nothingHere => 'Aún no hay nada aquí.';

  @override
  String get noGenre => 'Sin género';

  @override
  String get fileUnavailable => 'Este archivo no está disponible ahora';

  @override
  String get nothingAvailable =>
      'Estas canciones no están disponibles. ¿Está conectado el disco?';

  @override
  String get watchFolders => 'Vigilar cambios en las carpetas';

  @override
  String get watchFoldersBody =>
      'Detecta archivos nuevos, modificados y eliminados mientras el reproductor está abierto.';

  @override
  String get newPlaylist => 'Nueva lista';

  @override
  String get importPlaylist => 'Importar lista';

  @override
  String get exportPlaylist => 'Exportar lista';

  @override
  String get skipTrack => 'Saltar en las listas';

  @override
  String get unskipTrack => 'Dejar de saltar';

  @override
  String get skippedTrack => 'Se salta en las listas';

  @override
  String get skippedFilter => 'Saltadas';

  @override
  String get duplicatesFilter => 'Duplicadas';

  @override
  String get smartRuleField => 'Campo';

  @override
  String get smartRuleCompare => 'Comparación';

  @override
  String get newSmartPlaylist => 'Lista inteligente';

  @override
  String get editSmartRules => 'Editar reglas';

  @override
  String get smartSuffix => 'inteligente';

  @override
  String get ruleGenre => 'Género';

  @override
  String get ruleYear => 'Año';

  @override
  String get ruleRating => 'Nota';

  @override
  String get ruleIs => 'es';

  @override
  String get ruleIsNot => 'no es';

  @override
  String get ruleAtLeast => 'como mínimo';

  @override
  String get ruleAtMost => 'como máximo';

  @override
  String get matchAllRules => 'Todas las reglas';

  @override
  String get matchAnyRule => 'Cualquier regla';

  @override
  String get addRule => 'Añadir regla';

  @override
  String get removeRule => 'Quitar regla';

  @override
  String get smartOrder => 'Orden';

  @override
  String get orderTitle => 'Título';

  @override
  String get orderRecent => 'Añadidas recientemente';

  @override
  String get orderRating => 'Mejor valoradas';

  @override
  String get orderYear => 'Más nuevas';

  @override
  String get smartLimit => 'Máximo de canciones';

  @override
  String get noLimit => 'Sin límite';

  @override
  String get choosePlaylistCover => 'Elegir carátula';

  @override
  String get removePlaylistCover => 'Quitar carátula';

  @override
  String get coverUnreadable => 'No se pudo leer esa imagen';

  @override
  String get renamePlaylist => 'Renombrar';

  @override
  String get deletePlaylist => 'Eliminar lista';

  @override
  String deletePlaylistBody(String name) {
    return '¿Eliminar «$name»? Los archivos de música se quedan donde están.';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get create => 'Crear';

  @override
  String get playlistName => 'Nombre de la lista';

  @override
  String get addToPlaylist => 'Añadir a una lista';

  @override
  String get removeFromPlaylist => 'Quitar de la lista';

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Bajar';

  @override
  String get dragToReorder => 'Arrastra para reordenar';

  @override
  String get autoFavorites => 'Favoritos';

  @override
  String get autoMostPlayed => 'Más escuchado';

  @override
  String get autoRecent => 'Añadido recientemente';

  @override
  String get automaticSuffix => 'automática';

  @override
  String exportFailed(String error) {
    return 'No se pudo escribir el archivo: $error';
  }

  @override
  String importFailed(String error) {
    return 'No se pudo leer el archivo: $error';
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
      other: '$n artistas',
      one: '1 artista',
    );
    return '$_temp0';
  }

  @override
  String genreCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n géneros',
      one: '1 género',
    );
    return '$_temp0';
  }

  @override
  String playlistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n listas',
      one: '1 lista',
    );
    return '$_temp0';
  }

  @override
  String fileCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n archivos',
      one: '1 archivo',
    );
    return '$_temp0';
  }

  @override
  String folderChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cambios',
      one: '1 cambio',
    );
    return '$_temp0';
  }

  @override
  String imported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n canciones importadas',
      one: '1 canción importada',
    );
    return '$_temp0';
  }

  @override
  String importedRemote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n direcciones de red omitidas',
      one: '1 dirección de red omitida',
    );
    return '$_temp0';
  }

  @override
  String get lyricsTab => 'Letra';

  @override
  String get coverTab => 'Carátula';

  @override
  String get noLyrics => 'Esta pista no tiene letra';

  @override
  String get lyricsSynced => 'sincronizada';

  @override
  String get lyricsUnsynced => 'sin sincronizar';

  @override
  String get lyricsEmbedded => 'En las etiquetas';

  @override
  String get lyricsTiming => 'Ajustar el tiempo de la letra';

  @override
  String get lyricsEarlier => 'Mostrar la letra antes';

  @override
  String get lyricsLater => 'Mostrar la letra después';

  @override
  String get lyricsResetTiming => 'Restablecer el tiempo';

  @override
  String get withLyrics => 'Con letra';

  @override
  String get upNext => 'A continuación';

  @override
  String get clearQueue => 'Vaciar';

  @override
  String get saveAsPlaylist => 'Guardar como lista';

  @override
  String get detailAlbum => 'Álbum';

  @override
  String get detailGenre => 'Género';

  @override
  String get detailFile => 'Archivo';

  @override
  String get detailCover => 'Carátula';

  @override
  String get detailFolder => 'Carpeta';

  @override
  String get coverEmbedded => 'Integrada';

  @override
  String get coverGenerated => 'Generada';

  @override
  String secondsOffset(String value) {
    return '$value s';
  }

  @override
  String playlistSaved(String name) {
    return 'Guardada como «$name»';
  }

  @override
  String get settingsPlayback => 'Reproducción';

  @override
  String get settingsEqualizer => 'Ecualizador';

  @override
  String get equalizerOn => 'Usar el ecualizador';

  @override
  String get equalizerHint =>
      'Baja un poco el volumen general para dejar sitio a las bandas reforzadas, y así el sonido no se distorsiona.';

  @override
  String get equalizerPresets => 'Preajustes';

  @override
  String get equalizerCustom => 'Personalizado';

  @override
  String get equalizerFlat => 'Plano';

  @override
  String get equalizerRock => 'Rock';

  @override
  String get equalizerPop => 'Pop';

  @override
  String get equalizerJazz => 'Jazz';

  @override
  String get equalizerClassical => 'Clásica';

  @override
  String get equalizerElectronic => 'Electrónica';

  @override
  String get equalizerBass => 'Más graves';

  @override
  String get equalizerTreble => 'Más agudos';

  @override
  String get equalizerVocal => 'Voces';

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
  String get settingsLibrary => 'Biblioteca';

  @override
  String get settingsLyrics => 'Letras';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsShortcuts => 'Atajos de teclado';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get rememberSession => 'Recordar la última pista';

  @override
  String get rememberSessionHint =>
      'Vuelve a abrir la cola donde se detuvo, en pausa.';

  @override
  String get playWholeList => 'Reproducir toda la lista al elegir una pista';

  @override
  String get playWholeListHint => 'Desactivado, solo suena la pista elegida.';

  @override
  String get closeNote =>
      'Al cerrar la ventana, el reproductor se cierra y la música se detiene.';

  @override
  String get stopAfterTrack => 'Detener después de esta pista';

  @override
  String get cancelStopAfter => 'Seguir reproduciendo después de esta pista';

  @override
  String get showInFiles => 'Mostrar en el gestor de archivos';

  @override
  String get keepAwake =>
      'Mantener el ordenador activo durante la reproducción';

  @override
  String get keepAwakeHint =>
      'La pantalla sigue encendida y el ordenador no se suspende solo. En pausa, todo vuelve a la normalidad.';

  @override
  String get keepAwakeReason => 'Reproduciendo música';

  @override
  String get notifyTrack => 'Avisar cuando cambie la pista';

  @override
  String get notifyTrackHint =>
      'Muestra el título y el artista en una notificación del sistema.';

  @override
  String get shuffleOrder => 'Mezclar el orden';

  @override
  String get playlistShuffled => 'Orden mezclado';

  @override
  String get removeDuplicates => 'Quitar duplicados';

  @override
  String duplicatesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicados eliminados',
      one: '1 duplicado eliminado',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get gapless => 'Reproducir sin pausas entre pistas';

  @override
  String get gaplessHint =>
      'Desactivado, la salida de sonido se cierra y se abre entre pistas.';

  @override
  String get crossfade => 'Fundido entre pistas';

  @override
  String get crossfadeOff => 'Desactivado';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get crossfadeHint =>
      'Las canciones se solapan al cambiar. Las seguidas del mismo álbum siguen sin pausa.';

  @override
  String get fadeOnPause => 'Suavizar al pausar';

  @override
  String get fadeOnPauseHint =>
      'El sonido baja y vuelve poco a poco al pausar y continuar.';

  @override
  String get replayGain => 'ReplayGain';

  @override
  String get replayGainOff => 'Desactivado';

  @override
  String get replayGainTrack => 'Pista';

  @override
  String get replayGainAlbum => 'Álbum';

  @override
  String get replayGainHint =>
      'Iguala el volumen con los valores de las etiquetas del archivo. Álbum conserva las diferencias dentro de un álbum. Los archivos sin esas etiquetas suenan sin cambios.';

  @override
  String get libraryFolders => 'Carpetas de la biblioteca';

  @override
  String get watchFoldersSetting => 'Vigilar cambios en las carpetas';

  @override
  String get watchFoldersHint =>
      'Los archivos nuevos, modificados y eliminados aparecen mientras el reproductor está abierto.';

  @override
  String get refreshOnOpen => 'Actualizar al abrir';

  @override
  String get refreshOnOpenHint =>
      'Comprueba las carpetas cada vez que se abre el reproductor.';

  @override
  String get refreshNow => 'Actualizar ahora';

  @override
  String get lyricsFiles => 'Buscar archivos .lrc y .srt';

  @override
  String get lyricsFilesHint => 'Junto a la música, con el mismo nombre.';

  @override
  String get lyricsEmbeddedSetting => 'Usar letras integradas';

  @override
  String get lyricsEmbeddedHint =>
      'De las etiquetas del archivo, cuando no hay archivo de letra.';

  @override
  String get themeSetting => 'Tema';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get dynamicColor => 'Color dinámico del sistema';

  @override
  String get dynamicColorHint =>
      'Usa los colores del fondo de pantalla, cuando el sistema los ofrece.';

  @override
  String get accentSetting => 'Color de acento';

  @override
  String get accentDefault => 'Predeterminado';

  @override
  String get accentCoral => 'Coral';

  @override
  String get accentAmber => 'Ámbar';

  @override
  String get accentGreen => 'Verde';

  @override
  String get accentTeal => 'Verde azulado';

  @override
  String get accentBlue => 'Azul';

  @override
  String get accentPurple => 'Morado';

  @override
  String get densitySetting => 'Densidad de las listas';

  @override
  String get densityComfortable => 'Cómoda';

  @override
  String get densityCompact => 'Compacta';

  @override
  String get textSizeSetting => 'Tamaño del texto';

  @override
  String get reduceMotion => 'Reducir animaciones';

  @override
  String get reduceMotionHint =>
      'Desactiva el desplazamiento de la letra y otras animaciones.';

  @override
  String get resetShortcuts => 'Restaurar valores predeterminados';

  @override
  String get mediaKeysNote =>
      'Las teclas multimedia del teclado (reproducir, pausar, siguiente, anterior) funcionan sin configurar nada.';

  @override
  String get commandPlayPause => 'Reproducir y pausar';

  @override
  String get commandSeekBack => 'Retroceder 5 segundos';

  @override
  String get commandSeekForward => 'Avanzar 5 segundos';

  @override
  String get commandPrevious => 'Pista anterior';

  @override
  String get commandNext => 'Pista siguiente';

  @override
  String get commandMute => 'Silenciar';

  @override
  String get commandSearch => 'Buscar';

  @override
  String get commandLyrics => 'Abrir y cerrar la letra';

  @override
  String get commandQueue => 'Abrir y cerrar la cola';

  @override
  String get keySpace => 'Espacio';

  @override
  String changeShortcut(String command) {
    return 'Cambiar el atajo: $command';
  }

  @override
  String get pressKeys => 'Pulsa las teclas nuevas. Esc cancela.';

  @override
  String shortcutInUse(String command) {
    return 'Ya lo usa: $command';
  }

  @override
  String get aboutDescription =>
      'Reproduce los archivos de tu ordenador. Sin cuenta, sin streaming y sin rastreo: lo que escuchas se queda contigo.';

  @override
  String versionLabel(String version) {
    return 'Versión $version';
  }

  @override
  String get licenseLabel => 'Licencia: Apache 2.0';

  @override
  String get thirdPartyLicenses => 'Textos completos de las licencias';

  @override
  String get builtWithClaude => 'Desarrollado con la ayuda de Claude Code.';

  @override
  String get reportIssue => 'Informar de un problema en GitHub';

  @override
  String get designInspiration => 'Inspiración del diseño';

  @override
  String get dartPackagesLabel => 'Licencias: paquetes de Dart';

  @override
  String get systemLibrariesLabel => 'Licencias: bibliotecas del sistema';

  @override
  String get bundledLibrariesLabel => 'Licencias: bibliotecas incluidas';

  @override
  String get interfaceAssetsLabel => 'Licencias: iconos';

  @override
  String get keepLogs => 'Escribir registros';

  @override
  String get keepLogsHint =>
      'Para investigar un problema. Incluyen nombres de canciones y rutas, y se quedan en este ordenador.';

  @override
  String get aboutSupport => 'Soporte';

  @override
  String get openDataFolder => 'Abrir la carpeta de datos';

  @override
  String get copySupportInfo => 'Copiar información para soporte';

  @override
  String get supportInfoCopied => 'Copiado';

  @override
  String addedToPlaylist(String name) {
    return 'Añadido a «$name»';
  }

  @override
  String get addTracks => 'Añadir canciones';

  @override
  String addTracksConfirm(int n) {
    return 'Añadir $n';
  }

  @override
  String get alreadyInPlaylist => 'Ya está en esta lista';

  @override
  String get searchTracksHint => 'Buscar canciones';

  @override
  String get playlistEmptyHint =>
      'Esta lista está vacía. Usa Añadir canciones para llenarla.';

  @override
  String tracksAdded(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n canciones añadidas',
      one: '1 canción añadida',
    );
    return '$_temp0';
  }

  @override
  String get nowPlaying => 'Sonando ahora';

  @override
  String get yourLibrary => 'Tu biblioteca';

  @override
  String get rediscover => 'Redescubre';

  @override
  String get yourPlaylists => 'Tus listas';

  @override
  String get filterList => 'Buscar en esta lista';

  @override
  String get recentSearches => 'Búsquedas recientes';

  @override
  String get clearRecent => 'Borrar';

  @override
  String get removeRecent => 'Quitar de las búsquedas recientes';

  @override
  String get browseGenres => 'Explorar por género';

  @override
  String get pin => 'Fijar';

  @override
  String get unpin => 'Desfijar';

  @override
  String get pinned => 'Fijado';

  @override
  String get pinnedHeading => 'Fijados';

  @override
  String get yourMixes => 'Tus mixes';

  @override
  String get dailyMix => 'Mix del día';

  @override
  String genreMix(String genre) {
    return 'Mix de $genre';
  }

  @override
  String get openTrackPage => 'Abrir la página de la canción';

  @override
  String get trackDetails => 'Detalles';

  @override
  String get overview => 'Resumen';

  @override
  String get singles => 'Pistas sueltas';

  @override
  String singlesHint(String tracks) {
    return '$tracks solas en su álbum';
  }

  @override
  String get expandRail => 'Mostrar nombres';

  @override
  String get collapseRail => 'Ocultar nombres';

  @override
  String get playerSize => 'Tamaño del reproductor';

  @override
  String get modeFull => 'Completo';

  @override
  String get modeCompact => 'Compacto';

  @override
  String get modeMini => 'Minirreproductor';

  @override
  String get exitMini => 'Salir del minirreproductor';

  @override
  String get autoTopRated => 'Mejor valoradas';

  @override
  String get rateTrack => 'Valorar…';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas',
      one: '1 estrella',
    );
    return '$_temp0';
  }

  @override
  String get clearRating => 'Quitar la valoración';

  @override
  String get dynamicMixStart => 'Iniciar mix dinámico';

  @override
  String get dynamicMixStop => 'Detener mix dinámico';

  @override
  String get columnRating => 'Valoración';

  @override
  String get useRatings => 'Usar valoración por estrellas';

  @override
  String get useRatingsHint =>
      'Muestra estrellas junto al corazón. Desactivado, tus valoraciones se conservan, y las canciones con una estrella siguen fuera de los mixes.';

  @override
  String markAll(int n) {
    return 'Marcar todas ($n)';
  }

  @override
  String get clearSelection => 'Borrar selección';

  @override
  String createWithTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Crear con $n canciones',
      one: 'Crear con 1 canción',
    );
    return '$_temp0';
  }

  @override
  String get tagEditMenu => 'Editar etiquetas…';

  @override
  String get tagEditAlbumMenu => 'Editar álbum…';

  @override
  String get tagEditTitle => 'Editar etiquetas';

  @override
  String get tagEditAlbumTitle => 'Editar álbum';

  @override
  String get tagsReadOnlyTitle => 'Etiquetas';

  @override
  String get tagDetails => 'Detalles';

  @override
  String get tagTitle => 'Título';

  @override
  String get tagArtist => 'Artista';

  @override
  String get tagAlbum => 'Álbum';

  @override
  String get tagAlbumArtist => 'Artista del álbum';

  @override
  String get tagYear => 'Año';

  @override
  String get tagGenre => 'Género';

  @override
  String get tagComposer => 'Compositor';

  @override
  String get tagComment => 'Comentario';

  @override
  String get tagTrack => 'Pista';

  @override
  String get tagDisc => 'Disco';

  @override
  String get tagTrackNumber => 'Número de pista';

  @override
  String get tagTrackTotal => 'Total de pistas';

  @override
  String get tagDiscNumber => 'Número de disco';

  @override
  String get tagDiscTotal => 'Total de discos';

  @override
  String get tagPairOf => 'de';

  @override
  String get tagChanged => 'modificado';

  @override
  String tagChangedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n campos modificados',
      one: '$n campo modificado',
    );
    return '$_temp0';
  }

  @override
  String tagPosition(int index, int total) {
    return '$index de $total';
  }

  @override
  String get tagPreviousTrack => 'Pista anterior';

  @override
  String get tagNextTrack => 'Pista siguiente';

  @override
  String get tagSaveChangesTitle => '¿Guardar los cambios de esta pista?';

  @override
  String tagSaveChangesBody(String fields, String title) {
    return 'Cambiaste $fields en $title. Antes, guarda o descarta estos cambios.';
  }

  @override
  String get tagDiscard => 'Descartar';

  @override
  String get tagDiscardBatchTitle => '¿Descartar los cambios?';

  @override
  String get tagSaveAndNext => 'Guardar e ir a la siguiente';

  @override
  String get tagSaveAndPrevious => 'Guardar e ir a la anterior';

  @override
  String get tagSaveAndClose => 'Guardar y cerrar';

  @override
  String get tagLyricsFileNote =>
      'Esto edita la letra dentro del archivo de música. El archivo de letra que está al lado no cambia y sigue teniendo prioridad.';

  @override
  String get tagCoverCurrent => 'Portada actual';

  @override
  String get tagCoverNew => 'Nueva';

  @override
  String get tagCoverBefore => 'Antes';

  @override
  String get tagCoverChange => 'Cambiar imagen';

  @override
  String tagCoverFromFolder(String name) {
    return 'Usar la portada de la carpeta ($name)';
  }

  @override
  String get tagCoverRemove => 'Quitar la portada incrustada';

  @override
  String get tagCoverKeep => 'Mantener la del archivo';

  @override
  String get tagCoverChoose => 'Elige la portada';

  @override
  String tagReadOnlyFormat(String format) {
    return 'Todavía no se pueden editar archivos $format. Las etiquetas se muestran solo para lectura.';
  }

  @override
  String get tagReadOnlyDisk =>
      'Este archivo está en un disco de solo lectura. Para editarlo, monta el disco con permiso de escritura.';

  @override
  String get tagReadOnlyPermission =>
      'No tienes permiso para cambiar este archivo.';

  @override
  String get tagReadOnlyMissing => 'Este archivo no está disponible ahora.';

  @override
  String get tagVariousValues => 'Varios valores';

  @override
  String get tagBatchNote =>
      'Solo se graba lo que cambies; el resto queda como está en cada pista. El título y el número de pista quedan fuera, porque cada pista tiene el suyo.';

  @override
  String get tagKeepField => 'Mantener este campo';

  @override
  String tagEraseField(int count, String label) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Borrar $label en las $count pistas',
      one: 'Borrar $label en $count pista',
    );
    return '$_temp0';
  }

  @override
  String tagWillErase(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Se borrará en las $n pistas',
      one: 'Se borrará en $n pista',
    );
    return '$_temp0';
  }

  @override
  String tagArtistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n artistas',
      one: '$n artista',
    );
    return '$_temp0';
  }

  @override
  String tagBatchSkipped(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n archivos no se pueden editar y quedan fuera.',
      one: '$n archivo no se puede editar y queda fuera.',
    );
    return '$_temp0';
  }

  @override
  String tagBatchSummary(int fields, int files) {
    return 'Campos modificados: $fields · archivos: $files';
  }

  @override
  String tagSaveIn(int n) {
    return 'Guardar en $n';
  }

  @override
  String get tagAlbumFields => 'Datos y portada del álbum';

  @override
  String get tagColumnNumber => 'N.º';

  @override
  String get tagNumberInOrder => 'Numerar en orden';

  @override
  String get tagTitleFromFile => 'Título del nombre de archivo';

  @override
  String get tagAlbumDragHint =>
      'Arrastra por el asa, o usa Subir y Bajar en el menú de la fila. Numerar en orden da 1, 2, 3… según la tabla.';

  @override
  String tagFilesToWrite(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Se grabarán $n archivos',
      one: 'Se grabará $n archivo',
    );
    return '$_temp0';
  }

  @override
  String tagsWriting(int done, int total) {
    return 'Grabando $done de $total';
  }

  @override
  String get tagsHideProgress => 'Ocultar; la grabación continúa';

  @override
  String tagsWritten(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Etiquetas grabadas en $n archivos',
      one: 'Etiquetas grabadas en $n archivo',
    );
    return '$_temp0';
  }

  @override
  String tagsPartly(int ok, int failed) {
    return '$ok grabadas, $failed no';
  }

  @override
  String get tagFailuresDetails => 'Detalles';

  @override
  String tagsRestored(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Etiquetas restauradas en $n archivos',
      one: 'Etiquetas restauradas en $n archivo',
    );
    return '$_temp0';
  }

  @override
  String tagsPartlyRestored(int ok, int failed) {
    return '$ok restauradas, $failed cambiaron desde entonces';
  }

  @override
  String tagFailuresTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n archivos no se grabaron',
      one: '$n archivo no se grabó',
    );
    return '$_temp0';
  }

  @override
  String tagFailureFormat(String format) {
    return 'Todavía no se pueden editar archivos $format';
  }

  @override
  String get tagFailureReadOnly => 'El disco es de solo lectura';

  @override
  String get tagFailurePermission => 'Sin permiso para cambiar el archivo';

  @override
  String get tagFailureMissing => 'El archivo o el disco ya no está';

  @override
  String get tagFailureInUse =>
      'Otro programa está usando el archivo. Cambia de pista o ciérralo e inténtalo de nuevo';

  @override
  String get tagFailureNoSpace => 'No hay espacio en el disco';

  @override
  String get tagFailureChanged => 'El archivo cambió después de grabarse';

  @override
  String get tagFailureDamaged =>
      'La estructura del archivo no se pudo grabar con seguridad y quedó como estaba';

  @override
  String get selectionAdd => 'Seleccionar';

  @override
  String get selectionRemove => 'Quitar de la selección';

  @override
  String get selectionClear => 'Borrar selección';

  @override
  String selectionCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n seleccionadas',
      one: '$n seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get tagColumnFile => 'Archivo';

  @override
  String get organizeMenu => 'Organizar archivos…';

  @override
  String get organizeCopyMenu => 'Copiar a una carpeta…';

  @override
  String get organizeTitle => 'Organizar archivos';

  @override
  String get organizeCopyTitle => 'Copiar a una carpeta';

  @override
  String get organizeAction => 'Organizar';

  @override
  String get organizeCopyAction => 'Copiar';

  @override
  String get organizePattern => 'Patrón de nombres';

  @override
  String get organizePatternInvalid =>
      'Usa los botones de abajo; el patrón necesita el título';

  @override
  String get organizeUnknown => 'Desconocido';

  @override
  String get organizeChooseFolder => 'Elegir carpeta';

  @override
  String get organizeNoFolder => 'Elige adónde copiar';

  @override
  String organizeFreeSpace(String free, String needed) {
    return '$free libres · $needed por copiar';
  }

  @override
  String get organizeNothing => 'Nada que hacer: todo está en su sitio.';

  @override
  String get organizeBusy =>
      'Espera a que termine la lectura de la biblioteca.';

  @override
  String get organizeSameTarget => 'Mismo nombre que otra';

  @override
  String get organizeTargetExists => 'Ya hay un archivo con ese nombre';

  @override
  String get organizePlaying => 'Sonando ahora';

  @override
  String get organizeNoSpace => 'No cabe';

  @override
  String organizeWillMove(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Se moverán $n archivos',
      one: 'Se moverá $n archivo',
    );
    return '$_temp0';
  }

  @override
  String organizeWillCopy(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Se copiarán $n archivos',
      one: 'Se copiará $n archivo',
    );
    return '$_temp0';
  }

  @override
  String organizeUnchanged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ya en su sitio',
      one: '$n ya en su sitio',
    );
    return '$_temp0';
  }

  @override
  String organizeProblems(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n con problema',
      one: '$n con problema',
    );
    return '$_temp0';
  }

  @override
  String organizeMoving(int done, int total) {
    return 'Moviendo $done de $total';
  }

  @override
  String organizeCopying(int done, int total) {
    return 'Copiando $done de $total';
  }

  @override
  String organizeMoved(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n archivos movidos',
      one: '$n archivo movido',
    );
    return '$_temp0';
  }

  @override
  String organizeCopied(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n archivos copiados',
      one: '$n archivo copiado',
    );
    return '$_temp0';
  }

  @override
  String organizeRestored(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n archivos de vuelta en su sitio',
      one: '$n archivo de vuelta en su sitio',
    );
    return '$_temp0';
  }

  @override
  String get tagCueReadOnly =>
      'Las pistas de una cue sheet no se pueden editar aquí.';
}
