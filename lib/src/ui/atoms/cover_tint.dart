// lib/src/ui/atoms/cover_tint.dart
//
// O fundo de uma tela tingido pela capa, do alto para baixo. A cor sai de uma
// miniatura, num isolate, e passa pelo tema: o que aparece é o tom do Material 3
// feito a partir dela, para o texto continuar legível.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// A cor mais marcante da imagem: a média das que têm mais saturação, em vez da
/// média de tudo, que numa capa sempre dá um cinza. Null sem cor nenhuma.
Color? dominantColor(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final small = img.copyResize(decoded, width: 32, height: 32);
  var r = 0.0, g = 0.0, b = 0.0, weight = 0.0;
  for (final pixel in small) {
    final top = [pixel.r, pixel.g, pixel.b].reduce((x, y) => x > y ? x : y);
    final low = [pixel.r, pixel.g, pixel.b].reduce((x, y) => x < y ? x : y);
    final chroma = (top - low) / 255;
    if (chroma < .15) continue;
    final w = chroma * chroma;
    r += pixel.r * w;
    g += pixel.g * w;
    b += pixel.b * w;
    weight += w;
  }
  if (weight == 0) return null;
  return Color.fromARGB(
    255,
    (r / weight).round(),
    (g / weight).round(),
    (b / weight).round(),
  );
}

int? _read(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  return dominantColor(file.readAsBytesSync())?.toARGB32();
}

final _cache = <String, Color?>{};

Future<Color?> _colorOf(String path) async {
  if (_cache.containsKey(path)) return _cache[path];
  final value = await compute(_read, path);
  return _cache[path] = value == null ? null : Color(value);
}

/// O tom do fundo para uma cor de capa, no tema atual.
Color coverTintOf(Color seed, Brightness brightness) => ColorScheme.fromSeed(
  seedColor: seed,
  brightness: brightness,
).primaryContainer.withValues(alpha: .45);

class CoverTint extends StatefulWidget {
  static const height = 360.0;

  /// A capa, ou null sem tinta.
  final String? path;
  final Widget child;

  const CoverTint({super.key, required this.path, required this.child});

  @override
  State<CoverTint> createState() => _CoverTintState();
}

class _CoverTintState extends State<CoverTint> {
  Color? _color;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CoverTint old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _load();
  }

  void _load() {
    final path = widget.path;
    if (path == null) {
      _color = null;
      return;
    }
    unawaited(
      _colorOf(path).then((color) {
        if (mounted && widget.path == path) setState(() => _color = color);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    if (color == null) return widget.child;
    final tint = coverTintOf(color, Theme.of(context).brightness);
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: CoverTint.height,
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tint, tint.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
