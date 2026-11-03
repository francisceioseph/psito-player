// lib/player_app.dart
//
// O player: liga o motor e a biblioteca às telas, e guarda para onde a
// pessoa navegou. Os componentes ficam em `src/ui/`, em atomic design.
import 'dart:async';
import 'dart:io';
import 'dart:ui' show AppExitResponse, AppExitType;

import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'l10n/l10n.dart';
import 'src/library/folder_watcher.dart';
import 'src/library/library_controller.dart';
import 'src/library/library_search.dart';
import 'src/library/library_store.dart';
import 'src/library/models.dart';
import 'src/library/scanner.dart';
import 'src/lyrics/lyrics_controller.dart';
import 'src/lyrics/lyrics_loader.dart';
import 'src/player/engine.dart';
import 'src/player/mpris.dart';
import 'src/player/playback_controller.dart';
import 'src/player/player_shortcuts.dart';
import 'src/settings/player_settings.dart';
import 'src/ui/atoms/generic_art.dart';
import 'src/ui/atoms/monogram.dart';
import 'src/ui/format.dart';
import 'src/ui/molecules/track_menu.dart';
import 'src/ui/organisms/navigation.dart';
import 'src/ui/organisms/now_playing_panel.dart';
import 'src/ui/organisms/player_bar.dart';
import 'src/ui/pages/album_page.dart';
import 'src/ui/pages/empty_library_page.dart';
import 'src/ui/pages/folders_page.dart';
import 'src/ui/pages/home_page.dart';
import 'src/ui/pages/library_page.dart';
import 'src/ui/pages/playlist_page.dart';
import 'src/ui/pages/playlists_page.dart';
import 'src/ui/pages/search_page.dart';
import 'src/ui/pages/settings_page.dart';
import 'src/ui/pages/tracks_page.dart';
import 'src/ui/player_actions.dart';
import 'src/ui/templates/shell_template.dart';

export 'src/library/library_controller.dart' show userMusicDir;
export 'src/player/media_kit_engine.dart' show MediaKitEngine;

/// O tema de quem abre o player sem trazer um: só a cor de destaque.
ThemeData playerBaseTheme(Color accent) =>
    ThemeData(colorScheme: ColorScheme.dark(primary: accent));

/// A mãozinha nos botões. O Flutter só a mostra na web por padrão.
const _clickable = ButtonStyle(mouseCursor: WidgetStateMouseCursor.clickable);

/// Os textos, um passo acima do padrão do Material, que é pensado para o celular.
const _textTheme = TextTheme(
  headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
  titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
  titleMedium: TextStyle(fontSize: 17),
  titleSmall: TextStyle(fontSize: 15),
  bodyMedium: TextStyle(fontSize: 15),
  bodySmall: TextStyle(fontSize: 13),
  labelLarge: TextStyle(fontSize: 15),
  labelMedium: TextStyle(fontSize: 13),
  labelSmall: TextStyle(fontSize: 12),
);

/// Num botão, o foco do teclado é um contorno, que se vê sobre qualquer fundo.
ButtonStyle _buttonStyle(ColorScheme scheme) => _clickable.copyWith(
  side: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.focused)
        ? BorderSide(color: scheme.primary, width: 2)
        : null,
  ),
);

/// O barramento da sessão, para os controles de mídia.
DBusClient sessionBus() => DBusClient.session();

/// O tema do player: os papéis tonais do Material 3 a partir da cor de destaque.
/// Sem [accent], é a que quem abre o player traz como `primary`.
ThemeData playerTheme(
  ThemeData base, {
  Brightness brightness = Brightness.dark,
  Color? accent,
  bool compact = false,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: accent ?? base.colorScheme.primary,
    brightness: brightness,
  );
  final button = _buttonStyle(scheme);
  return ThemeData(
    colorScheme: scheme,
    textTheme: _textTheme,
    extensions: base.extensions.values,
    visualDensity: compact ? VisualDensity.compact : null,
    focusColor: scheme.primary.withValues(alpha: .3),
    sliderTheme: const SliderThemeData(
      mouseCursor: WidgetStateMouseCursor.clickable,
    ),
    iconButtonTheme: IconButtonThemeData(style: button),
    textButtonTheme: TextButtonThemeData(style: button),
    filledButtonTheme: FilledButtonThemeData(style: button),
    outlinedButtonTheme: OutlinedButtonThemeData(style: button),
    segmentedButtonTheme: const SegmentedButtonThemeData(style: _clickable),
    popupMenuTheme: const PopupMenuThemeData(
      mouseCursor: WidgetStateMouseCursor.clickable,
    ),
  );
}

/// O banco e o scanner, que abrem de forma assíncrona.
class LibraryServices {
  final LibraryStore store;
  final LibraryScanner scanner;
  final FolderWatcher? watcher;

  const LibraryServices(this.store, this.scanner, {this.watcher});
}

class PlayerView extends StatefulWidget {
  /// Cria o motor. Pode lançar, se faltar a biblioteca.
  final PlayerEngine Function() createEngine;

  /// Abre a biblioteca. Pode lançar.
  final Future<LibraryServices> Function() openLibrary;

  /// O que abre ao começar.
  final List<String> initialPaths;

  /// O seletor de pastas. Devolve o caminho, ou null se cancelaram.
  final Future<String?> Function(String title) pickFolder;

  /// O seletor de um arquivo M3U.
  final Future<String?> Function(String title) pickPlaylistFile;

  /// O seletor de onde gravar um arquivo, com o nome sugerido.
  final Future<String?> Function(String title, String suggestedName)
  pickSaveFile;

  /// A pasta de música da pessoa, se existe.
  final String? musicDir;

  /// Acha a letra de um arquivo. Sem isto, lê do disco, onde os Ajustes dizem.
  final LyricsLoader? readLyrics;

  /// O que pedem para abrir com o player já aberto. Vazio é só trazer a janela.
  final Stream<List<String>>? openRequests;

  /// Traz a janela para a frente, se quem abre o player sabe como.
  final Future<void> Function()? raiseWindow;

  /// O barramento dos controles de mídia. Sem isto, o player não os publica.
  final DBusClient Function()? connectBus;

  /// Abre uma pasta no gerenciador de arquivos.
  final Future<void> Function(String path) openFolder;

  const PlayerView({
    super.key,
    required this.createEngine,
    required this.openLibrary,
    required this.pickFolder,
    required this.pickPlaylistFile,
    required this.pickSaveFile,
    required this.openFolder,
    this.initialPaths = const [],
    this.musicDir,
    this.readLyrics,
    this.openRequests,
    this.raiseWindow,
    this.connectBus,
  });

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  PlayerEngine? _engine;
  LibraryStore? _store;
  LibraryController? _library;
  PlaybackController? _playback;
  LibrarySearch? _search;
  LyricsController? _lyrics;
  Mpris? _mpris;
  DBusClient? _bus;
  StreamSubscription<List<String>>? _opens;

  /// O que pediram para abrir antes da sessão voltar.
  var _pendingOpens = const <String>[];
  bool _restored = false;
  final _settings = PlayerSettings();
  final _searchFocus = FocusNode();

  /// O erro de abrir o motor ou a biblioteca.
  String? _engineError;
  String? _libraryError;

  PlayerDestination _destination = PlayerDestination.home;

  /// O que foi aberto a partir do destino: um álbum, um artista, um gênero, uma
  /// pasta ou uma playlist, com o que estava atrás.
  final _stack = <Object>[];

  /// A aba do painel Tocando agora, ou null fechado.
  PanelTab? _panel;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Fechar a janela encerra o processo sem passar pelo dispose
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async {
        await _playback?.saveSession();
        return AppExitResponse.exit;
      },
    );
    _settings.addListener(_onSettings);
    _opens = widget.openRequests?.listen(_onOpenRequest);
    try {
      _engine = widget.createEngine();
    } catch (e) {
      debugPrint('🎵 sem motor: $e');
      _engineError = '$e';
      return;
    }
    unawaited(_openLibrary());
  }

  void _onOpenRequest(List<String> paths) {
    unawaited(widget.raiseWindow?.call());
    if (paths.isEmpty) return;
    final playback = _playback;
    if (playback == null || !_restored) {
      _pendingOpens = paths;
    } else {
      unawaited(playback.playPaths(paths));
    }
  }

  bool _lyricsFiles = true;
  bool _lyricsEmbedded = true;
  bool? _gapless;
  PlayerReplayGain? _replayGain;

  void _applyAudio() {
    final engine = _engine;
    final s = _settings;
    if (engine == null) return;
    if (s.gapless != _gapless) {
      _gapless = s.gapless;
      unawaited(engine.setGapless(s.gapless));
    }
    if (s.replayGain != _replayGain) {
      _replayGain = s.replayGain;
      unawaited(engine.setReplayGain(s.replayGain));
    }
  }

  /// Mudar onde procurar letras vale para a faixa que está tocando.
  void _onSettings() {
    final s = _settings;
    _applyAudio();
    if (s.lyricsFiles == _lyricsFiles && s.lyricsEmbedded == _lyricsEmbedded) {
      return;
    }
    _lyricsFiles = s.lyricsFiles;
    _lyricsEmbedded = s.lyricsEmbedded;
    _lyrics?.reload();
  }

  Future<void> _publishMediaControls(PlaybackController playback) async {
    final connect = widget.connectBus;
    if (connect == null) return;
    final DBusClient bus;
    try {
      bus = connect();
    } catch (e) {
      debugPrint('🎵 sem barramento: $e');
      return;
    }
    final mpris = Mpris(
      playback,
      identity: 'Psito Player',
      onRaise: widget.raiseWindow,
      onQuit: () =>
          ServicesBinding.instance.exitApplication(AppExitType.cancelable),
    );
    if (await mpris.publish(bus) && mounted) {
      _bus = bus;
      _mpris = mpris;
    } else {
      await mpris.close();
      await bus.close();
    }
  }

  Future<void> _openLibrary() async {
    final LibraryServices services;
    try {
      services = await widget.openLibrary();
    } catch (e) {
      debugPrint('🎵 sem biblioteca: $e');
      if (mounted) setState(() => _libraryError = '$e');
      return;
    }
    if (!mounted) {
      unawaited(services.store.close());
      return;
    }
    _store = services.store;
    await _settings.load(services.store);
    _applyAudio();
    _lyricsFiles = _settings.lyricsFiles;
    _lyricsEmbedded = _settings.lyricsEmbedded;
    if (!mounted) return;
    final library = LibraryController(
      store: services.store,
      scanner: services.scanner,
      watcher: services.watcher,
    );
    final playback = PlaybackController(
      engine: _engine!,
      store: services.store,
      onLibraryChanged: () => unawaited(library.reload()),
      isAvailable: (path) => !library.isMissing(path),
      onNothingAvailable: () => _snack(context.l10n.nothingAvailable),
      playWholeList: () => _settings.playWholeList,
    );
    setState(() {
      _library = library;
      _playback = playback;
      _search = LibrarySearch(services.store);
      _lyrics = LyricsController(
        playback: playback,
        store: services.store,
        load:
            widget.readLyrics ??
            (path) => loadLyrics(
              path,
              files: _settings.lyricsFiles,
              embedded: _settings.lyricsEmbedded,
            ),
      );
    });
    await library.reload();
    if (!mounted) return;
    await playback.restore(
      open: widget.initialPaths,
      resume: _settings.rememberSession,
    );
    if (!mounted) return;
    _restored = true;
    if (_pendingOpens.isNotEmpty) {
      final paths = _pendingOpens;
      _pendingOpens = const [];
      await playback.playPaths(paths);
    }
    await _publishMediaControls(playback);
    if (!mounted) return;
    if (_settings.refreshOnOpen) await library.checkFolders();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    final playback = _playback;
    final store = _store;
    final engine = _engine;
    final mpris = _mpris;
    final bus = _bus;
    _lifecycle.dispose();
    unawaited(_opens?.cancel());
    _settings.removeListener(_onSettings);
    _settings.dispose();
    _lyrics?.dispose();
    _library?.dispose();
    _search?.dispose();
    _searchFocus.dispose();
    unawaited(() async {
      await mpris?.close();
      await bus?.close();
      await playback?.saveSession();
      playback?.dispose();
      await store?.close();
      await engine?.dispose();
    }());
    super.dispose();
  }

  void _navigate(PlayerDestination destination) {
    // Sem largura para os dois, o painel esconderia o destino
    final covers =
        MediaQuery.sizeOf(context).width < ShellTemplate.panelSideMinWidth;
    setState(() {
      _destination = destination;
      _stack.clear();
    });
    if (covers) _setPanel(null);
  }

  void _setPanel(PanelTab? tab) {
    _lyrics?.active = tab == PanelTab.lyrics;
    setState(() => _panel = tab);
  }

  /// O atalho de uma aba: abre nela e, se já está nela, fecha.
  void _togglePanel(PanelTab tab) => _setPanel(_panel == tab ? null : tab);

  Future<void> _saveQueue(List<String> paths) async {
    final l = context.l10n;
    final name = await askPlaylistName(
      context,
      title: l.saveAsPlaylist,
      action: l.create,
    );
    if (name == null || !mounted) return;
    await _library!.createPlaylist(name, paths);
    if (mounted) _snack(context.l10n.playlistSaved(name));
  }

  void _open(Object item) => setState(() => _stack.add(item));

  void _back() => setState(() => _stack.removeLast());

  void _openSearch([SearchFilter? filter]) {
    if (filter != null) _search?.setFilter(filter);
    _navigate(PlayerDestination.search);
    _searchFocus.requestFocus();
  }

  Future<void> _addFolder(String path) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await _library!.addFolder(path);
    final message = switch (result) {
      AddFolderResult.added => null,
      AddFolderResult.alreadyInLibrary => l.folderAlreadyAdded,
      AddFolderResult.notVisible => l.folderNotVisible,
    };
    if (message != null) {
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    } else if (mounted) {
      _navigate(PlayerDestination.library);
    }
  }

  Future<void> _pickFolder() async {
    final path = await widget.pickFolder(context.l10n.addFolder);
    if (path != null && mounted) await _addFolder(path);
  }

  Future<void> _createPlaylist() async {
    final l = context.l10n;
    final name = await askPlaylistName(
      context,
      title: l.newPlaylist,
      action: l.create,
    );
    if (name != null) await _library!.createPlaylist(name);
  }

  Future<void> _importPlaylist() async {
    final l = context.l10n;
    final path = await widget.pickPlaylistFile(l.importM3u);
    if (path == null || !mounted) return;
    try {
      final result = await _library!.importM3u(path);
      _snack(
        result.remote == 0
            ? l.imported(result.tracks)
            : '${l.imported(result.tracks)} · ${l.importedRemote(result.remote)}',
      );
    } on FileSystemException catch (e) {
      _snack(l.importFailed(e.osError?.message ?? e.message));
    }
  }

  Future<void> _exportPlaylist(String name, List<Track> tracks) async {
    final l = context.l10n;
    final path = await widget.pickSaveFile(l.exportM3u, '$name.m3u8');
    if (path == null || !mounted) return;
    try {
      await _library!.exportM3u(tracks, path);
    } on FileSystemException catch (e) {
      _snack(l.exportFailed(e.osError?.message ?? e.message));
    }
  }

  /// O que está aberto em cima do destino.
  Widget? _opened(LibraryController library, PlaybackController playback) {
    if (_stack.isEmpty) return null;
    final item = _stack.last;
    Widget tracks(String key, String title, Widget art, TrackQuery query) =>
        TracksPage(
          key: ValueKey(key),
          title: title,
          art: art,
          query: query,
          library: library,
          playback: playback,
          onBack: _back,
          onOpenAlbum: _open,
        );
    return switch (item) {
      final Album album => AlbumPage(
        key: ValueKey('album ${album.id}'),
        album: album,
        library: library,
        playback: playback,
        onBack: _back,
      ),
      final Artist artist => tracks(
        'artist ${artist.id}',
        artistName(artist.name, context),
        Monogram(name: artistName(artist.name, context)),
        TrackQuery(artistId: artist.id),
      ),
      final Genre genre => tracks(
        'genre ${genre.name}',
        genreName(genre.name, context),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GenericArt(seed: genreName(genre.name, context)),
        ),
        TrackQuery(genre: genre.name, sort: TrackSort.artist),
      ),
      final MusicDir dir => tracks(
        'dir ${dir.path}',
        prettyPath(dir.path, Platform.environment['HOME']),
        Icon(
          Icons.folder_rounded,
          size: 96,
          color: Theme.of(context).colorScheme.primary,
        ),
        TrackQuery(dir: dir.path, sort: TrackSort.album),
      ),
      final Playlist playlist => PlaylistPage(
        key: ValueKey('playlist ${playlist.kind.name} ${playlist.id}'),
        playlist: playlist,
        library: library,
        playback: playback,
        onBack: _back,
        onExport: _exportPlaylist,
      ),
      _ => throw ArgumentError.value(item),
    };
  }

  Widget _page(LibraryController library, PlaybackController playback) {
    final opened = _opened(library, playback);
    if (opened != null) return opened;
    final emptyHere =
        library.empty &&
        (_destination == PlayerDestination.home ||
            _destination == PlayerDestination.library);
    if (emptyHere) {
      return EmptyLibraryPage(
        musicDir: widget.musicDir,
        onAddFolder: () => unawaited(_pickFolder()),
        onUseFolder: (path) => unawaited(_addFolder(path)),
      );
    }
    return switch (_destination) {
      PlayerDestination.home => HomePage(
        library: library,
        playback: playback,
        onOpen: _open,
        onSeeLibrary: (section) {
          library.setSection(section);
          _navigate(PlayerDestination.library);
        },
        onSeePlaylists: () => _navigate(PlayerDestination.playlists),
      ),
      PlayerDestination.library => LibraryPage(
        library: library,
        playback: playback,
        onOpen: _open,
        onSearch: _openSearch,
      ),
      PlayerDestination.folders => FoldersPage(
        library: library,
        onAddFolder: () => unawaited(_pickFolder()),
      ),
      PlayerDestination.playlists => PlaylistsPage(
        library: library,
        onOpen: _open,
        onCreate: () => unawaited(_createPlaylist()),
        onImport: () => unawaited(_importPlaylist()),
      ),
      PlayerDestination.search => SearchPage(
        search: _search!,
        library: library,
        playback: playback,
        focusNode: _searchFocus,
        onOpen: _open,
      ),
      PlayerDestination.settings => SettingsPage(
        settings: _settings,
        library: library,
        dataDir: _dataDir,
        onOpenFolders: () => _navigate(PlayerDestination.folders),
        onOpenDataFolder: () => unawaited(widget.openFolder(_dataDir)),
      ),
    };
  }

  String get _dataDir => p.dirname(libraryPaths(Platform.environment).db);

  Widget _shell(LibraryController library, PlaybackController playback) =>
      ListenableBuilder(
        listenable: Listenable.merge([library, playback]),
        builder: (context, _) => PlayerActions(
          library: library,
          playback: playback,
          exportPlaylist: _exportPlaylist,
          child: Focus(
            autofocus: true,
            onKeyEvent: (_, event) => handlePlayerKey(
              event,
              playback,
              shortcuts: _settings.shortcuts,
              onSearch: _openSearch,
              onLyrics: () => _togglePanel(PanelTab.lyrics),
              onQueue: () => _togglePanel(PanelTab.queue),
            ),
            child: ShellTemplate(
              rail: PlayerRail(
                selected: _destination,
                onSelected: _navigate,
                onAddFolder: () => unawaited(_pickFolder()),
              ),
              compactNav: CompactNavigation(
                selected: _destination,
                onSelected: _navigate,
                onAddFolder: () => unawaited(_pickFolder()),
              ),
              content: _page(library, playback),
              panel: _panel == null
                  ? null
                  : NowPlayingPanel(
                      tab: _panel!,
                      playback: playback,
                      lyrics: _lyrics!,
                      store: _store!,
                      onTab: _setPanel,
                      onClose: () => _setPanel(null),
                      onSaveQueue: (paths) => unawaited(_saveQueue(paths)),
                    ),
              bar: PlayerBar(
                playback: playback,
                canOpenPanel:
                    MediaQuery.sizeOf(context).height >=
                    ShellTemplate.contentMinHeight,
                onOpenPanel: _setPanel,
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _settings,
    builder: (context, _) => _themed(context),
  );

  Widget _themed(BuildContext context) {
    final s = _settings;
    final media = MediaQuery.of(context);
    final theme = playerTheme(
      Theme.of(context),
      brightness: switch (s.themeMode) {
        ThemeMode.dark => Brightness.dark,
        ThemeMode.light => Brightness.light,
        ThemeMode.system => media.platformBrightness,
      },
      accent: s.accent?.color,
      compact: s.compact,
    );
    final library = _library;
    final playback = _playback;
    final Widget body;
    if (_engineError != null) {
      body = _Message(context.l10n.engineUnavailable(_engineError!));
    } else if (_libraryError != null) {
      body = _Message(context.l10n.libraryUnavailable(_libraryError!));
    } else if (library == null || playback == null) {
      body = const SizedBox.expand();
    } else {
      body = _shell(library, playback);
    }
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(media.textScaler.scale(1) * s.textScale),
        disableAnimations: media.disableAnimations || s.reduceMotion,
      ),
      child: Theme(
        data: theme,
        child: Scaffold(backgroundColor: theme.colorScheme.surface, body: body),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;

  const _Message(this.text);

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Text(text),
    ),
  );
}

/// Onde o banco e as miniaturas ficam.
LibraryServicesPaths libraryPaths(Map<String, String> env) {
  final home = env['HOME'] ?? '.';
  final data = env['XDG_DATA_HOME'] ?? p.join(home, '.local', 'share');
  final cache = env['XDG_CACHE_HOME'] ?? p.join(home, '.cache');
  return (
    db: p.join(data, 'psito', 'player', 'library.db'),
    covers: p.join(cache, 'psito', 'player', 'covers'),
  );
}

typedef LibraryServicesPaths = ({String db, String covers});

Future<LibraryServices> openLibraryServices() async {
  final paths = libraryPaths(Platform.environment);
  await Directory(p.dirname(paths.db)).create(recursive: true);
  await Directory(paths.covers).create(recursive: true);
  return LibraryServices(
    await IsolateStore.open(paths.db),
    IsolateScanner(dbPath: paths.db, coverDir: paths.covers),
    watcher: DirectoryWatcher(),
  );
}
