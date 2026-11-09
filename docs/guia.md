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

No menu da música que está tocando, **Parar depois desta faixa** para no fim dela, e um
ícone na barra mostra que está marcado. **Mostrar no gerenciador de arquivos** vale para
qualquer música.

O botão de busca nas páginas de álbum, artista e playlist procura só naquela lista.

**Pular nas listas**, no menu de uma música, deixa ela de fora quando uma lista toca, no
aleatório e nos mixes. Ela continua aparecendo, com um sinal, e toca se você clicar nela.
Em **Músicas**, o filtro **Puladas** mostra as marcadas, e o **Duplicadas** junta as que
têm o mesmo título e artista com a duração quase igual.

Ligue as notas por estrelas nos Ajustes, em Biblioteca, para dar de 1 a 5 estrelas a uma música, na tela dela ou no menu. Clicar na estrela atual tira a nota. As de 4 e 5 estrelas formam a playlist Mais bem avaliadas, e as de 1 estrela ficam fora dos mixes.

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

O botão de infinito, na Início e na fila, liga o mix dinâmico: ele vai somando músicas da sua biblioteca, puxando para as que você dá nota e marca como favoritas, até você desligar ou escolher outra coisa para ouvir.

## Playlists

- **Nova playlist**, na tela Playlists, cria uma: digite o nome e, se quiser, já escolha
  as músicas, uma a uma, todas as da busca ou pastas inteiras. Marcar uma pasta também
  sugere o nome dela.
- **Adicionar músicas**, dentro de uma playlist, escolhe do mesmo jeito.
- **Playlist inteligente**, na tela Playlists, se monta sozinha por regras de gênero, ano
  e nota: todas elas ou qualquer uma, com a ordem e o máximo de músicas. Ela se atualiza
  quando a biblioteca muda. **Editar regras** fica dentro dela.
- **A capa** vem dos álbuns da playlist: uma, ou uma grade com até quatro. O ícone de
  imagem no canto dela, ou **Escolher capa** no menu, usa uma imagem sua, e **Remover
  capa** volta para as dos álbuns.
- **Adicionar à playlist**, no menu de qualquer música, álbum, artista ou playlist, ou
  no botão da página do álbum, funciona de qualquer lugar.
- Arraste a alça para reordenar, ou use **Mover para cima** e **Mover para baixo** no
  menu.
- **Embaralhar a ordem** e **Remover duplicadas**, no menu da playlist, mudam a lista, e
  o aviso que aparece traz **Desfazer**.
- Arquivos M3U, M3U8, XSPF e PLS podem ser importados e exportados.

A fila também reordena com o botão direito numa música, e pode virar playlist.

## Letras

Um `.lrc` ou `.srt` com o nome da música, ao lado dela, ou a letra nas tags do arquivo,
aparecem no painel Letra. Clique numa linha para ir até ela. Se o tempo estiver errado,
o botão do relógio ajusta para aquela música. Um `.lrc` com o tempo de cada palavra (`<00:12.40>`)
acende as palavras conforme são cantadas.

Um álbum num arquivo só, com um `.cue` de mesmo nome ao lado, aparece com as faixas separadas.
O FLAC também pode trazer o texto da cue sheet na tag `CUESHEET`. Essas faixas não têm o editor de tags,
e ao organizar o par vai junto, com o nome de sempre.

## Editar as tags

No menu de uma música, **Editar tags…** (ou Ctrl+E na linha em foco) abre título, artista,
álbum, número, gênero, compositor, comentário, letra embutida e capa. As setas seguem pela
lista, e com algo alterado ele pergunta antes de sair da música.

No menu de um álbum, **Editar álbum…** muda o que vale para todas as faixas e arruma número,
título e artista numa tabela. Arraste as linhas e use **Numerar na ordem**.

Para várias músicas, marque com Ctrl+clique ou Shift+clique, ou **Selecionar** no menu, e use
**Editar tags** na barra que aparece. Só o que você mexer é gravado.

O player grava só os campos editados: ReplayGain, notas de outros programas e o que mais
houver no arquivo ficam como estão. O aviso no fim tem **Desfazer**. Não dá para editar WMA,
nem arquivos em disco só para leitura. Favoritos e estrelas continuam só na biblioteca.

## Organizar os arquivos

No menu de um álbum, de uma pasta em **Pastas** ou na barra de seleção, **Organizar arquivos…**
põe as músicas nos lugares que as tags dizem. Monte o padrão com os botões, como
`{albumArtist}/{year} - {album}/{disc}{track} {title}`, e veja a lista do que muda antes de
confirmar. O que daria o mesmo nome, ou passaria por cima de outro arquivo, fica marcado e não é
movido. A música que está tocando também fica.

A letra de mesmo nome vai junto, e a capa da pasta quando a pasta inteira muda. Contagens, notas,
favoritos e playlists continuam valendo, e o aviso no fim tem **Desfazer**.

**Copiar para uma pasta…** usa o mesmo padrão para levar um álbum, uma playlist ou uma seleção a
um pendrive: os originais ficam, a prévia mostra o espaço livre e o que não cabe, e os nomes
respeitam o que o disco aceita. O que já foi copiado não é copiado de novo.

## Som

Em **Ajustes, Reprodução**:

- **Tocar sem pausa** emenda as músicas feitas para tocar juntas.
- **Cruzar as faixas** sobrepõe o fim de uma música e o começo da outra, de 3 a 12
  segundos. Músicas seguidas do mesmo álbum continuam emendadas.
- **Suavizar ao pausar** baixa e devolve o som aos poucos.
- **ReplayGain** iguala o volume com os valores das tags. **Faixa** nivela cada música,
  e **Álbum** mantém as diferenças dentro de um álbum. O player não calcula esses
  valores: marque os arquivos antes com uma ferramenta como o `rsgain`.
- **Manter o computador acordado enquanto toca** deixa a tela ligada e impede a suspensão
  automática. **Avisar quando a faixa mudar** mostra uma notificação. As duas começam
  desligadas.

Em **Ajustes, Equalizador**, ligue a chave e escolha uma predefinição ou mexa nas dez
bandas: a mudança vale com a música tocando, logo depois de soltar a banda. O volume geral
baixa um pouco quando uma banda sobe, para o som não distorcer.

## Teclado

| Tecla | Ação |
|---|---|
| Espaço | Tocar ou pausar |
| Esquerda, Direita | Voltar ou avançar 5 segundos |
| Ctrl+Esquerda, Ctrl+Direita | Música anterior ou próxima |
| M | Silenciar |
| Ctrl+K | Buscar |
| Ctrl+E | Editar as tags da linha em foco |
| L | Letra |
| Q | Fila |
| Tab, Shift+Tab | Passar pelos controles |
| Enter | Acionar o controle em foco |
| Menu, Shift+F10 | Abrir o menu do que está em foco |

Esses são os padrões. **Ajustes, Atalhos de teclado** muda. As teclas de mídia passam
pela área de trabalho, por MPRIS.

## Onde ficam os seus dados

A biblioteca fica em `~/.local/share/psito/player`, e as miniaturas das capas em
`~/.cache/psito/player`. O player só altera os arquivos de música quando você edita as tags ou organiza os arquivos. O que desfaz fica em `tag-undo` e `organize-undo`, na mesma pasta da biblioteca, por 7 dias.

No Windows, a biblioteca fica em `%APPDATA%\Psito Player` e as miniaturas em `%LOCALAPPDATA%\Psito Player`. Desinstalar o player não apaga essas pastas.

Fechar a janela encerra o player e para a música.
