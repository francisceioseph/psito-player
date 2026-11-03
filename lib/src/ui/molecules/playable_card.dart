// lib/src/ui/molecules/playable_card.dart
//
// O desenho comum dos cartões de álbum, playlist e artista: abrir com o clique, o
// menu no botão direito e o tocar, que aparece com o ponteiro ou o foco.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import 'context_menu.dart';

class PlayableCard extends StatefulWidget {
  /// O que os textos ocupam abaixo da arte, para a grade reservar.
  static const textHeight = 47.0;

  /// O nome para o leitor de tela.
  final String label;
  final VoidCallback onOpen;

  /// Toca, ou null sem o botão.
  final VoidCallback? onPlay;
  final String? playTooltip;
  final PopupMenuItemBuilder<VoidCallback>? menu;

  /// Mostra o selo de fixado na arte.
  final bool pinned;

  /// Do alto da arte até o fim do cartão, com os textos.
  final Widget child;

  const PlayableCard({
    super.key,
    required this.label,
    required this.onOpen,
    required this.child,
    this.onPlay,
    this.playTooltip,
    this.menu,
    this.pinned = false,
  });

  @override
  State<PlayableCard> createState() => _PlayableCardState();
}

class _PlayableCardState extends State<PlayableCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ContextMenu(
      items: widget.menu,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        // O foco no botão de tocar conta: sem isto, ele some ao receber o foco
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (v) => setState(() => _focused = v),
          child: Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: widget.pinned
                      ? '${widget.label}, ${context.l10n.pinned}'
                      : widget.label,
                  excludeSemantics: true,
                  child: InkWell(
                    mouseCursor: WidgetStateMouseCursor.clickable,
                    borderRadius: BorderRadius.circular(12),
                    onTap: widget.onOpen,
                    child: widget.child,
                  ),
                ),
              ),
              if (widget.pinned)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Tooltip(
                    message: context.l10n.pinned,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              if (widget.onPlay != null && (_hovered || _focused))
                Positioned(
                  right: 8,
                  bottom: PlayableCard.textHeight + 8,
                  child: IconButton.filled(
                    tooltip: widget.playTooltip,
                    icon: const Icon(Icons.play_arrow_rounded),
                    onPressed: widget.onPlay,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
