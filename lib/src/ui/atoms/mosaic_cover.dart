// lib/src/ui/atoms/mosaic_cover.dart
//
// A capa de uma coleção: as capas que ela tem, de uma a quatro, sempre em grade.
// Sem nenhuma, uma decoração a partir do nome. Só capas de verdade entram: quatro
// artes genéricas, cada uma de uma cor, pareciam o logo de um outro sistema.
import 'package:flutter/material.dart';

import 'cover_art.dart';
import 'generic_art.dart';

class MosaicCover extends StatelessWidget {
  final List<({String? path, String seed})> covers;
  final String seed;
  final double? size;

  const MosaicCover({
    super.key,
    required this.covers,
    required this.seed,
    this.size,
  });

  /// Quem ocupa cada canto da grade: uma capa que falta repete na diagonal.
  static const _corners = {
    2: [0, 1, 1, 0],
    3: [0, 1, 2, 0],
    4: [0, 1, 2, 3],
  };

  @override
  Widget build(BuildContext context) {
    final real = [
      for (final cover in covers)
        if (cover.path != null) cover,
    ];
    final Widget art;
    if (real.isEmpty) {
      art = _Decoration(seed: seed);
    } else if (real.length == 1) {
      art = CoverArt(path: real.first.path, seed: real.first.seed, radius: 0);
    } else {
      final corners = _corners[real.length.clamp(2, 4)]!;
      Widget cell(int corner) => Expanded(
        child: CoverArt(
          path: real[corners[corner]].path,
          seed: real[corners[corner]].seed,
          radius: 0,
          plain: true,
        ),
      );
      art = Column(
        children: [
          Expanded(child: Row(children: [cell(0), cell(1)])),
          Expanded(child: Row(children: [cell(2), cell(3)])),
        ],
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: art),
    );
  }
}

/// A arte genérica, com ondas, bolhas ou arcos conforme o nome, e uma nota.
class _Decoration extends StatelessWidget {
  final String seed;

  const _Decoration({required this.seed});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Stack(
      fit: StackFit.expand,
      children: [
        GenericArt(seed: seed, showTitle: false),
        FractionallySizedBox(
          widthFactor: 0.34,
          heightFactor: 0.34,
          child: FittedBox(
            child: Icon(
              Icons.music_note_rounded,
              color: ArtPalette.of(stableHash(seed)).ink
                  .withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    ),
  );
}
