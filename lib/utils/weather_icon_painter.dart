// lib/widgets/weather_icon_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

String normalizeCondition(String raw) {
  final c = raw.toLowerCase().trim();
  if (c.contains('thunder') || c.contains('storm') || c.contains('lightning')) return 'stormy';
  if (c.contains('snow') || c.contains('sleet') || c.contains('hail') || c.contains('blizzard')) return 'snowy';
  if (c.contains('rain') || c.contains('shower') || c.contains('drizzle') || c.contains('mist') || c.contains('precip')) return 'rainy';
  if (c.contains('cold') || c.contains('freeze') || c.contains('frost') || c.contains('ice')) return 'cold';
  if (c.contains('wind') || c.contains('gale') || c.contains('breezy')) return 'windy';
  if (c.contains('partly') || c.contains('partial') || c.contains('scattered')) return 'partly cloudy';
  if (c.contains('cloud') || c.contains('overcast') || c.contains('fog') || c.contains('haz') || c.contains('smoke')) return 'cloudy';
  if (c.contains('sun') || c.contains('clear') || c.contains('fair') || c.contains('hot') || c.contains('warm') || c.contains('bright')) return 'sunny';
  return 'partly cloudy';
}

class AnimatedWeatherIcon extends StatefulWidget {
  final String condition;
  final double size;
  const AnimatedWeatherIcon({super.key, required this.condition, this.size = 120});

  @override
  State<AnimatedWeatherIcon> createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<AnimatedWeatherIcon>
    with TickerProviderStateMixin {
  // ✅ Declare as nullable — initialized safely in initState
  AnimationController? _floatCtrl;
  AnimationController? _rotateCtrl;
  AnimationController? _pulseCtrl;
  AnimationController? _rainCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _pulseCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _rainCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _floatCtrl?.dispose();
    _rotateCtrl?.dispose();
    _pulseCtrl?.dispose();
    _rainCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final floatCtrl  = _floatCtrl;
    final rotateCtrl = _rotateCtrl;
    final pulseCtrl  = _pulseCtrl;
    final rainCtrl   = _rainCtrl;

    // Not ready yet — show empty box
    if (floatCtrl == null || rotateCtrl == null || pulseCtrl == null || rainCtrl == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([floatCtrl, rotateCtrl, pulseCtrl, rainCtrl]),
      builder: (_, __) => Transform.translate(
        offset: Offset(0, floatCtrl.value * 8 - 4),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _WeatherIconPainter(
              condition:  normalizeCondition(widget.condition),
              rotateProg: rotateCtrl.value,
              pulseProg:  CurvedAnimation(parent: pulseCtrl, curve: Curves.easeInOut).value,
              rainProg:   rainCtrl.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherIconPainter extends CustomPainter {
  final String condition;
  final double rotateProg, pulseProg, rainProg;

  const _WeatherIconPainter({
    required this.condition,
    required this.rotateProg,
    required this.pulseProg,
    required this.rainProg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (condition) {
      case 'sunny':         _drawSun(canvas, size);           break;
      case 'partly cloudy': _drawPartlyCloudy(canvas, size);  break;
      case 'cloudy':        _drawCloudy(canvas, size);        break;
      case 'rainy':         _drawRainy(canvas, size);         break;
      case 'stormy':        _drawStormy(canvas, size);        break;
      case 'snowy':
      case 'cold':          _drawSnowy(canvas, size);         break;
      case 'windy':         _drawWindy(canvas, size);         break;
      default:              _drawPartlyCloudy(canvas, size);
    }
  }

  // ── SUNNY ──────────────────────────────────────────────────────────────────
  void _drawSun(Canvas canvas, Size sz) {
    final cx = sz.width * .5, cy = sz.height * .5, r = sz.width * .27;
    for (int i = 5; i >= 1; i--) {
      canvas.drawCircle(Offset(cx, cy), r + i * 9 + pulseProg * 5,
          Paint()..color = const Color(0xFFFFD54F).withOpacity(0.03 * i));
    }
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotateProg * math.pi * 2);
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * math.pi * 2;
      canvas.drawLine(
        Offset(math.cos(a) * (r + 6), math.sin(a) * (r + 6)),
        Offset(math.cos(a) * (r + (i % 2 == 0 ? 22 : 14)), math.sin(a) * (r + (i % 2 == 0 ? 22 : 14))),
        Paint()..color = const Color(0xFFFFE082).withOpacity(.85)
          ..strokeWidth = i % 2 == 0 ? 3.5 : 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..shader = RadialGradient(
          center: const Alignment(-.25, -.25),
          colors: const [Color(0xFFFFF9C4), Color(0xFFFFE57F), Color(0xFFFFD740), Color(0xFFFFC400)],
          stops: const [0, .35, .65, 1],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - r * .28, cy - r * .28), width: r * .55, height: r * .32),
      Paint()..color = Colors.white.withOpacity(.35),
    );
  }

  // ── PARTLY CLOUDY ──────────────────────────────────────────────────────────
  void _drawPartlyCloudy(Canvas canvas, Size sz) {
    final sx = sz.width * .63, sy = sz.height * .32, sr = sz.width * .22;
    canvas.drawCircle(Offset(sx, sy), sr + 10 + pulseProg * 5,
        Paint()..color = const Color(0xFFFFD54F).withOpacity(.22));
    canvas.drawCircle(Offset(sx, sy), sr,
        Paint()..shader = RadialGradient(
          center: const Alignment(-.3, -.3),
          colors: const [Color(0xFFFFF9C4), Color(0xFFFFE57F), Color(0xFFFFC400)],
        ).createShader(Rect.fromCircle(center: Offset(sx, sy), radius: sr)));
    _whiteCloud(canvas, Offset(sz.width * .38, sz.height * .62), sz.width * .72);
  }

  // ── CLOUDY ──────────────────────────────────────────────────────────────────
  void _drawCloudy(Canvas canvas, Size sz) {
    _whiteCloud(canvas, Offset(sz.width * .54, sz.height * .44), sz.width * .55, opacity: .7);
    _whiteCloud(canvas, Offset(sz.width * .42, sz.height * .60), sz.width * .78);
  }

  // ── RAINY ───────────────────────────────────────────────────────────────────
  void _drawRainy(Canvas canvas, Size sz) {
    _blueCloud(canvas, Offset(sz.width * .5, sz.height * .40), sz.width * .82);
    final p = Paint()..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    const cols = [.20, .33, .48, .61, .73, .42];
    for (int i = 0; i < cols.length; i++) {
      final off = (rainProg + i * .17) % 1.0;
      final x = sz.width * cols[i];
      final y0 = sz.height * (.65 + off * .26);
      final y1 = y0 + sz.height * .10;
      if (y1 < sz.height) {
        canvas.drawLine(Offset(x - 2, y0), Offset(x - 5, y1),
            p..color = const Color(0xFF90CAF9).withOpacity(.45 + off * .55));
      }
    }
  }

  // ── STORMY ──────────────────────────────────────────────────────────────────
  void _drawStormy(Canvas canvas, Size sz) {
    _blueCloud(canvas, Offset(sz.width * .5, sz.height * .36), sz.width * .82, dark: true);
    final rp = Paint()..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    const rcols = [.24, .42, .65, .76];
    for (int i = 0; i < rcols.length; i++) {
      final off = (rainProg + i * .25) % 1.0;
      final x = sz.width * rcols[i];
      final y0 = sz.height * (.60 + off * .22);
      final y1 = y0 + sz.height * .08;
      if (y1 < sz.height) {
        canvas.drawLine(Offset(x - 2, y0), Offset(x - 4, y1),
            rp..color = const Color(0xFF90CAF9).withOpacity(.4 + off * .4));
      }
    }
    if (pulseProg > .3) {
      final op = ((pulseProg - .3) / .7).clamp(0.0, 1.0);
      final bolt = Path()
        ..moveTo(sz.width * .54, sz.height * .55)
        ..lineTo(sz.width * .44, sz.height * .72)
        ..lineTo(sz.width * .53, sz.height * .70)
        ..lineTo(sz.width * .42, sz.height * .90);
      canvas.drawPath(bolt, Paint()..color = const Color(0xFFFFEE58).withOpacity(.35 * op)..strokeWidth = 14..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke);
      canvas.drawPath(bolt, Paint()..color = const Color(0xFFFFEE58).withOpacity(op)..strokeWidth = 4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke);
    }
  }

  // ── SNOWY ───────────────────────────────────────────────────────────────────
  void _drawSnowy(Canvas canvas, Size sz) {
    _whiteCloud(canvas, Offset(sz.width * .48, sz.height * .40), sz.width * .78);
    final sp = Paint()..color = Colors.white..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    const scols = [.24, .40, .57, .70, .36, .62];
    for (int i = 0; i < scols.length; i++) {
      final off = (rainProg + i * .18) % 1.0;
      final x = sz.width * scols[i];
      final y = sz.height * (.62 + off * .26);
      if (y < sz.height - 4) _snowflake(canvas, Offset(x, y), 5.5, sp);
    }
  }

  // ── WINDY ───────────────────────────────────────────────────────────────────
  void _drawWindy(Canvas canvas, Size sz) {
    final lp = Paint()..strokeWidth = 3.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final lines = [[.08,.35,.78,.35,.9],[.04,.50,.88,.50,.7],[.10,.65,.70,.65,.5],[.15,.78,.55,.78,.35]];
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i];
      final s = math.sin((rainProg * math.pi * 2) + i * .8) * 4;
      final path = Path()..moveTo(sz.width * l[0], sz.height * l[1] + s);
      path.cubicTo(
        sz.width * (l[0] + (l[2]-l[0])*.33), sz.height * l[1] - 10 + s,
        sz.width * (l[0] + (l[2]-l[0])*.66), sz.height * l[1] + 10 + s,
        sz.width * l[2], sz.height * l[3] + s,
      );
      canvas.drawPath(path, lp..color = Colors.white.withOpacity(l[4]));
    }
  }

  // ── WHITE 3D CLOUD ──────────────────────────────────────────────────────────
  void _whiteCloud(Canvas canvas, Offset c, double w, {double opacity = 1.0}) {
    final h = w * .44;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + h * .62), width: w * .75, height: h * .18),
      Paint()..color = const Color(0xFFB0C4DE).withOpacity(.30 * opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, c.dy + h * .12), width: w, height: h * .60), Radius.circular(h * .30)),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(opacity), const Color(0xFFDEEEFA).withOpacity(opacity)],
      ).createShader(Rect.fromCenter(center: c, width: w, height: h)),
    );
    final bp = Paint()..color = Colors.white.withOpacity(opacity);
    canvas.drawCircle(Offset(c.dx - w * .23, c.dy - h * .02), h * .36, bp);
    canvas.drawCircle(Offset(c.dx - w * .04, c.dy - h * .22), h * .50, bp);
    canvas.drawCircle(Offset(c.dx + w * .18, c.dy - h * .08), h * .38, bp);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - w * .48, c.dy + h * .08, w * .96, h * .22), Radius.circular(h * .10)),
      Paint()..color = const Color(0xFFCBDFF0).withOpacity(.55 * opacity),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx - h * .12, c.dy - h * .28), width: h * .22, height: h * .12),
      Paint()..color = Colors.white.withOpacity(.65 * opacity),
    );
  }

  // ── BLUE 3D CLOUD (rainy/stormy) ────────────────────────────────────────────
  void _blueCloud(Canvas canvas, Offset c, double w, {bool dark = false}) {
    final h   = w * .46;
    final top = dark ? const Color(0xFF3D5A80) : const Color(0xFF5B7FA6);
    final bot = dark ? const Color(0xFF1E2D40) : const Color(0xFF3A6186);
    final bmp = dark ? const Color(0xFF4A6D90) : const Color(0xFF6B9EC7);
    final shn = dark ? const Color(0xFF7AA8CC) : const Color(0xFF9BC8E8);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + h * .68), width: w * .8, height: h * .20),
      Paint()..color = Colors.black.withOpacity(.20),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, c.dy + h * .12), width: w, height: h * .62), Radius.circular(h * .30)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bot])
          .createShader(Rect.fromCenter(center: c, width: w, height: h)),
    );

    Shader bmpShader(Offset center, double r) => RadialGradient(
      center: const Alignment(-.3, -.4), colors: [bmp, bot],
    ).createShader(Rect.fromCircle(center: center, radius: r));

    final bl = Offset(c.dx - w * .24, c.dy - h * .02);
    canvas.drawCircle(bl, h * .40, Paint()..shader = bmpShader(bl, h * .40));
    final bc = Offset(c.dx - w * .04, c.dy - h * .26);
    canvas.drawCircle(bc, h * .52, Paint()..shader = bmpShader(bc, h * .52));
    final br = Offset(c.dx + w * .20, c.dy - h * .10);
    canvas.drawCircle(br, h * .38, Paint()..shader = bmpShader(br, h * .38));

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - w * .48, c.dy + h * .10, w * .96, h * .20), Radius.circular(h * .09)),
      Paint()..color = bot.withOpacity(.85),
    );
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx - w * .07, c.dy - h * .42), width: h * .28, height: h * .13),
        Paint()..color = shn.withOpacity(.60));
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx - w * .26, c.dy - h * .16), width: h * .18, height: h * .09),
        Paint()..color = shn.withOpacity(.45));
  }

  // ── SNOWFLAKE ───────────────────────────────────────────────────────────────
  void _snowflake(Canvas canvas, Offset c, double r, Paint p) {
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * math.pi * 2;
      canvas.drawLine(Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r),
          Offset(c.dx - math.cos(a) * r, c.dy - math.sin(a) * r), p);
    }
    canvas.drawCircle(c, 2.0, p..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _WeatherIconPainter o) =>
      o.rotateProg != rotateProg || o.pulseProg != pulseProg || o.rainProg != rainProg;
}