// lib/src/ui/molecules/volume_control.dart
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class VolumeControl extends StatelessWidget {
  /// O bastante para acertar o volume sem precisar de mira.
  static const maxSliderWidth = 200.0;

  /// De 0 a 1.
  final double volume;
  final ValueChanged<double> onChanged;

  const VolumeControl({
    super.key,
    required this.volume,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        size: 20,
      ),
      Flexible(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxSliderWidth),
          child: Semantics(
            label: context.l10n.volume,
            child: Slider(value: volume.clamp(0, 1), onChanged: onChanged),
          ),
        ),
      ),
    ],
  );
}
