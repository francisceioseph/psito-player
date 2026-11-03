// O desenho dos controles vem do tema e de um lugar só: uma tela não monta o seu.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sources = [
    for (final file in Directory('lib/src/ui').listSync(recursive: true))
      if (file is File && file.path.endsWith('.dart')) file,
  ];

  void refuses(String code, {Set<String> except = const {}}) {
    final found = [
      for (final file in sources)
        if (!except.any(file.path.endsWith) &&
            file.readAsStringSync().contains(code))
          file.path,
    ];
    expect(found, isEmpty, reason: code);
  }

  test('o campo de busca é um só', () {
    refuses('SearchBar(');
    refuses('OutlineInputBorder');
  });

  test('o botão secundário é o tonal, e o terciário o de texto', () {
    refuses('OutlinedButton');
    refuses('ElevatedButton');
  });

  test('ligar e desligar é o ToggleIconButton', () {
    refuses('IconButton.filledTonal(', except: {'toggle_icon_button.dart'});
  });
}
