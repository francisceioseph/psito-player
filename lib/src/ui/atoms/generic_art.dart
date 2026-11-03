// lib/src/ui/atoms/generic_art.dart
//
// A capa de quem não tem capa: um degradê com profundidade, um grafismo discreto e,
// se couber, o título, sempre os mesmos para o mesmo álbum. As cores são conteúdo,
// como uma capa de verdade, e não saem do tema: nascem do nome, sem nenhuma escrita
// no código.
import 'dart:math';

import 'package:flutter/material.dart';

/// Um hash que não muda entre execuções, ao contrário do `hashCode`.
int stableHash(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// As cores de uma arte: tons vizinhos, escuros o bastante para o texto claro.
@immutable
class ArtPalette {
  final Color deep;
  final Color middle;
  final Color glow;
  final Color ink;

  const ArtPalette(this.deep, this.middle, this.glow, this.ink);

  factory ArtPalette.of(int hash) {
    final hue = (hash % 360).toDouble();
    // Os vizinhos dão a sensação de luz. O complementar é que parecia de brinquedo
    final step = 16.0 + (hash >> 9) % 20;
    final side = (hash >> 4).isEven ? 1 : -1;
    HSLColor color(double h, double s, double l) =>
        HSLColor.fromAHSL(1, (h + 360) % 360, s, l);
    return ArtPalette(
      color(hue, 0.62, 0.20).toColor(),
      color(hue + side * step, 0.58, 0.34).toColor(),
      color(hue + side * step * 2, 0.62, 0.50).toColor(),
      color(hue, 0.30, 0.96).toColor(),
    );
  }
}

class GenericArt extends StatelessWidget {
  /// A partir deste lado, o título entra na arte.
  static const titleMinSide = 96.0;

  /// O que decide a arte, como `título|artista`.
  final String seed;

  /// Com o título desenhado, se [seed] traz um e ele couber.
  final bool showTitle;

  /// Com o grafismo. Num mosaico, quatro deles disputam o olho.
  final bool motif;

  const GenericArt({
    super.key,
    required this.seed,
    this.showTitle = true,
    this.motif = true,
  });

  @override
  Widget build(BuildContext context) {
    final parts = seed.split('|');
    return CustomPaint(
      painter: _ArtPainter(
        stableHash(seed),
        title: showTitle && parts.length > 1 ? parts.first.trim() : '',
        motif: motif,
        style: Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ArtPainter extends CustomPainter {
  final int hash;
  final String title;
  final TextStyle style;
  final bool motif;

  _ArtPainter(
    this.hash, {
    required this.title,
    required this.style,
    required this.motif,
  });

  /// Um número de 0 a 1 tirado do hash, diferente para cada [slot].
  double _unit(int slot) => ((hash >> (slot * 3)) & 0xff) / 255;

  void _background(Canvas canvas, Rect rect, ArtPalette palette) {
    final angle = _unit(1) * 2 * pi;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(cos(angle), sin(angle)),
          end: Alignment(-cos(angle), -sin(angle)),
          colors: [palette.deep, palette.middle],
        ).createShader(rect),
    );
    final center = Alignment(_unit(2) * 1.6 - 0.8, _unit(3) * 1.6 - 0.8);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: center,
          radius: 0.7 + _unit(4) * 0.4,
          colors: [
            palette.glow.withValues(alpha: 0.7),
            palette.glow.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  void _rings(Canvas canvas, Size size, Color ink) {
    final s = size.shortestSide;
    final center = Offset(
      size.width * (_unit(5) > .5 ? 1 : 0),
      size.height * (_unit(6) > .5 ? 0 : 1),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, s * 0.006)
      ..color = ink.withValues(alpha: 0.16);
    for (var r = s * 0.22; r < s * 1.3; r += s * 0.07) {
      canvas.drawCircle(center, r, paint);
    }
  }

  /// Uma onda de som, espelhada em torno de uma linha.
  void _bars(Canvas canvas, Size size, Color ink) {
    final s = size.shortestSide;
    const count = 17;
    final width = size.width / (count * 1.7);
    final middle = s * 0.36;
    final paint = Paint()..color = ink.withValues(alpha: 0.18);
    for (var i = 0; i < count; i++) {
      final wave = sin(i * (0.5 + _unit(5)) + _unit(6) * 6);
      // As pontas mais baixas, como uma frase de música
      final fade = sin((i + 0.5) / count * pi);
      final half = s * (0.03 + 0.2 * fade * (wave + 1.2) / 2.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            (i + 0.3) * size.width / count,
            middle - half,
            (i + 0.3) * size.width / count + width,
            middle + half,
          ),
          Radius.circular(width / 2),
        ),
        paint,
      );
    }
  }

  void _arcs(Canvas canvas, Size size, Color ink) {
    final s = size.shortestSide;
    final paint = Paint()..color = ink.withValues(alpha: 0.07);
    final x = size.width * (_unit(5) * 0.5 + 0.5);
    canvas.drawCircle(Offset(x, s * 0.1), s * 0.55, paint);
    canvas.drawCircle(Offset(x - s * 0.2, s * 0.05), s * 0.32, paint);
  }

  void _grooves(Canvas canvas, Size size, Color ink) {
    final s = size.shortestSide;
    final paint = Paint()
      ..strokeWidth = max(1, s * 0.012)
      ..strokeCap = StrokeCap.round
      ..color = ink.withValues(alpha: 0.12);
    for (var y = s * 0.1; y < size.height; y += s * 0.09) {
      canvas.drawLine(
        Offset(-s * 0.1, y + s * 0.4),
        Offset(size.width + s * 0.1, y - s * 0.4),
        paint,
      );
    }
  }

  void _title(Canvas canvas, Size size, Color ink) {
    final s = size.shortestSide;
    if (title.isEmpty || s < GenericArt.titleMinSide) return;
    final margin = s * 0.09;
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: style.copyWith(
          color: ink,
          fontSize: s * 0.115,
          fontWeight: FontWeight.w700,
          height: 1.12,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: size.width - margin * 2);
    painter.paint(
      canvas,
      Offset(margin, size.height - margin - painter.height),
    );
    painter.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final palette = ArtPalette.of(hash);
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    _background(canvas, rect, palette);
    if (motif) {
      switch ((hash >> 5) % 4) {
        case 0:
          _rings(canvas, size, palette.ink);
        case 1:
          _bars(canvas, size, palette.ink);
        case 2:
          _arcs(canvas, size, palette.ink);
        default:
          _grooves(canvas, size, palette.ink);
      }
    }
    // O pé mais escuro segura o título sobre qualquer fundo
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.45, 1],
          colors: [
            palette.deep.withValues(alpha: 0),
            palette.deep.withValues(alpha: 0.8),
          ],
        ).createShader(rect),
    );
    _title(canvas, size, palette.ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.hash != hash ||
      old.title != title ||
      old.style != style ||
      old.motif != motif;
}
