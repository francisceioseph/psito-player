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
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: IconButton.filled(
                      tooltip: l.addFolder,
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(56, 56),
                      ),
                      icon: const Icon(Icons.create_new_folder_rounded),
                      onPressed: onAddFolder,
                    ),
                  ),
                  for (final destination in _main)
                    _RailItem(
                      icon: destination.icon,
                      label: destination.label(context),
                      selected: destination == selected,
                      onTap: () => onSelected(destination),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: IconButton(
                      tooltip: l.settings,
                      isSelected: selected == PlayerDestination.settings,
                      icon: Icon(PlayerDestination.settings.icon),
                      onPressed: () => onSelected(PlayerDestination.settings),
                    ),
                  ),
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
const _indicatorSize = Size(56, 32);

/// Um destino da barra lateral, com a aparência do `NavigationRail` do Material 3.
/// O dele não deixa escolher o cursor do mouse.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      selected: selected,
      child: _RailInk(
        onTap: onTap,
        splashColor: scheme.primary.withValues(alpha: .12),
        hoverColor: scheme.primary.withValues(alpha: .04),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            children: [
              AnimatedContainer(
                duration: kThemeAnimationDuration,
                width: _indicatorSize.width,
                height: _indicatorSize.height,
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: selected
                      ? scheme.secondaryContainer
                      : scheme.secondaryContainer.withValues(alpha: 0),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              // Numa fonte larga, encolhe em vez de quebrar a palavra
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O destino inteiro é o clique, e o realce fica só no indicador.
class _RailInk extends InkResponse {
  const _RailInk({
    super.child,
    super.onTap,
    super.splashColor,
    super.hoverColor,
  }) : super(
         containedInkWell: true,
         highlightShape: BoxShape.rectangle,
         customBorder: const StadiumBorder(),
         mouseCursor: WidgetStateMouseCursor.clickable,
       );

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) =>
      () => Rect.fromLTWH(
        (referenceBox.size.width - _indicatorSize.width) / 2,
        0,
        _indicatorSize.width,
        _indicatorSize.height,
      );
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
