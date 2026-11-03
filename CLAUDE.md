# Psito Player

Player de músicas locais para Linux, em Flutter. Não depende do Psito OS: é o projeto `examples/player_psito/` do repositório `psito-os` que o liga ao sistema, importando este como pacote.

- O áudio é a `libmpv2` por trás da `PlayerEngine`, e a biblioteca é um SQLite (o `LibraryDb`, num isolate pelo `LibraryStore`), com o scanner em outro isolate. A busca é um FTS5 no mesmo banco.
- As letras (`lib/src/lyrics/`) vêm do `.lrc`, do `.srt` ou das tags, e o `LyricsController` agenda a troca de linha entre os avisos de posição do motor.
- Os controles de mídia são MPRIS (`lib/src/player/mpris.dart`). Sozinho, o player é um só por sessão (`single_instance.dart`, pelo nome `org.psito.player`).
- Os Ajustes (`lib/src/settings/player_settings.dart`) ficam no banco, e valem só dentro do player. Os atalhos são editáveis (`player_shortcuts.dart`).
- O cruzamento (`crossfade.dart`, `media_kit_engine.dart`): o tocador principal tem a fila e vai para a faixa nova, e um segundo mpv, o `_tail`, termina a antiga. Dá para medir o som num null sink com tons de frequências diferentes. Faixas seguidas do mesmo álbum não cruzam (`shouldCrossfade`).
- O seletor de músicas (`add_tracks_dialog.dart`, `showAddTracks` e `showNewPlaylist`) marca por música, pela busca ou por pasta (`pick_folders.dart`), e a playlist nova nasce nele.
- As playlists inteligentes (`SmartRules` em `models.dart`, a coluna `rules` e o `_smartWhere` no banco, `smart_playlist_dialog.dart`) têm o `kind` `manual`, com o nome e o resto das outras: quem muda é o `smart`, que tira o que escolhe e reordena à mão.
- A capa de uma playlist (`mosaic_cover.dart`) leva só capas de verdade, de uma a quatro, e sem nenhuma é a decoração. A capa escolhida fica em `playlist-covers/`, junto do banco e fora do cache, e o `pickImage` do `PlayerView` é opcional: sem ele, não há a opção.
- Os diálogos abertos pelo estado do `PlayerView` usam `_themedKey`, porque o contexto dele fica acima do tema do player.
- O `PlayerActions` (`lib/src/ui/player_actions.dart`) leva a biblioteca e o playback aos cartões e menus. O botão direito é o `ContextMenu`, e os cartões com tocar são o `PlayableCard`.
- A tela da música é o `TrackPage`, na pilha do `PlayerView`, com as abas do painel (`PanelTabs`). Abrir o painel fecha ela. Os mixes (`LibraryDb.mixes`) não ficam guardados: a ordem é calculada a partir do dia.
- Os modos (`PlayerMode`, nos Ajustes) mudam a janela pelo `resizeWindow`, que no player sozinho é o método `resize` do canal `psito_player/window`, no runner. No Psito ele não existe, e os modos ficam de fora. Uma janela estreita e alta usa o layout de celular de qualquer forma (`ShellTemplate.isMobile`).
- `lib/player_app.dart` tem o `PlayerView`, que recebe de fora o motor, a biblioteca e os seletores. `lib/standalone_app.dart` é o player sozinho.

- As tags e a duração vêm do `audio_metadata_reader`, e o `format_probes.dart` cobre o que ele não lê: o WMA inteiro e a duração do AAC, do WavPack e do APE.
- O mix dinâmico fica no `PlaybackController` (`setDynamicMix`, `_topUpMix`), com a escolha no `LibraryDb.dynamicMixBatch`.
- A versão é do semantic-release (`.releaserc.json`, `tool/set-version.sh`): `feat` sobe o minor, `fix` o patch e BREAKING CHANGE o major. O CI devolve à `master` o commit da versão, então rode `git pull --rebase` antes de cada push.

## Regras
- Só música local, sem serviços de terceiros.
- Widgets em atomic design (`lib/src/ui/`): o que aparece em mais de um lugar sobe para lá.
- Nenhum texto que quem usa lê fica no código: vai para os `.arb`, em todos os idiomas (en, pt, es, fr, de, ru, zh; o `l10n_test` confere as chaves, os marcadores e se cabe). No russo, o plural usa `one`, `few`, `many` e `other`, sem `=1`, porque 21 também é `one`. Em português, um plural com `=1` tem também o `=0`.
- Controles: os campos vêm do `inputDecorationTheme`, e toda busca é o `SearchField`. Botão principal é `FilledButton`, secundário é o tonal e terciário é o `TextButton`; o que liga e desliga é o `ToggleIconButton` (`design_test`).
- Todo clique tem nome para o leitor de tela (`Semantics(label:)` ou `Tooltip`).
- As cores vêm do `Theme.of(context).colorScheme`, sem `Colors.x` nem `Color(0x...)` nos widgets.
- A janela precisa funcionar até 240×160.
- Rode `flutter analyze` e `flutter test -j 2` depois de editar Dart. Mudar uma tela de propósito pede `flutter test --update-goldens test/golden_test.dart`, e olhar as imagens em `test/goldens/`.
- Tudo com clique tem o caminho pelo teclado: o `accessibility_test` confere o Tab, o foco, o contraste e os rótulos, nos dois temas.
- Repositórios: uma versão nova faz o `apt.yml` gerar o `.deb` e o `.rpm`, anexar à release e publicar no GitHub Pages os repositórios APT e DNF com as três últimas (`tool/build-apt-repo.sh`, `tool/build-dnf-repo.sh`). O pacote do AUR (`psito-player-bin`) sai do `.deb` da release pelo `tool/build-aur.sh`, e quem envia é quem mantém, com a própria conta. A página (`site/`) tem os textos em `site/i18n.js`. A chave fica no segredo `APT_SIGNING_KEY` (`tool/create-apt-key.sh`, uma vez só).
- Logs: instalado, o `debugPrint` só escreve com o ajuste "Registrar logs" ligado (`lib/src/logging.dart`). Em desenvolvimento, escreve sempre.
