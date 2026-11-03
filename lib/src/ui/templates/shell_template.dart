// lib/src/ui/templates/shell_template.dart
//
// A janela: a navegação, o conteúdo, o painel ao lado e a barra do player, que dá
// lugar ao painel. Decide o que cabe, até o mínimo de 240x160, em que só a
// barra fica.
import 'package:flutter/material.dart';

class ShellTemplate extends StatelessWidget {
  /// A partir daqui, a barra lateral. Abaixo, a navegação compacta.
  static const railMinWidth = 560.0;
  static const railMinHeight = 560.0;

  /// Abaixo desta altura, a barra do player ocupa tudo.
  static const contentMinHeight = 260.0;

  /// Janelas estreitas e altas ficam como num celular, mesmo sem pedir.
  static const mobileMinWidth = 300.0;
  static const mobileMinHeight = 520.0;

  /// O layout de celular cabe e faz sentido nesse tamanho.
  static bool isMobile(Size size, {bool forced = false}) =>
      size.height >= mobileMinHeight &&
      size.width >= mobileMinWidth &&
      (forced || size.width < railMinWidth);

  /// A partir daqui, o painel fica ao lado do conteúdo. Abaixo, no lugar dele.
  static const panelSideMinWidth = 900.0;
  static const panelWidth = 340.0;

  final Widget rail;
  final Widget compactNav;
  final Widget content;

  /// O painel ao lado, ou null fechado.
  final Widget? panel;
  final Widget bar;

  /// A navegação embaixo, no lugar da lateral, no layout de celular.
  final Widget? bottomNav;

  const ShellTemplate({
    super.key,
    required this.rail,
    required this.compactNav,
    required this.content,
    required this.bar,
    this.bottomNav,
    this.panel,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final showContent = c.maxHeight >= contentMinHeight;
      final nav = bottomNav;
      final showRail =
          nav == null &&
          c.maxWidth >= railMinWidth &&
          c.maxHeight >= railMinHeight;
      final panel = this.panel;
      final panelBeside = panel != null && c.maxWidth >= panelSideMinWidth;
      return Row(
        children: [
          if (showRail) rail,
          Expanded(
            child: Column(
              children: [
                if (showContent) ...[
                  if (!showRail && nav == null) compactNav,
                  Expanded(
                    child: panel == null || panelBeside ? content : panel,
                  ),
                ] else
                  const Spacer(),
                if (panel == null || !showContent) bar,
                ?nav,
              ],
            ),
          ),
          if (showContent && panelBeside)
            SizedBox(width: panelWidth, child: panel),
        ],
      );
    },
  );
}
