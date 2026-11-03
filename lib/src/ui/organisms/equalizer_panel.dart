// lib/src/ui/organisms/equalizer_panel.dart
//
// As bandas do equalizador lado a lado, rolando quando não cabem.
import 'dart:math';

import 'package:flutter/material.dart';

import '../../player/equalizer.dart';
import '../molecules/equalizer_band.dart';

class EqualizerPanel extends StatelessWidget {
  /// O bastante para o nome da banda mais larga.
  static const minBandWidth = 48.0;

  /// Mais que isso espalha demais as bandas.
  static const maxBandWidth = 64.0;

  final List<double> gains;

  /// A banda e o ganho novo. Null desativa.
  final void Function(int band, double gain)? onChanged;

  const EqualizerPanel({
    super.key,
    required this.gains,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = max(
        minBandWidth,
        min(maxBandWidth, constraints.maxWidth / gains.length),
      );
      final change = onChanged;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < gains.length; i++)
              SizedBox(
                width: width,
                child: EqualizerBand(
                  frequency: equalizerBands[i],
                  gain: gains[i],
                  onChanged: change == null ? null : (v) => change(i, v),
                ),
              ),
          ],
        ),
      );
    },
  );
}
