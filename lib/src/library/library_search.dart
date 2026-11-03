// lib/src/library/library_search.dart
//
// A busca, que fica viva ao abrir um resultado e voltar. Só o último pedido vale.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'library_controller.dart';
import 'library_store.dart';
import 'models.dart';

enum SearchFilter { all, tracks, albums, artists, folders }

class LibrarySearch extends ChangeNotifier {
  /// O bastante para não consultar a cada letra de quem digita rápido.
  static const debounce = Duration(milliseconds: 80);

  final LibraryStore store;

  /// Quanto a busca precisa ficar parada para contar como uma busca feita.
  static const rememberAfter = Duration(milliseconds: 1500);
  static const recentLimit = 8;
  static const _recentKey = 'recentSearches';

  LibrarySearch(this.store) {
    unawaited(_loadRecent());
  }

  /// As últimas buscas com resultado, a mais nova primeiro.
  List<String> recent = const [];
  Timer? _remember;

  Future<void> _loadRecent() async {
    final saved = await store.setting(_recentKey);
    if (saved == null || _disposed) return;
    try {
      final list = jsonDecode(saved);
      if (list is List) {
        recent = list.whereType<String>().take(recentLimit).toList();
        notifyListeners();
      }
    } on FormatException catch (e) {
      debugPrint('🎵 buscas recentes ilegíveis: $e');
    }
  }

  void _setRecent(List<String> value) {
    recent = value;
    notifyListeners();
    unawaited(store.setSetting(_recentKey, jsonEncode(value)));
  }

  void _rememberQuery() {
    final text = query.trim();
    if (text.isEmpty || results.isEmpty) return;
    // Quem digitou devagar passou por pedaços da palavra
    final lower = text.toLowerCase();
    _setRecent(
      [
        text,
        for (final old in recent)
          if (!lower.startsWith(old.toLowerCase())) old,
      ].take(recentLimit).toList(),
    );
  }

  void removeRecent(String text) =>
      _setRecent([...recent.where((old) => old != text)]);

  void clearRecent() => _setRecent(const []);

  String query = '';
  SearchFilter filter = SearchFilter.all;
  SearchResults results = const SearchResults();
  Timer? _timer;
  int _latest = 0;
  bool _disposed = false;

  void setFilter(SearchFilter value) {
    filter = value;
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    _timer?.cancel();
    _remember?.cancel();
    if (value.trim().isEmpty) {
      _latest++;
      results = const SearchResults();
      notifyListeners();
      return;
    }
    _timer = Timer(debounce, () => unawaited(refresh()));
  }

  /// Consulta de novo, como depois de a biblioteca mudar.
  Future<void> refresh() async {
    if (query.trim().isEmpty) return;
    final ticket = ++_latest;
    final found = await store.search(query);
    if (_disposed || ticket != _latest) return;
    results = found;
    notifyListeners();
    _remember?.cancel();
    _remember = Timer(rememberAfter, _rememberQuery);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _remember?.cancel();
    super.dispose();
  }
}
