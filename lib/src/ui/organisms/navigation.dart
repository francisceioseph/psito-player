// lib/src/ui/organisms/navigation.dart
//
// Os destinos do player: a barra lateral, e a fileira de ícones quando ela não
// cabe.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

enum PlayerDestination { home, library, playlists, folders, search, settings }

extension on PlayerDestination {
  IconData get icon => switch (this) {
    PlayerDestination.home => Icons.home_rounded,
    PlayerDestination.library => Icons.library_music_rounded,
    PlayerDestination.playlists => Icons.playlist_play_rounded,
    PlayerDestination.folders => Icons.folder_rounded,
    PlayerDestination.search => Icons.search_rounded,
    PlayerDestination.settings => Icons.settings_rounded,
  };

  String label(BuildContext context) {
    final l = context.l10n;
    return switch (this) {
      PlayerDestination.home => l.home,
      PlayerDestination.library => l.library,
      PlayerDestination.playlists => l.playlists,
      PlayerDestination.folders => l.folders,
      PlayerDestination.search => l.search,
      PlayerDestination.settings => l.settings,
    };
  }
}

const _main = [
  PlayerDestination.home,
  PlayerDestination.library,
  PlayerDestination.playlists,
  PlayerDestination.folders,
  PlayerDestination.search,
];

class PlayerRail extends StatelessWidget {
  final PlayerDestination selected;
  final ValueChanged<PlayerDestination> onSelected;
  final VoidCallback onAddFolder;

  const PlayerRail({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onAddFolder,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget item(PlayerDestination destination) => _RailItem(
      icon: destination.icon,
      label: destination.label(context),
      selected: destination == selected,
      onTap: () => onSelected(destination),
    );
    return Material(
      color: scheme.surface,
      child: SizedBox(
        width: _railWidth,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: IconButton.filled(
                      tooltip: l.addFolder,
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_railRadius),
                        ),
                        minimumSize: const Size.square(_railSquare),
                      ),
                      icon: const Icon(Icons.create_new_folder_rounded),
                      onPressed: onAddFolder,
                    ),
                  ),
                  for (final destination in _main) item(destination),
                  const Spacer(),
                  item(PlayerDestination.settings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _railWidth = 80.0;
const _railSquare = 56.0;
const _railRadius = 16.0;

/// Um destino da barra lateral: um quadrado como o de adicionar pasta, com o nome
/// na dica.
class _RailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_railRadius),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          preferBelow: false,
          child: Material(
            color: selected ? scheme.secondaryContainer : Colors.transparent,
            shape: shape,
            child: InkWell(
              mouseCursor: WidgetStateMouseCursor.clickable,
              customBorder: shape,
              onTap: onTap,
              child: SizedBox.square(
                dimension: _railSquare,
                child: Icon(
                  icon,
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CompactNavigation extends StatelessWidget {
  final PlayerDestination selected;
  final ValueChanged<PlayerDestination> onSelected;
  final VoidCallback onAddFolder;

  const CompactNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onAddFolder,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        IconButton(
          tooltip: context.l10n.addFolder,
          icon: const Icon(Icons.create_new_folder_rounded),
          onPressed: onAddFolder,
        ),
        for (final destination in PlayerDestination.values)
          destination == selected
              ? IconButton.filledTonal(
                  tooltip: destination.label(context),
                  isSelected: true,
                  icon: Icon(destination.icon),
                  onPressed: () => onSelected(destination),
                )
              : IconButton(
                  tooltip: destination.label(context),
                  icon: Icon(destination.icon),
                  onPressed: () => onSelected(destination),
                ),
      ],
    ),
  );
}
