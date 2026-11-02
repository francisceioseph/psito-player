# Psito Player

Player de músicas locais para Linux, em Flutter. Não depende do Psito OS: é o projeto `examples/player_psito/` do repositório `psito-os` que o liga ao sistema, importando este como pacote.

- O áudio é a `libmpv2` por trás da `PlayerEngine`, e a biblioteca é um SQLite (o `LibraryDb`, num isolate pelo `LibraryStore`), com o scanner em outro isolate. A busca é um FTS5 no mesmo banco.
- As letras (`lib/src/lyrics/`) vêm do `.lrc`, do `.srt` ou das tags, e o `LyricsController` agenda a troca de linha entre os avisos de posição do motor.
- Os controles de mídia são MPRIS (`lib/src/player/mpris.dart`). Sozinho, o player é um só por sessão (`single_instance.dart`, pelo nome `org.psito.player`).
- Os Ajustes (`lib/src/settings/player_settings.dart`) ficam no banco, e valem só dentro do player. Os atalhos são editáveis (`player_shortcuts.dart`).
- `lib/player_app.dart` tem o `PlayerView`, que recebe de fora o motor, a biblioteca e os seletores. `lib/standalone_app.dart` é o player sozinho.

## Regras
- Só música local, sem serviços de terceiros.
- Widgets em atomic design (`lib/src/ui/`): o que aparece em mais de um lugar sobe para lá.
- Nenhum texto que quem usa lê fica no código: vai para os `.arb`, nos dois idiomas. Em português, um plural com `=1` tem também o `=0`.
- Todo clique tem nome para o leitor de tela (`Semantics(label:)` ou `Tooltip`).
- As cores vêm do `Theme.of(context).colorScheme`, sem `Colors.x` nem `Color(0x...)` nos widgets.
- A janela precisa funcionar até 240×160.
- Rode `flutter analyze` e `flutter test -j 2` depois de editar Dart.
