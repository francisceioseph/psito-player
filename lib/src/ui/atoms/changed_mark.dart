// lib/src/ui/atoms/changed_mark.dart
//
// O ponto de um campo que mudou e ainda não foi gravado.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class ChangedMark extends StatelessWidget {
  const ChangedMark({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.tagChanged,
    child: Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    ),
  );
}
