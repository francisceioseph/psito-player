// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'player_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class PlayerLocalizationsPt extends PlayerLocalizations {
  PlayerLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Player de música';

  @override
  String get noTrack => 'Nenhuma faixa';

  @override
  String get play => 'Tocar';

  @override
  String get pause => 'Pausar';

  @override
  String get progress => 'Progresso';

  @override
  String get volume => 'Volume';

  @override
  String get home => 'Início';

  @override
  String get library => 'Biblioteca';

  @override
  String get playlists => 'Playlists';

  @override
  String get folders => 'Pastas';

  @override
  String get search => 'Buscar';

  @override
  String get settings => 'Ajustes';

  @override
  String engineUnavailable(Object error) {
    return 'O motor de áudio não está disponível: $error';
  }

  @override
  String get openFailed => 'Não foi possível tocar este arquivo';

  @override
  String get addFolder => 'Adicionar pasta';

  @override
  String get addMusicFolder => 'Adicionar pasta de músicas';

  @override
  String get folderNotVisible =>
      'O player não enxerga esta pasta. Escolha uma no seu home ou num disco externo.';

  @override
  String get folderAlreadyAdded => 'Esta pasta já está na biblioteca.';

  @override
  String libraryUnavailable(String error) {
    return 'Não foi possível abrir a biblioteca: $error';
  }

  @override
  String get albums => 'Álbuns';

  @override
  String get unknownArtist => 'Artista desconhecido';

  @override
  String playAlbum(String album) {
    return 'Tocar $album';
  }

  @override
  String get hasLyrics => 'Tem letra';

  @override
  String get moreOptions => 'Mais opções';

  @override
  String get playNext => 'Tocar a seguir';

  @override
  String get addToQueue => 'Adicionar à fila';

  @override
  String get removeFromQueue => 'Tirar da fila';

  @override
  String get queue => 'Fila';

  @override
  String get queueEmpty => 'A fila está vazia';

  @override
  String get close => 'Fechar';

  @override
  String get shuffle => 'Aleatório';

  @override
  String get previousTrack => 'Faixa anterior';

  @override
  String get nextTrack => 'Próxima faixa';

  @override
  String get repeatOff => 'Repetir: desligado';

  @override
  String get repeatAll => 'Repetir: tudo';

  @override
  String get repeatOne => 'Repetir: esta faixa';

  @override
  String get continueListening => 'Continuar de onde parou';

  @override
  String get continuePlaying => 'Continuar';

  @override
  String stoppedAt(String artist, String position, String duration) {
    return '$artist · parou em $position de $duration';
  }

  @override
  String get shuffleAll => 'Tudo em aleatório';

  @override
  String get recentlyAdded => 'Adicionados recentemente';

  @override
  String get seeAll => 'Ver tudo';

  @override
  String get mostPlayed => 'Mais tocadas';

  @override
  String get emptyTitle => 'Sua biblioteca está vazia';

  @override
  String get emptyBody =>
      'Aponte para a pasta onde ficam suas músicas. O player lê os arquivos direto do seu computador e não envia nada para fora.';

  @override
  String useFolder(String folder) {
    return 'Usar $folder';
  }

  @override
  String get acceptedFormats => 'Formatos aceitos';

  @override
  String get scanning => 'Lendo sua biblioteca';

  @override
  String get scanSubtitle =>
      'Leitura em andamento: você já pode ouvir o que foi encontrado';

  @override
  String scanFiles(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString de $totalString arquivos';
  }

  @override
  String get scanLessThanMinute => 'menos de 1 min restante';

  @override
  String scanMinutesLeft(int n) {
    return 'cerca de $n min restantes';
  }

  @override
  String get pauseScan => 'Pausar';

  @override
  String get resumeScan => 'Continuar';

  @override
  String get cancelScan => 'Cancelar';

  @override
  String get scanKeepsGoing => 'A leitura continua se você fechar esta tela';

  @override
  String get foundSoFar => 'Encontrados até agora';

  @override
  String get updateAll => 'Atualizar tudo';

  @override
  String get updateFolder => 'Atualizar pasta';

  @override
  String get removeFolder => 'Remover da biblioteca';

  @override
  String get folderMissing => 'Disco não encontrado';

  @override
  String get notScanned => 'Ainda não lida';

  @override
  String get scannedJustNow => 'Atualizada agora';

  @override
  String scannedMinutes(int n) {
    return 'Atualizada há $n min';
  }

  @override
  String scannedHours(int n) {
    return 'Atualizada há $n h';
  }

  @override
  String scannedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Atualizada há $n dias',
      one: 'Atualizada ontem',
      zero: 'Atualizada hoje',
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
      other: '$nString álbuns',
      one: '1 álbum',
      zero: '0 álbum',
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
      other: '$nString músicas',
      one: '1 música',
      zero: '0 música',
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
      other: '$nString pastas',
      one: '1 pasta',
      zero: '0 pasta',
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
      other: '$nString capas encontradas',
      one: '1 capa encontrada',
      zero: '0 capa encontrada',
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
      other: '$nString arquivos ignorados',
      one: '1 arquivo ignorado',
      zero: '0 arquivo ignorado',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Voltar';

  @override
  String get songs => 'Músicas';

  @override
  String get artists => 'Artistas';

  @override
  String get genres => 'Gêneros';

  @override
  String get allFilter => 'Tudo';

  @override
  String get allSongs => 'Todas';

  @override
  String get favorites => 'Favoritas';

  @override
  String get mineFilter => 'Minhas';

  @override
  String get automaticFilter => 'Automáticas';

  @override
  String get addFavorite => 'Marcar como favorita';

  @override
  String get removeFavorite => 'Tirar das favoritas';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortRecent => 'Recentes';

  @override
  String get sortAZ => 'A a Z';

  @override
  String get sortArtist => 'Artista';

  @override
  String get sortYear => 'Ano';

  @override
  String get sortMostTracks => 'Mais músicas';

  @override
  String get columnTitle => 'Título';

  @override
  String get columnAlbum => 'Álbum';

  @override
  String get columnDuration => 'Duração';

  @override
  String get columnFormat => 'Formato';

  @override
  String get viewGrid => 'Grade';

  @override
  String get viewList => 'Lista';

  @override
  String get searchHint => 'Buscar na biblioteca';

  @override
  String get searchSongsHint => 'Buscar músicas';

  @override
  String get searchArtistsHint => 'Buscar artistas';

  @override
  String get searchGenresHint => 'Buscar gêneros';

  @override
  String get searchAlbumsHint => 'Buscar álbuns';

  @override
  String get searchFoldersHint => 'Buscar pastas';

  @override
  String get searchAllHint => 'Músicas, álbuns, artistas ou pastas';

  @override
  String get searchShortcut => 'Ctrl K';

  @override
  String get clearSearch => 'Limpar a busca';

  @override
  String noResults(String query) {
    return 'Nada encontrado para \"$query\"';
  }

  @override
  String get searchPrompt => 'Digite para buscar na sua biblioteca.';

  @override
  String get bestResult => 'Melhor resultado';

  @override
  String get playAll => 'Tocar tudo';

  @override
  String get kindArtist => 'Artista';

  @override
  String get kindAlbum => 'Álbum';

  @override
  String get kindSong => 'Música';

  @override
  String get nothingHere => 'Nada por aqui ainda.';

  @override
  String get noGenre => 'Sem gênero';

  @override
  String get fileUnavailable => 'Este arquivo não está disponível agora';

  @override
  String get nothingAvailable =>
      'Estas músicas não estão disponíveis. O disco está ligado?';

  @override
  String get watchFolders => 'Observar mudanças nas pastas';

  @override
  String get watchFoldersBody =>
      'Detecta arquivos novos, alterados e removidos enquanto o player está aberto.';

  @override
  String get newPlaylist => 'Nova playlist';

  @override
  String get importPlaylist => 'Importar playlist';

  @override
  String get exportPlaylist => 'Exportar playlist';

  @override
  String get renamePlaylist => 'Renomear';

  @override
  String get deletePlaylist => 'Excluir playlist';

  @override
  String deletePlaylistBody(String name) {
    return 'Excluir \"$name\"? Os arquivos de música continuam onde estão.';
  }

  @override
  String get delete => 'Excluir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get create => 'Criar';

  @override
  String get playlistName => 'Nome da playlist';

  @override
  String get addToPlaylist => 'Adicionar à playlist';

  @override
  String get removeFromPlaylist => 'Tirar da playlist';

  @override
  String get moveUp => 'Mover para cima';

  @override
  String get moveDown => 'Mover para baixo';

  @override
  String get dragToReorder => 'Arrastar para reordenar';

  @override
  String get autoFavorites => 'Favoritas';

  @override
  String get autoMostPlayed => 'Mais tocadas';

  @override
  String get autoRecent => 'Adicionadas recentemente';

  @override
  String get automaticSuffix => 'automática';

  @override
  String exportFailed(String error) {
    return 'Não foi possível gravar o arquivo: $error';
  }

  @override
  String importFailed(String error) {
    return 'Não foi possível ler o arquivo: $error';
  }

  @override
  String lengthDays(int d, int h) {
    return '$d dias e $h h';
  }

  @override
  String artistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n artistas',
      one: '1 artista',
      zero: '0 artista',
    );
    return '$_temp0';
  }

  @override
  String genreCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gêneros',
      one: '1 gênero',
      zero: '0 gênero',
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
      zero: '0 playlist',
    );
    return '$_temp0';
  }

  @override
  String fileCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n arquivos',
      one: '1 arquivo',
      zero: '0 arquivo',
    );
    return '$_temp0';
  }

  @override
  String folderChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n alterações',
      one: '1 alteração',
      zero: '0 alteração',
    );
    return '$_temp0';
  }

  @override
  String imported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n músicas importadas',
      one: '1 música importada',
      zero: '0 música importada',
    );
    return '$_temp0';
  }

  @override
  String importedRemote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n endereços da rede ignorados',
      one: '1 endereço da rede ignorado',
      zero: '0 endereço da rede ignorado',
    );
    return '$_temp0';
  }

  @override
  String get lyricsTab => 'Letra';

  @override
  String get coverTab => 'Capa';

  @override
  String get noLyrics => 'Esta faixa não tem letra';

  @override
  String get lyricsSynced => 'sincronizada';

  @override
  String get lyricsUnsynced => 'sem tempo';

  @override
  String get lyricsEmbedded => 'Nas tags';

  @override
  String get lyricsTiming => 'Ajustar o tempo da letra';

  @override
  String get lyricsEarlier => 'Adiantar a letra';

  @override
  String get lyricsLater => 'Atrasar a letra';

  @override
  String get lyricsResetTiming => 'Zerar o ajuste';

  @override
  String get withLyrics => 'Com letra';

  @override
  String get upNext => 'A seguir';

  @override
  String get clearQueue => 'Limpar';

  @override
  String get saveAsPlaylist => 'Salvar como playlist';

  @override
  String get detailAlbum => 'Álbum';

  @override
  String get detailGenre => 'Gênero';

  @override
  String get detailFile => 'Arquivo';

  @override
  String get detailCover => 'Capa';

  @override
  String get detailFolder => 'Pasta';

  @override
  String get coverEmbedded => 'Embutida';

  @override
  String get coverGenerated => 'Gerada';

  @override
  String secondsOffset(String value) {
    return '$value s';
  }

  @override
  String playlistSaved(String name) {
    return 'Salva como “$name”';
  }

  @override
  String get settingsPlayback => 'Reprodução';

  @override
  String get settingsEqualizer => 'Equalizador';

  @override
  String get equalizerOn => 'Usar o equalizador';

  @override
  String get equalizerHint =>
      'Baixa um pouco o volume geral para dar espaço às bandas aumentadas, e o som não distorce.';

  @override
  String get equalizerPresets => 'Predefinições';

  @override
  String get equalizerCustom => 'Personalizada';

  @override
  String get equalizerFlat => 'Plana';

  @override
  String get equalizerRock => 'Rock';

  @override
  String get equalizerPop => 'Pop';

  @override
  String get equalizerJazz => 'Jazz';

  @override
  String get equalizerClassical => 'Clássica';

  @override
  String get equalizerElectronic => 'Eletrônica';

  @override
  String get equalizerBass => 'Mais graves';

  @override
  String get equalizerTreble => 'Mais agudos';

  @override
  String get equalizerVocal => 'Voz';

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
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsShortcuts => 'Atalhos de teclado';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get rememberSession => 'Lembrar a última faixa';

  @override
  String get rememberSessionHint =>
      'Reabre a fila no ponto em que parou, sem tocar.';

  @override
  String get playWholeList => 'Tocar a lista inteira ao escolher uma faixa';

  @override
  String get playWholeListHint => 'Desligado, toca só a faixa escolhida.';

  @override
  String get closeNote => 'Fechar a janela encerra o player e para a música.';

  @override
  String get stopAfterTrack => 'Parar depois desta faixa';

  @override
  String get cancelStopAfter => 'Continuar tocando depois desta faixa';

  @override
  String get showInFiles => 'Mostrar no gerenciador de arquivos';

  @override
  String get keepAwake => 'Manter o computador acordado enquanto toca';

  @override
  String get keepAwakeHint =>
      'A tela fica ligada e o computador não suspende sozinho. Pausado, volta ao normal.';

  @override
  String get keepAwakeReason => 'Tocando música';

  @override
  String get notifyTrack => 'Avisar quando a faixa mudar';

  @override
  String get notifyTrackHint =>
      'Mostra o título e o artista numa notificação do sistema.';

  @override
  String get shuffleOrder => 'Embaralhar a ordem';

  @override
  String get playlistShuffled => 'Ordem embaralhada';

  @override
  String get removeDuplicates => 'Remover duplicadas';

  @override
  String duplicatesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicadas removidas',
      one: '1 duplicada removida',
      zero: 'Nenhuma duplicada removida',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Desfazer';

  @override
  String get gapless => 'Tocar sem pausa entre as faixas';

  @override
  String get gaplessHint =>
      'Desligado, a saída de som fecha e abre entre as faixas.';

  @override
  String get replayGain => 'ReplayGain';

  @override
  String get replayGainOff => 'Desligado';

  @override
  String get replayGainTrack => 'Faixa';

  @override
  String get replayGainAlbum => 'Álbum';

  @override
  String get replayGainHint =>
      'Iguala o volume com os valores gravados nas tags. Álbum mantém as diferenças dentro de um álbum. Arquivos sem esses valores tocam como estão.';

  @override
  String get libraryFolders => 'Pastas da biblioteca';

  @override
  String get watchFoldersSetting => 'Observar mudanças nas pastas';

  @override
  String get watchFoldersHint =>
      'Arquivos novos, alterados e removidos aparecem com o player aberto.';

  @override
  String get refreshOnOpen => 'Atualizar ao abrir';

  @override
  String get refreshOnOpenHint => 'Confere as pastas sempre que o player abre.';

  @override
  String get refreshNow => 'Atualizar agora';

  @override
  String get lyricsFiles => 'Procurar arquivos .lrc e .srt';

  @override
  String get lyricsFilesHint => 'Ao lado da música, com o mesmo nome.';

  @override
  String get lyricsEmbeddedSetting => 'Usar letras embutidas';

  @override
  String get lyricsEmbeddedHint =>
      'Das tags do arquivo, quando não há arquivo de letra.';

  @override
  String get themeSetting => 'Tema';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get dynamicColor => 'Cor dinâmica do sistema';

  @override
  String get dynamicColorHint =>
      'Usa as cores do papel de parede, quando o sistema oferecer.';

  @override
  String get accentSetting => 'Cor de destaque';

  @override
  String get accentDefault => 'Padrão';

  @override
  String get accentCoral => 'Coral';

  @override
  String get accentAmber => 'Âmbar';

  @override
  String get accentGreen => 'Verde';

  @override
  String get accentTeal => 'Turquesa';

  @override
  String get accentBlue => 'Azul';

  @override
  String get accentPurple => 'Roxo';

  @override
  String get densitySetting => 'Densidade das listas';

  @override
  String get densityComfortable => 'Confortável';

  @override
  String get densityCompact => 'Compacta';

  @override
  String get textSizeSetting => 'Tamanho do texto';

  @override
  String get reduceMotion => 'Reduzir animações';

  @override
  String get reduceMotionHint =>
      'Desliga a rolagem animada da letra e as outras animações.';

  @override
  String get resetShortcuts => 'Restaurar padrões';

  @override
  String get mediaKeysNote =>
      'As teclas de mídia do teclado (tocar, pausar, próxima, anterior) funcionam sem configurar nada.';

  @override
  String get commandPlayPause => 'Tocar e pausar';

  @override
  String get commandSeekBack => 'Voltar 5 segundos';

  @override
  String get commandSeekForward => 'Avançar 5 segundos';

  @override
  String get commandPrevious => 'Faixa anterior';

  @override
  String get commandNext => 'Próxima faixa';

  @override
  String get commandMute => 'Silenciar';

  @override
  String get commandSearch => 'Buscar';

  @override
  String get commandLyrics => 'Abrir e fechar a letra';

  @override
  String get commandQueue => 'Abrir e fechar a fila';

  @override
  String get keySpace => 'Espaço';

  @override
  String changeShortcut(String command) {
    return 'Mudar o atalho: $command';
  }

  @override
  String get pressKeys => 'Aperte as novas teclas. Esc cancela.';

  @override
  String shortcutInUse(String command) {
    return 'Já é usado por: $command';
  }

  @override
  String get aboutDescription =>
      'Toca os arquivos que estão no seu computador. Sem conta, sem streaming e sem rastreamento: o que você ouve fica com você.';

  @override
  String versionLabel(String version) {
    return 'Versão $version';
  }

  @override
  String get licenseLabel => 'Licença: Apache 2.0';

  @override
  String get thirdPartyLicenses => 'Textos completos das licenças';

  @override
  String get builtWithClaude => 'Desenvolvido com o auxílio do Claude Code.';

  @override
  String get reportIssue => 'Relatar um problema no GitHub';

  @override
  String get designInspiration => 'Inspiração do design';

  @override
  String get dartPackagesLabel => 'Licenças: pacotes Dart';

  @override
  String get systemLibrariesLabel => 'Licenças: bibliotecas do sistema';

  @override
  String get interfaceAssetsLabel => 'Licenças: ícones';

  @override
  String get keepLogs => 'Registrar logs';

  @override
  String get keepLogsHint =>
      'Para investigar um problema. Incluem nomes de músicas e caminhos, e ficam só neste computador.';

  @override
  String get aboutSupport => 'Suporte';

  @override
  String get openDataFolder => 'Abrir a pasta de dados';

  @override
  String get copySupportInfo => 'Copiar informações para suporte';

  @override
  String get supportInfoCopied => 'Copiado';

  @override
  String addedToPlaylist(String name) {
    return 'Adicionado a “$name”';
  }

  @override
  String get addTracks => 'Adicionar músicas';

  @override
  String addTracksConfirm(int n) {
    return 'Adicionar $n';
  }

  @override
  String get alreadyInPlaylist => 'Já está nesta playlist';

  @override
  String get searchTracksHint => 'Buscar músicas';

  @override
  String get playlistEmptyHint =>
      'Esta playlist está vazia. Use Adicionar músicas para preencher.';

  @override
  String tracksAdded(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n músicas adicionadas',
      one: '1 música adicionada',
      zero: '0 músicas adicionadas',
    );
    return '$_temp0';
  }

  @override
  String get nowPlaying => 'Tocando agora';

  @override
  String get yourLibrary => 'Sua biblioteca';

  @override
  String get rediscover => 'Para redescobrir';

  @override
  String get yourPlaylists => 'Suas playlists';

  @override
  String get filterList => 'Buscar nesta lista';

  @override
  String get recentSearches => 'Buscas recentes';

  @override
  String get clearRecent => 'Limpar';

  @override
  String get removeRecent => 'Tirar das buscas recentes';

  @override
  String get browseGenres => 'Explorar por gênero';

  @override
  String get pin => 'Fixar';

  @override
  String get unpin => 'Desafixar';

  @override
  String get pinned => 'Fixado';

  @override
  String get pinnedHeading => 'Fixados';

  @override
  String get yourMixes => 'Seus mixes';

  @override
  String get dailyMix => 'Mix do dia';

  @override
  String genreMix(String genre) {
    return 'Mix de $genre';
  }

  @override
  String get openTrackPage => 'Abrir a tela da música';

  @override
  String get trackDetails => 'Detalhes';

  @override
  String get overview => 'Visão geral';

  @override
  String get singles => 'Músicas avulsas';

  @override
  String singlesHint(String tracks) {
    return '$tracks sozinhas no álbum';
  }

  @override
  String get expandRail => 'Mostrar os nomes';

  @override
  String get collapseRail => 'Esconder os nomes';

  @override
  String get playerSize => 'Tamanho do player';

  @override
  String get modeFull => 'Completo';

  @override
  String get modeCompact => 'Compacto';

  @override
  String get modeMini => 'Miniplayer';

  @override
  String get exitMini => 'Sair do miniplayer';

  @override
  String get autoTopRated => 'Mais bem avaliadas';

  @override
  String get rateTrack => 'Dar nota…';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas',
      one: '1 estrela',
      zero: '0 estrela',
    );
    return '$_temp0';
  }

  @override
  String get clearRating => 'Tirar a nota';

  @override
  String get dynamicMixStart => 'Ligar o mix dinâmico';

  @override
  String get dynamicMixStop => 'Desligar o mix dinâmico';

  @override
  String get columnRating => 'Nota';

  @override
  String get useRatings => 'Usar notas por estrelas';

  @override
  String get useRatingsHint =>
      'Mostra as estrelas junto do coração. Desligado, as notas que você deu ficam guardadas, e as músicas com uma estrela continuam fora dos mixes.';

  @override
  String markAll(int n) {
    return 'Marcar todas ($n)';
  }

  @override
  String get clearSelection => 'Limpar seleção';

  @override
  String createWithTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Criar com $n músicas',
      one: 'Criar com 1 música',
      zero: 'Criar com 0 músicas',
    );
    return '$_temp0';
  }
}
