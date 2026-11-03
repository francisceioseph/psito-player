// lib/src/library/pick_folders.dart
//
// As pastas da biblioteca como o seletor de músicas mostra: cada uma com as faixas
// dela e das de dentro, inclusive as que só têm subpastas.
import 'package:path/path.dart' as p;

import 'models.dart';

class PickFolder {
  final String path;

  /// Quantas pastas acima, até a da biblioteca.
  final int depth;

  /// De onde ela vem, a partir da pasta da biblioteca. Vazio na própria.
  final String location;

  /// As faixas, na ordem de cada álbum.
  final List<String> paths;

  const PickFolder({
    required this.path,
    required this.depth,
    required this.location,
    required this.paths,
  });

  String get name => p.basename(path);
}

int _inFolderOrder(Track a, Track b) {
  final dir = p.dirname(a.path).compareTo(p.dirname(b.path));
  if (dir != 0) return dir;
  final disc = (a.discNumber ?? 0).compareTo(b.discNumber ?? 0);
  if (disc != 0) return disc;
  final track = (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
  return track != 0 ? track : a.path.compareTo(b.path);
}

/// A pasta vem logo antes das de dentro dela, em ordem de nome.
String _sortKey(String path) => foldedText(path).replaceAll('/', '\u0000');

List<PickFolder> pickFolders(Iterable<Track> tracks, Iterable<String> roots) {
  final found = <String, ({String root, List<String> paths})>{};
  for (final track in List.of(tracks)..sort(_inFolderOrder)) {
    final dir = p.dirname(track.path);
    final root = roots.firstWhere(
      (root) => root == dir || p.isWithin(root, dir),
      orElse: () => dir,
    );
    for (var at = dir; ; at = p.dirname(at)) {
      found
          .putIfAbsent(at, () => (root: root, paths: []))
          .paths
          .add(track.path);
      if (at == root) break;
    }
  }
  final keys = found.keys.toList()
    ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));
  return [
    for (final path in keys)
      PickFolder(
        path: path,
        depth:
            p.split(p.relative(path, from: found[path]!.root)).length -
            (path == found[path]!.root ? 1 : 0),
        location: path == found[path]!.root
            ? ''
            : p.relative(p.dirname(path), from: p.dirname(found[path]!.root)),
        paths: found[path]!.paths,
      ),
  ];
}
