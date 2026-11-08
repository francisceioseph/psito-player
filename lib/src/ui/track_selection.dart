// lib/src/ui/track_selection.dart
//
// As faixas marcadas numa lista, para agir sobre várias de uma vez.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../library/models.dart';

class TrackSelection extends ChangeNotifier {
  final _tracks = <String, Track>{};
  String? _anchor;

  bool get active => _tracks.isNotEmpty;
  int get count => _tracks.length;
  List<Track> get tracks => List.unmodifiable(_tracks.values);
  bool contains(Track track) => _tracks.containsKey(track.path);

  /// Marca ou desmarca, e é daqui que o Shift conta.
  void toggle(Track track) {
    if (_tracks.remove(track.path) == null) _tracks[track.path] = track;
    _anchor = track.path;
    notifyListeners();
  }

  /// Marca de onde parou até [index], em [list].
  void extendTo(List<Track> list, int index) {
    final found = list.indexWhere((t) => t.path == _anchor);
    final from = found < 0 ? index : found;
    final (low, high) = from < index ? (from, index) : (index, from);
    for (final track in list.sublist(low, high + 1)) {
      _tracks[track.path] = track;
    }
    notifyListeners();
  }

  void clear() {
    if (_tracks.isEmpty) return;
    _tracks.clear();
    _anchor = null;
    notifyListeners();
  }

  /// Decide o que um clique numa linha faz. Com a seleção valendo, marca; com
  /// Ctrl ou Shift, começa a marcar; senão, [play].
  void tap(List<Track> list, int index, VoidCallback play) {
    final keys = HardwareKeyboard.instance;
    if (keys.isShiftPressed && active) {
      extendTo(list, index);
    } else if (keys.isControlPressed || active) {
      toggle(list[index]);
    } else {
      play();
    }
  }
}
