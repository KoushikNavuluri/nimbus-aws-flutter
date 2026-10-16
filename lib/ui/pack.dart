// The Sky Pack: a crimped foil wrapper with Puff peeking through the window.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/art.dart';
import '../store.dart';
import '../theme.dart';

const _foil = LinearGradient(
  begin: Alignment(-0.34, -0.94),
  end: Alignment(0.34, 0.94),
  colors: [Color(0xFFFF4D7E), Color(0xFFFF8FCF), Color(0xFF8C7CFF), Color(0xFF4AA3FF)],
  stops: [0.0, 0.3, 0.62, 1.0],
);

class PackArt extends StatefulWidget {
  const PackArt({super.key, this.w = 200, this.torn = false, this.label = 'Sky Pack', this.date});
  final double w;
  final bool torn;
  final String label;
  final DateTime? date;

  @override
  State<PackArt> createState() => _PackArtState();
}

class _PackArtState extends State<PackArt> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
      _c.value = 0.8;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    final h = (w * 1.42).roundToDouble();
    final d = widget.date ?? DateTime.now();
    final dateText = '${d.day.toString().padLeft(2, '0')} ${kMonths[d.month - 1].toUpperCase()} · 1 CLOUDLING';
    final win = w * 0.62;
    return SizedBox(
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x801D2352), offset: Offset(0, 20), blurRadius: 30, spreadRadius: -14)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: _foil))),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(animation: _c, builder: (c, _) => CustomPaint(painter: _SweepPainter(_c.value))),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: h * 0.09,
                child: AnimatedOpacity(
                  opacity: widget.torn ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: const CustomPaint(painter: _CrimpPainter(dashedBottom: true)),
                ),
              ),
              Positioned(bottom: 0, left: 0, right: 0, height: h * 0.08, child: const CustomPaint(painter: _CrimpPainter(dashedBottom: false))),
              Positioned(
                left: w * 0.1,
                right: w * 0.1,
                top: h * 0.16,
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('NIMBUS', style: tUi(math.max(12.0, w * 0.06), weight: FontWeight.w700, color: const Color(0xE6FFFFFF), spacing: math.max(12.0, w * 0.06) * 0.22)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        softWrap: false,
                        style: tDisplay(w * 0.15, weight: FontWeight.w700, color: Colors.white, height: 0.95)
                            .copyWith(shadows: const [Shadow(color: Color(0x591D2352), offset: Offset(0, 3))]),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: h * 0.44,
                left: (w - win) / 2,
                child: Container(
                  width: win,
                  height: win,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.2, -0.3),
                      colors: [Colors.white, Color(0xFFEAF0FF), Color(0xFFCFDAFF)],
                      stops: [0.0, 0.6, 1.0],
                    ),
                    border: Border.all(color: const Color(0xD91D2352), width: 2.5),
                  ),
                  child: Puff(size: w * 0.5, mood: 'wow', blink: false),
                ),
              ),
              Positioned(
                bottom: h * 0.10,
                left: 6,
                right: 6,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(dateText, textAlign: TextAlign.center, style: tMono(12, weight: FontWeight.w700, color: const Color(0xE6FFFFFF))),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-0.98, -0.17),
                        end: Alignment(0.98, 0.17),
                        colors: [Color(0x00FFFFFF), Color(0x59FFFFFF), Color(0x00FFFFFF)],
                        stops: [0.35, 0.5, 0.65],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xE61D2352), width: 2.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The strip that tears off the top of the pack.
class PackStrip extends StatelessWidget {
  const PackStrip({super.key, this.w = 200});
  final double w;
  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: (w * 1.42 * 0.09).roundToDouble(),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: _foil,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border.all(color: const Color(0xE61D2352), width: 2.5),
        ),
        child: const CustomPaint(painter: _CrimpPainter(dashedBottom: false, line: false)),
      );
}

class _SweepPainter extends CustomPainter {
  _SweepPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final prog = Curves.easeOutCubic.transform((t / 0.6).clamp(0.0, 1.0).toDouble());
    final p = 1.2 - 2.4 * prog;
    final band = Rect.fromLTWH(-1.5 * w * p, 0, 2.5 * w, size.height);
    final shader = const LinearGradient(
      begin: Alignment(-0.87, -0.5),
      end: Alignment(0.87, 0.5),
      colors: [Color(0x00FFFFFF), Color(0x8CFFFFFF), Color(0x00FFFFFF)],
      stops: [0.3, 0.45, 0.6],
    ).createShader(band);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_SweepPainter o) => o.t != t;
}

class _CrimpPainter extends CustomPainter {
  const _CrimpPainter({required this.dashedBottom, this.line = true});
  final bool dashedBottom;
  final bool line;

  @override
  void paint(Canvas canvas, Size size) {
    final stripe = Paint()..color = const Color(0x80FFFFFF);
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 3, size.height), stripe);
    }
    if (!line) return;
    if (dashedBottom) {
      final p = Paint()
        ..color = const Color(0x8C1D2352)
        ..strokeWidth = 2.5;
      final y = size.height - 1.25;
      for (double x = 0; x < size.width; x += 10) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 6, size.width), y), p);
      }
    } else {
      canvas.drawLine(
          const Offset(0, 1.25),
          Offset(size.width, 1.25),
          Paint()
            ..color = const Color(0x401D2352)
            ..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(_CrimpPainter o) => o.dashedBottom != dashedBottom || o.line != line;
}
