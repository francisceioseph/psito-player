// lib/src/ui/molecules/context_menu.dart
//
// O menu do botão direito. Quem não usa o mouse abre com a tecla Menu ou Shift+F10,
// e o leitor de tela, com uma ação.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';

class ContextMenu extends StatelessWidget {
  /// O que o menu oferece, ou null sem menu.
  final PopupMenuItemBuilder<VoidCallback>? items;
  final Widget child;

  const ContextMenu({super.key, required this.items, required this.child});

  Future<void> _open(BuildContext context, Offset? at) async {
    final items = this.items!;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final box = context.findRenderObject()! as RenderBox;
    final point = box.localToGlobal(
      at ?? box.size.center(Offset.zero),
      ancestor: overlay,
    );
    final action = await showMenu<VoidCallback>(
      context: context,
      position: RelativeRect.fromRect(
        point & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: items(context),
    );
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (items == null) return child;
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: context.l10n.moreOptions): () =>
            unawaited(_open(context, null)),
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final menuKey =
              event.logicalKey == LogicalKeyboardKey.contextMenu ||
              (event.logicalKey == LogicalKeyboardKey.f10 &&
                  HardwareKeyboard.instance.isShiftPressed);
          if (!menuKey) return KeyEventResult.ignored;
          unawaited(_open(context, null));
          return KeyEventResult.handled;
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.deferToChild,
          onSecondaryTapUp: (details) =>
              unawaited(_open(context, details.localPosition)),
          child: child,
        ),
      ),
    );
  }
}
