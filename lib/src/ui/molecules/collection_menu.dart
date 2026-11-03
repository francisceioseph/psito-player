// lib/src/ui/molecules/collection_menu.dart
//
// Os menus de álbuns, artistas e playlists: tudo o que dá para fazer com um grupo
// de faixas sem abrir a tela dele.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/library_controller.dart';
import '../../library/models.dart';
import '../format.dart';
import '../player_actions.dart';
import 'track_menu.dart';

List<PopupMenuEntry<VoidCallback>> collectionMenu(
  BuildContext context,
  PlayerActions actions,
  Future<List<Track>> Function() load,
) {
  final l = context.l10n;
  final playback = actions.playback;
  return [
    PopupMenuItem(
      value: () => unawaited(() async {
        await playback.playTracks(await load());
      }()),
      child: Text(l.play),
    ),
    PopupMenuItem(
      value: () => unawaited(() async {
        await playback.shuffleTracks(await load());
      }()),
      child: Text(l.shuffle),
    ),
    PopupMenuItem(
      value: () => unawaited(() async {
        await playback.tracksToQueue(await load());
      }()),
      child: Text(l.addToQueue),
    ),
    PopupMenuItem(
      value: () => unawaited(() async {
        final tracks = await load();
        if (!context.mounted) return;
        await showAddToPlaylist(context, actions.library, [
          for (final t in tracks) t.path,
        ]);
      }()),
      child: Text(l.addToPlaylist),
    ),
  ];
}

/// Fixar ou desafixar, com o que estiver valendo agora.
PopupMenuEntry<VoidCallback> pinItem(
  BuildContext context,
  PlayerActions actions,
  PinKind kind,
  int id,
) {
  final l = context.l10n;
  final pinned = actions.library.isPinned(kind, id);
  return PopupMenuItem(
    value: () => unawaited(actions.library.setPinned(kind, id, !pinned)),
    child: Text(pinned ? l.unpin : l.pin),
  );
}

Future<void> renamePlaylist(
  BuildContext context,
  LibraryController library,
  Playlist playlist,
) async {
  final l = context.l10n;
  final name = await askPlaylistName(
    context,
    title: l.renamePlaylist,
    action: l.save,
    initial: playlist.name,
  );
  if (name != null) await library.renamePlaylist(playlist, name);
}

/// Pergunta antes. Devolve se apagou.
Future<bool> deletePlaylist(
  BuildContext context,
  LibraryController library,
  Playlist playlist,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l = context.l10n;
      return AlertDialog(
        title: Text(l.deletePlaylist),
        content: Text(l.deletePlaylistBody(playlist.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.delete),
          ),
        ],
      );
    },
  );
  if (confirmed != true) return false;
  await library.deletePlaylist(playlist);
  return true;
}

List<PopupMenuEntry<VoidCallback>> playlistMenu(
  BuildContext context,
  PlayerActions actions,
  Playlist playlist,
) {
  final l = context.l10n;
  final library = actions.library;
  Future<List<Track>> load() => library.tracksOf(playlist);
  return [
    ...collectionMenu(context, actions, load),
    const PopupMenuDivider(),
    if (!playlist.automatic)
      pinItem(context, actions, PinKind.playlist, playlist.id),
    if (!playlist.automatic)
      PopupMenuItem(
        value: () => unawaited(renamePlaylist(context, library, playlist)),
        child: Text(l.renamePlaylist),
      ),
    PopupMenuItem(
      value: () => unawaited(() async {
        final name = playlistName(playlist, context);
        await actions.exportPlaylist(name, await load());
      }()),
      child: Text(l.exportPlaylist),
    ),
    if (!playlist.automatic)
      PopupMenuItem(
        value: () => unawaited(deletePlaylist(context, library, playlist)),
        child: Text(l.deletePlaylist),
      ),
  ];
}
