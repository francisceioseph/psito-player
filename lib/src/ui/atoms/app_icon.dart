// lib/src/ui/atoms/app_icon.dart
//
// O ícone do player, desenhado dos mesmos caminhos do icon.svg. Como imagem, ele
// precisaria de um caminho de asset diferente quando o player é um pacote de outro
// app. Um teste confere se os caminhos continuam iguais aos do arquivo.
import 'package:flutter/material.dart';

const appIconBackground = Color(0xFF80280C);
const appIconShadowPath =
    'M12070 13880 c-383 -96 -615 -386 -614 -770 1 -675 776 -1034 1294 '
    '-598 249 209 354 620 226 878 -30 61 -45 57 -71 -22 -56 -166 -171 '
    '-256 -314 -246 -385 28 -413 559 -33 630 92 17 91 16 54 48 -102 85 '
    '-365 124 -542 80z M7343 6650 c-633 -67 -1123 -573 -1159 -1195 -55 '
    '-959 955 -1642 1825 -1234 928 435 998 1729 121 2250 -195 115 -536 '
    '207 -703 188 -7 -1 -45 -5 -84 -9z';
const appIconBodyPath =
    'M3465 16351 c-200 -89 -190 -320 34 -746 429 -816 1129 -1275 2171 '
    '-1421 158 -22 762 -26 905 -6 50 7 126 17 170 23 233 31 537 98 748 '
    '164 123 39 162 31 88 -18 -195 -129 -790 -389 -1168 -511 -738 -237 '
    '-1597 -288 -2201 -131 -181 48 -231 45 -306 -17 -130 -107 -102 -260 '
    '107 -573 532 -799 1321 -998 2302 -580 498 212 894 458 1943 1209 752 '
    '539 1167 799 1712 1075 667 338 1455 586 2095 660 50 6 140 16 200 23 '
    '188 21 704 15 921 -11 813 -97 1451 -359 2049 -840 194 -156 188 -158 '
    '107 34 -382 902 -1384 1565 -2527 1670 -272 25 -9294 21 -9350 -4z '
    'M12420 14969 c-649 -25 -1254 -241 -1779 -633 -830 -622 -1306 -1677 '
    '-1075 -2383 107 -330 283 -545 844 -1037 771 -675 1030 -1111 1105 '
    '-1858 31 -310 -9 -911 -69 -1026 -64 -125 -284 -121 -350 7 -8 14 -26 '
    '97 -40 183 -106 631 -421 1078 -1010 1432 -180 109 -520 266 -537 249 '
    '-5 -5 -10 -1070 -12 -2368 -3 -2091 -5 -2370 -19 -2445 -66 -355 -191 '
    '-621 -415 -878 -40 -46 -73 -88 -73 -93 0 -5 1026 -9 2674 -9 2674 0 '
    '2674 0 2727 28 166 86 185 266 46 426 -750 863 -1325 2051 -1536 3171 '
    '-127 675 -167 1544 -96 2093 2 20 9 78 15 127 139 1138 549 2139 1227 '
    '2990 291 364 706 761 1046 1000 76 53 73 61 -48 163 -739 625 -1582 '
    '902 -2625 861z m-20 -1089 c100 -20 240 -81 240 -104 0 -9 -20 -15 -58 '
    '-18 -342 -32 -412 -497 -92 -619 187 -71 369 37 423 251 18 71 29 72 '
    '59 3 103 -234 57 -541 -115 -768 -257 -339 -787 -396 -1120 -119 -451 '
    '375 -348 1100 189 1324 165 68 311 84 474 50z M15460 13683 c-611 -432 '
    '-1281 -1272 -1600 -2005 -51 -117 -51 -118 42 -154 1574 -600 2186 '
    '-1476 1887 -2701 -51 -210 -38 -277 65 -324 115 -52 183 -6 464 315 '
    '954 1087 1121 2561 421 3723 -189 314 -519 693 -777 893 -43 32 -102 '
    '78 -132 102 -114 89 -274 198 -289 198 -9 -1 -45 -21 -81 -47z M8775 '
    '13508 c-127 -85 -322 -221 -435 -303 -113 -82 -279 -201 -370 -265 -91 '
    '-64 -228 -161 -305 -215 -1425 -1004 -2394 -2384 -3165 -4505 -229 '
    '-630 -464 -1504 -580 -2150 -10 -58 -30 -166 -44 -240 -58 -307 -119 '
    '-750 -155 -1130 -6 -58 -16 -155 -22 -216 -18 -187 31 -295 161 -353 '
    '52 -24 2130 -34 2130 -10 0 6 -29 47 -64 93 -646 827 -500 2004 330 '
    '2666 651 519 1603 568 2299 117 38 -25 73 -43 77 -41 4 3 8 1185 8 '
    '2627 0 2627 2 2777 36 3007 41 277 149 635 280 927 30 68 54 129 52 '
    '135 -2 6 -107 -59 -233 -144z M13622 11047 c-12 -13 -82 -253 -107 '
    '-362 -9 -38 -27 -116 -41 -173 -87 -364 -144 -917 -144 -1394 l0 -188 '
    '113 0 c659 0 1324 329 1756 869 128 160 126 154 57 255 -255 377 -861 '
    '761 -1545 982 -87 28 -76 27 -89 11z';

/// Lê os comandos M, m, c, l e z, os únicos que o icon.svg usa.
Path parseIconPath(String data) {
  final path = Path();
  final tokens = RegExp(r'[Mmclz]|-?\d+').allMatches(data).map((m) => m[0]!);
  final numbers = <double>[];
  String? command;
  void flush() {
    switch (command) {
      case 'M':
        path.moveTo(numbers[0], numbers[1]);
      case 'm':
        path.relativeMoveTo(numbers[0], numbers[1]);
      case 'l':
        path.relativeLineTo(numbers[0], numbers[1]);
      case 'c':
        path.relativeCubicTo(
          numbers[0],
          numbers[1],
          numbers[2],
          numbers[3],
          numbers[4],
          numbers[5],
        );
    }
    numbers.clear();
  }

  for (final token in tokens) {
    final number = double.tryParse(token);
    if (number == null) {
      command = token;
      if (token == 'z') path.close();
      continue;
    }
    numbers.add(number);
    if (numbers.length == (command == 'c' ? 6 : 2)) flush();
  }
  return path;
}

class AppIcon extends StatelessWidget {
  final double size;

  const AppIcon({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: const _AppIconPainter(),
    ),
  );
}

class _AppIconPainter extends CustomPainter {
  static final _shadow = parseIconPath(appIconShadowPath);
  static final _body = parseIconPath(appIconBodyPath)
    ..fillType = PathFillType.evenOdd;

  const _AppIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 2048;
    canvas
      ..save()
      ..scale(scale)
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 2048, 2048),
          const Radius.circular(360),
        ),
        Paint()..color = appIconBackground,
      )
      // Os caminhos estão em décimos, e com o y para cima
      ..translate(0, 2048)
      ..scale(0.1, -0.1)
      ..drawPath(_shadow, Paint()..color = const Color(0xFFFE8363))
      ..drawPath(_body, Paint()..color = const Color(0xFFFCD8C4))
      ..restore();
  }

  @override
  bool shouldRepaint(_AppIconPainter oldDelegate) => false;
}
