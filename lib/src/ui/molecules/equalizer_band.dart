// lib/src/ui/molecules/equalizer_band.dart
//
// Uma banda do equalizador: o ganho em cima, o controle de pé e a frequência
// embaixo.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../player/equalizer.dart';

class EqualizerBand extends StatefulWidget {
  static const sliderHeight = 180.0;

  /// A frequência, em Hz.
  final int frequency;
  final double gain;

  /// Vale ao soltar: cada mudança faz o mpv refazer os filtros. Null desativa.
  final ValueChanged<double>? onChanged;

  const EqualizerBand({
    super.key,
    required this.frequency,
    required this.gain,
    required this.onChanged,
  });

  @override
  State<EqualizerBand> createState() => _EqualizerBandState();
}

class _EqualizerBandState extends State<EqualizerBand> {
  /// O valor enquanto arrasta.
  double? _dragging;

  static String _signed(double gain) =>
      gain > 0 ? '+${gain.round()}' : '${gain.round()}';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final gain = _dragging ?? widget.gain;
    final hz = widget.frequency;
    final name = hz < 1000
        ? l.equalizerHz('$hz')
        : l.equalizerKhz('${hz ~/ 1000}');
    final onChanged = widget.onChanged;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(_signed(gain), style: theme.textTheme.bodySmall),
        ),
        SizedBox(
          height: EqualizerBand.sliderHeight,
          child: RotatedBox(
            quarterTurns: 3,
            child: Semantics(
              label: name,
              child: Slider(
                value: gain,
                min: -equalizerMaxGain,
                max: equalizerMaxGain,
                divisions: 2 * equalizerMaxGain.toInt(),
                semanticFormatterCallback: (v) => l.equalizerGain(_signed(v)),
                onChanged: onChanged == null
                    ? null
                    : (v) => setState(() => _dragging = v),
                onChangeEnd: onChanged == null
                    ? null
                    : (v) {
                        setState(() => _dragging = null);
                        onChanged(v);
                      },
              ),
            ),
          ),
        ),
        ExcludeSemantics(
          child: Text(
            name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
