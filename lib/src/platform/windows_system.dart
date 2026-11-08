// lib/src/platform/windows_system.dart
//
// As chamadas à API do Windows. As bibliotecas só abrem no primeiro uso, e cada
// chamada que falha responde como se o Windows não soubesse.
import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// O que o player pergunta ao Windows.
abstract interface class WindowsSystem {
  /// A pasta Música de verdade: ela pode ter sido levada para o OneDrive.
  String? musicFolder();

  /// O espaço livre e o tipo do disco de [path].
  (int, String)? diskInfo(String path);

  /// Não deixa a tela apagar nem o computador dormir.
  void keepAwake(bool on);

  /// Deixa a janela do player que já está aberta vir para a frente.
  void allowForeground();
}

const _maxPath = 32768;
const _esContinuous = 0x80000000;
const _esSystemRequired = 0x00000001;
const _esDisplayRequired = 0x00000002;
const _asfwAny = 0xFFFFFFFF;

// {4BD8D571-6D19-48D3-BE97-422220080E43}
const _musicFolderId = [
  0x71, 0xD5, 0xD8, 0x4B, 0x19, 0x6D, 0xD3, 0x48, //
  0xBE, 0x97, 0x42, 0x22, 0x20, 0x08, 0x0E, 0x43,
];

typedef _KnownFolderC = Int32 Function(
  Pointer<Uint8>,
  Uint32,
  IntPtr,
  Pointer<Pointer<Utf16>>,
);
typedef _KnownFolderDart = int Function(
  Pointer<Uint8>,
  int,
  int,
  Pointer<Pointer<Utf16>>,
);
typedef _DiskFreeC = Int32 Function(
  Pointer<Utf16>,
  Pointer<Uint64>,
  Pointer<Uint64>,
  Pointer<Uint64>,
);
typedef _DiskFreeDart = int Function(
  Pointer<Utf16>,
  Pointer<Uint64>,
  Pointer<Uint64>,
  Pointer<Uint64>,
);
typedef _VolumePathC = Int32 Function(Pointer<Utf16>, Pointer<Utf16>, Uint32);
typedef _VolumePathDart = int Function(Pointer<Utf16>, Pointer<Utf16>, int);
typedef _VolumeInfoC = Int32 Function(
  Pointer<Utf16>,
  Pointer<Utf16>,
  Uint32,
  Pointer<Uint32>,
  Pointer<Uint32>,
  Pointer<Uint32>,
  Pointer<Utf16>,
  Uint32,
);
typedef _VolumeInfoDart = int Function(
  Pointer<Utf16>,
  Pointer<Utf16>,
  int,
  Pointer<Uint32>,
  Pointer<Uint32>,
  Pointer<Uint32>,
  Pointer<Utf16>,
  int,
);

/// O nome do Windows no nome que o Linux dá ao mesmo sistema de arquivos.
String fileSystemName(String windowsName) {
  final name = windowsName.toLowerCase();
  return name == 'fat' || name == 'fat32' ? 'vfat' : name;
}

class Win32System implements WindowsSystem {
  const Win32System();

  static final _kernel32 = DynamicLibrary.open('kernel32.dll');
  static final _shell32 = DynamicLibrary.open('shell32.dll');
  static final _ole32 = DynamicLibrary.open('ole32.dll');
  static final _user32 = DynamicLibrary.open('user32.dll');

  @override
  String? musicFolder() {
    final known = _shell32.lookupFunction<_KnownFolderC, _KnownFolderDart>(
      'SHGetKnownFolderPath',
    );
    final free = _ole32
        .lookupFunction<Void Function(Pointer), void Function(Pointer)>(
          'CoTaskMemFree',
        );
    return using((arena) {
      final id = arena<Uint8>(_musicFolderId.length);
      id.asTypedList(_musicFolderId.length).setAll(0, _musicFolderId);
      final out = arena<Pointer<Utf16>>();
      final failed = known(id, 0, 0, out) < 0;
      final path = failed ? null : out.value.toDartString();
      free(out.value);
      return path;
    });
  }

  @override
  (int, String)? diskInfo(String path) {
    final diskFree = _kernel32.lookupFunction<_DiskFreeC, _DiskFreeDart>(
      'GetDiskFreeSpaceExW',
    );
    final volumePath = _kernel32.lookupFunction<_VolumePathC, _VolumePathDart>(
      'GetVolumePathNameW',
    );
    final volumeInfo = _kernel32.lookupFunction<_VolumeInfoC, _VolumeInfoDart>(
      'GetVolumeInformationW',
    );
    return using((arena) {
      final target = path.toNativeUtf16(allocator: arena);
      final available = arena<Uint64>();
      final root = arena<Uint16>(_maxPath).cast<Utf16>();
      final type = arena<Uint16>(64).cast<Utf16>();
      if (diskFree(target, available, nullptr, nullptr) == 0 ||
          volumePath(target, root, _maxPath) == 0 ||
          volumeInfo(root, nullptr, 0, nullptr, nullptr, nullptr, type, 64) ==
              0) {
        return null;
      }
      return (available.value, fileSystemName(type.toDartString()));
    });
  }

  @override
  void keepAwake(bool on) {
    _kernel32.lookupFunction<Uint32 Function(Uint32), int Function(int)>(
      'SetThreadExecutionState',
    )(
      on
          ? _esContinuous | _esSystemRequired | _esDisplayRequired
          : _esContinuous,
    );
  }

  @override
  void allowForeground() {
    _user32.lookupFunction<Int32 Function(Uint32), int Function(int)>(
      'AllowSetForegroundWindow',
    )(_asfwAny);
  }
}
