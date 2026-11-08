// lib/src/ui/templates/editor_template.dart
//
// A moldura dos editores: um diálogo e, em janela estreita, a tela inteira.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class EditorTemplate extends StatelessWidget {
  /// Abaixo desta largura, a tela inteira.
  static const fullScreenMaxWidth = 600.0;

  /// Abaixo desta altura, tudo rola junto: não sobra lugar para partes fixas.
  static const scrollAllMaxHeight = 420.0;
  static const _scrolledBodyHeight = 360.0;

  final String title;
  final String? subtitle;

  /// Ao lado do título, como as setas de faixa.
  final Widget? headerAction;

  /// As abas, entre o título e o conteúdo.
  final Widget? tabs;
  final Widget body;

  /// Embaixo do conteúdo, fixo: os dados do arquivo.
  final Widget? footer;

  /// À esquerda dos botões, como quantos campos mudaram.
  final String? status;
  final double width;

  /// O conteúdo ocupa a altura toda, e rola por dentro.
  final bool fill;
  final String closeLabel;
  final VoidCallback onClose;

  /// O nome e a ação do botão principal. Sem nome, é só para ler.
  final String? saveLabel;
  final VoidCallback? onSave;

  const EditorTemplate({
    super.key,
    required this.title,
    this.subtitle,
    this.headerAction,
    this.tabs,
    required this.body,
    this.footer,
    this.status,
    this.width = 760,
    this.fill = false,
    required this.closeLabel,
    required this.onClose,
    this.saveLabel,
    this.onSave,
  });

  Widget _heading(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _status(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      status ?? '',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _layout({
    required BuildContext context,
    required List<Widget> top,
    required List<Widget> bottom,
    required bool grow,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = SizedBox(height: 12);
      if (constraints.maxHeight < scrollAllMaxHeight) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final part in top) ...[part, gap],
              fill ? SizedBox(height: _scrolledBodyHeight, child: body) : body,
              for (final part in bottom) ...[gap, part],
            ],
          ),
        );
      }
      return Column(
        mainAxisSize: grow ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final part in top) ...[part, gap],
          Flexible(
            fit: grow ? FlexFit.tight : FlexFit.loose,
            child: fill ? body : SingleChildScrollView(child: body),
          ),
          for (final part in bottom) ...[gap, part],
        ],
      );
    },
  );

  Widget _wide(BuildContext context) {
    final l = context.l10n;
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _heading(context)),
        ?headerAction,
      ],
    );
    final actions = Row(
      children: [
        Expanded(child: _status(context)),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onClose,
          child: Text(saveLabel == null ? l.close : closeLabel),
        ),
        if (saveLabel != null) ...[
          const SizedBox(width: 8),
          FilledButton(onPressed: onSave, child: Text(saveLabel!)),
        ],
      ],
    );
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _layout(
            context: context,
            grow: fill,
            top: [header, ?tabs],
            bottom: [?footer, actions],
          ),
        ),
      ),
    );
  }

  Widget _full(BuildContext context) {
    final l = context.l10n;
    final header = Row(
      children: [
        IconButton(
          tooltip: saveLabel == null ? l.close : closeLabel,
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
        const SizedBox(width: 4),
        Expanded(child: _heading(context)),
        if (saveLabel != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: FilledButton(
              onPressed: onSave,
              child: Text(
                saveLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
    return Dialog.fullscreen(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _layout(
            context: context,
            grow: true,
            top: [header, ?headerAction, ?tabs],
            bottom: [?footer, if (status != null) _status(context)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      MediaQuery.sizeOf(context).width < fullScreenMaxWidth
      ? _full(context)
      : _wide(context);
}
