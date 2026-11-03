// lib/src/ui/templates/collection_template.dart
//
// A tela de uma coleção de faixas (álbum, artista, gênero, pasta, playlist): voltar,
// a arte ao lado dos dados, e o conteúdo.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../atoms/cover_tint.dart';
import 'page_template.dart';

class CollectionTemplate extends StatelessWidget {
  /// A partir desta largura, a arte fica ao lado dos dados.
  static const artMinWidth = 420.0;
  static const artSize = 180.0;

  /// A partir desta largura, a arte cresce.
  static const largeArtMinWidth = 760.0;
  static const largeArtSize = 232.0;

  final String title;
  final VoidCallback onBack;
  final Widget art;
  final Widget details;
  final List<Widget> slivers;

  /// A capa que tinge o alto da tela, ou null sem tinta.
  final String? tint;

  const CollectionTemplate({
    super.key,
    required this.title,
    required this.onBack,
    required this.art,
    required this.details,
    required this.slivers,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final about = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        details,
      ],
    );
    return CoverTint(
      path: tint,
      child: PageTemplate(
        back: TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: Text(context.l10n.back),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                if (width < artMinWidth) return about;
                final side = width < largeArtMinWidth ? artSize : largeArtSize;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: side, height: side, child: art),
                    const SizedBox(width: 24),
                    Expanded(child: about),
                  ],
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ...slivers,
        ],
      ),
    );
  }
}
