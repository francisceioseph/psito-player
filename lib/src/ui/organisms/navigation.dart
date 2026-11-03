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
  /// A partir daqui, o conteúdo tem largura para o rail aberto.
  static const expandMinWidth = 960.0;
  static const expandedWidth = 216.0;

  final PlayerDestination selected;
  final ValueChanged<PlayerDestination> onSelected;
  final VoidCallback onAddFolder;

  /// Aberto, com os nomes ao lado dos ícones.
  final bool expanded;

  /// Abre e fecha, ou null sem o botão.
  final VoidCallback? onToggle;

  const PlayerRail({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onAddFolder,
    this.expanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);
    Widget item(PlayerDestination destination) => _RailItem(
      icon: destination.icon,
      label: destination.label(context),
      selected: destination == selected,
      onTap: () => onSelected(destination),
    );
    return Material(
      color: scheme.surface,
      child: AnimatedContainer(
        duration: still ? Duration.zero : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: expanded ? expandedWidth : _railWidth,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (onToggle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: IconButton(
                          tooltip: expanded ? l.collapseRail : l.expandRail,
                          icon: Icon(
                            expanded
                                ? Icons.menu_open_rounded
                                : Icons.menu_rounded,
                          ),
                          onPressed: onToggle,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: _RailItem(
                        icon: Icons.create_new_folder_rounded,
                        label: l.addFolder,
                        filled: true,
                        onTap: onAddFolder,
                      ),
                    ),
                    for (final destination in _main) item(destination),
                    const Spacer(),
                    item(PlayerDestination.settings),
                  ],
                ),
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

/// Um destino da barra lateral: um quadrado como o de adicionar pasta e, com largura,
/// o nome ao lado.
class _RailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool filled;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_railRadius),
    );
    final background = filled
        ? scheme.primaryContainer
        : selected
        ? scheme.secondaryContainer
        : Colors.transparent;
    final foreground = filled
        ? scheme.onPrimaryContainer
        : selected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;
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
            color: background,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              mouseCursor: WidgetStateMouseCursor.clickable,
              customBorder: shape,
              onTap: onTap,
              child: SizedBox(
                height: _railSquare,
                // A animação passa por larguras em que o nome não cabe
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = Icon(icon, color: foreground);
                    if (constraints.maxWidth < _railSquare + 48) {
                      return SizedBox(
                        width: _railSquare,
                        child: Center(child: side),
                      );
                    }
                    return Row(
                      children: [
                        SizedBox(
                          width: _railSquare,
                          child: Center(child: side),
                        ),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: selected || filled
                                  ? foreground
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A navegação do modo compacto, embaixo, como num celular.
class PlayerBottomNav extends StatelessWidget {
  static const height = 72.0;
  static const destinations = [
    PlayerDestination.home,
    PlayerDestination.library,
    PlayerDestination.playlists,
    PlayerDestination.search,
    PlayerDestination.settings,
  ];

  final PlayerDestination selected;
  final ValueChanged<PlayerDestination> onSelected;

  const PlayerBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final destination in destinations)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: destination == selected,
                  label: destination.label(context),
                  excludeSemantics: true,
                  child: InkWell(
                    mouseCursor: WidgetStateMouseCursor.clickable,
                    onTap: () => onSelected(destination),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 32,
                          decoration: ShapeDecoration(
                            shape: const StadiumBorder(),
                            color: destination == selected
                                ? scheme.secondaryContainer
                                : Colors.transparent,
                          ),
                          child: Icon(
                            destination.icon,
                            color: destination == selected
                                ? scheme.onSecondaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            destination.label(context),
                            maxLines: 1,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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
