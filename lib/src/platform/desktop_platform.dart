// lib/src/platform/desktop_platform.dart
//
// O que o player pede ao sistema operacional. Cada sistema responde num arquivo
// desta pasta, e o resto do player só conhece esta interface.
import 'dart:io';

import '../player/playback_controller.dart';
import '../settings/player_settings.dart';
import 'linux_desktop.dart';
import 'windows_desktop.dart';

/// Onde o banco e as miniaturas ficam.
typedef LibraryServicesPaths = ({
  String db,
  String covers,
  String playlistCovers,
  String tagUndo,
});

/// Este processo do player, depois de ganhar a vaga de instância única.
abstract interface class AppInstance {
  /// O que pediram para abrir depois. Vazio é só trazer a janela.
  Stream<List<String>> get opens;
}

/// A ligação do player com o desktop enquanto ele está aberto: os controles de
/// mídia, não deixar a tela apagar e o aviso da faixa nova.
abstract interface class DesktopSession {
  /// Para de ouvir o player antes da primeira espera, porque quem chama descarta
  /// os Ajustes logo depois.
  Future<void> close();
}

/// O que a sessão com o desktop precisa saber do player.
class DesktopSessionRequest {
  final PlaybackController playback;
  final PlayerSettings settings;

  /// O motivo que o desktop mostra ao dizer quem está segurando a tela.
  final String awakeReason;

  /// Traz a janela para a frente, se quem abriu o player sabe como.
  final Future<void> Function()? onRaise;
  final Future<void> Function() onQuit;

  /// Se o player ainda está aberto, depois de cada espera.
  final bool Function() isOpen;

  const DesktopSessionRequest({
    required this.playback,
    required this.settings,
    required this.awakeReason,
    required this.onRaise,
    required this.onQuit,
    required this.isOpen,
  });
}

/// Por que o sistema recusou mexer num arquivo.
enum FileProblem {
  readOnlyDisk,
  noPermission,
  missing,
  noSpace,
  inUse,
  otherDisk,
}

abstract interface class DesktopPlatform {
  /// A pasta que a tela encurta para `~`. Nula onde isso não é costume.
  String? get homeDir;

  /// A pasta de música da pessoa, se existir.
  String? get musicDir;

  LibraryServicesPaths get libraryPaths;

  /// Abre uma pasta no gerenciador de arquivos, ou um endereço no navegador.
  Future<void> open(String pathOrUrl);

  /// Mostra um arquivo selecionado no gerenciador. Devolve se conseguiu.
  Future<bool> reveal(String path);

  /// Devolve esta instância, ou null se outra recebeu os [paths]. Se não der para
  /// saber, abre do mesmo jeito.
  Future<AppInstance?> claimInstance(List<String> paths);

  /// Liga o player ao desktop. Nulo se o desktop não atender, e o player toca
  /// sem isso.
  Future<DesktopSession?> openSession(DesktopSessionRequest request);

  /// O espaço livre e o tipo do disco de [path], ou nulo se não der para saber.
  (int, String)? diskInfo(String path);

  /// Devolve a [path] o modo que o arquivo original tinha, onde isso existe.
  void restoreFileMode(String path, int mode);

  /// O que quer dizer um código de erro do sistema. Nulo se não for nenhum destes.
  FileProblem? fileProblem(int osError);

  /// Um arquivo aberto por alguém não pode ser substituído.
  bool get openFilesBlockReplace;

  /// Todo disco segue as regras de nome do NTFS, qualquer que seja o tipo dele.
  bool get strictNames;

  /// Se os dois caminhos são o mesmo arquivo para o sistema.
  bool samePath(String a, String b);

  /// O arquivo só está na nuvem: ler o conteúdo dele faria o download.
  bool isCloudOnly(String path);

  /// Os [paths] como estão no disco, para um arquivo não entrar duas vezes na
  /// biblioteca por causa de maiúsculas.
  List<String> realPaths(List<String> paths);

  /// Observar uma pasta inclui as de dentro. Senão, cada uma tem a sua observação.
  bool get watchesSubfolders;

  /// O sistema mostra o aviso de faixa nova.
  bool get showsTrackNotice;
}

/// O sistema em que o player está rodando.
final DesktopPlatform desktopPlatform = Platform.isLinux
    ? LinuxDesktop()
    : Platform.isWindows
    ? WindowsDesktop()
    : throw UnsupportedError(Platform.operatingSystem);
