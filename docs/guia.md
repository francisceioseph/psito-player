# Guia do Psito Player

O player toca os arquivos de música do seu computador. Nada é enviado a lugar nenhum.

## Primeiros passos

Aperte o botão quadrado no alto da barra lateral e escolha uma pasta. O player lê em
segundo plano, e o que já encontrou pode tocar. Em **Pastas** dá para adicionar mais,
conferir mudanças e remover. Os arquivos continuam onde estão.

## Achar música

- **Início** mostra o que está tocando ou onde você parou, o que entrou por último, as
  mais tocadas, suas playlists e artistas, e álbuns para redescobrir.
- **Biblioteca** filtra por álbuns, artistas, músicas, pastas, playlists e gêneros.
- **Buscar** (Ctrl+K) procura em tudo enquanto você digita.

## Tocar

Clique numa música para tocar ela e o resto da lista. Passe o ponteiro num cartão para
ver o botão de tocar. O botão direito em álbuns, artistas, músicas e playlists traz o
resto, ou a tecla Menu e o Shift+F10 no item em foco.

A barra de baixo tem os controles. Os botões de letra e fila abrem o painel ao lado.
Clicar na capa abre a tela da música, com a letra grande, os dados do arquivo e a fila.

O botão de busca nas páginas de álbum, artista e playlist procura só naquela lista.

## Tamanhos

O botão com uma moldura, na barra, muda o tamanho do player. **Compacto** fica como um
app de celular, com a navegação embaixo. **Miniplayer** é uma janelinha só com a capa e
os controles, que fica por cima das outras. O botão no alto da barra lateral mostra ou
esconde os nomes.

## Fixados e mixes

**Fixar**, no menu de um álbum, artista ou playlist, leva ao alto do Início e da
Biblioteca. **Seus mixes**, no Início, saem da sua biblioteca: o mix do dia mistura o que
você ouve com o que ainda não ouviu, e cada gênero com músicas o bastante ganha o dele.
Eles mudam uma vez por dia.

## Playlists

- **Nova playlist**, na tela Playlists, cria uma.
- **Adicionar músicas**, dentro de uma playlist, busca na biblioteca e adiciona várias
  de uma vez.
- **Adicionar à playlist**, no menu de qualquer música, álbum, artista ou playlist, ou
  no botão da página do álbum, funciona de qualquer lugar.
- Arraste a alça para reordenar, ou use **Mover para cima** e **Mover para baixo** no
  menu.
- Arquivos M3U e M3U8 podem ser importados e exportados.

A fila também reordena com o botão direito numa música, e pode virar playlist.

## Letras

Um `.lrc` ou `.srt` com o nome da música, ao lado dela, ou a letra nas tags do arquivo,
aparecem no painel Letra. Clique numa linha para ir até ela. Se o tempo estiver errado,
o botão do relógio ajusta para aquela música.

## Som

Em **Ajustes, Reprodução**:

- **Tocar sem pausa** emenda as músicas feitas para tocar juntas.
- **ReplayGain** iguala o volume com os valores das tags. **Faixa** nivela cada música,
  e **Álbum** mantém as diferenças dentro de um álbum. O player não calcula esses
  valores: marque os arquivos antes com uma ferramenta como o `rsgain`.

## Teclado

| Tecla | Ação |
|---|---|
| Espaço | Tocar ou pausar |
| Esquerda, Direita | Voltar ou avançar 5 segundos |
| Ctrl+Esquerda, Ctrl+Direita | Música anterior ou próxima |
| M | Silenciar |
| Ctrl+K | Buscar |
| L | Letra |
| Q | Fila |
| Tab, Shift+Tab | Passar pelos controles |
| Enter | Acionar o controle em foco |
| Menu, Shift+F10 | Abrir o menu do que está em foco |

Esses são os padrões. **Ajustes, Atalhos de teclado** muda. As teclas de mídia passam
pela área de trabalho, por MPRIS.

## Onde ficam os seus dados

A biblioteca fica em `~/.local/share/psito/player`, e as miniaturas das capas em
`~/.cache/psito/player`. Os arquivos de música nunca são alterados.

Fechar a janela encerra o player e para a música.
