// THE SIGNATURE: holographic Cloudling cards. Your finger (or an idle drift) tilts the
// card and slides a rainbow foil + glare across it. Foil gets stronger with mastery.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../art/art.dart';
import '../data/services.dart';
import '../store.dart';
import '../theme.dart';
import 'kit.dart';

class CardSize {
  const CardSize(this.w, this.pad, this.nick, this.name, this.tag, this.critter, this.art, this.radius);
  final double w;
  final double pad;
  final double nick;
  final double name;
  final double tag;
  final double critter;
  final double art;
  final double radius;
  double get h => (w * 1.4).roundToDouble();
}

const Map<String, CardSize> kCardSizes = {
  'lg': CardSize(276, 10, 26, 15, 14, 150, 170, 24),
  'md': CardSize(164, 7, 17, 12, 12, 92, 104, 18),
  'sm': CardSize(150, 6, 16, 12, 12, 82, 92, 16),
};

CardSize cardSize(String s) => kCardSizes[s] ?? kCardSizes['lg']!;

class CardFront extends StatelessWidget {
  const CardFront({super.key, required this.id, this.size = 'lg', this.level = 0, this.silhouette = false, this.mood = 'happy'});
  final String id;
  final String size;
  final int level;
  final bool silhouette;
  final String mood;

  @override
  Widget build(BuildContext context) {
    final s = kSvc[id]!;
    final t = s.t;
    final z = cardSize(size);
    final big = size == 'lg';
    final sil = silhouette;
    return Container(
      padding: EdgeInsets.all(z.pad - 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(z.radius),
        color: sil ? const Color(0xFFC9D2EE) : null,
        gradient: sil
            ? null
            : LinearGradient(
                begin: const Alignment(-0.34, -0.94),
                end: const Alignment(0.34, 0.94),
                colors: [tintColor(t.color, 0.15), t.color, shadeColor(t.color, 0.12)],
                stops: const [0.0, 0.55, 1.0],
              ),
        border: Border.all(color: const Color(0xE61D2352), width: 2),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: C.cotton,
          borderRadius: BorderRadius.circular(z.radius - 6),
          border: Border.all(color: const Color(0xD91D2352), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Expanded(child: Text(sil ? '???' : s.nick, maxLines: 1, overflow: TextOverflow.ellipsis, style: tDisplay(z.nick, height: 1.0))),
                  Text('#${s.no.toString().padLeft(2, '0')}', style: tMono(12, weight: FontWeight.w700, color: C.ink3)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Container(
                height: z.art,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: sil ? const Color(0xFFE8ECF8) : t.soft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x1F1D2352), width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(child: CustomPaint(painter: DotsPainter())),
                    if (!sil)
                      Positioned(
                        left: -24,
                        top: 12,
                        child: Container(width: 96, height: 32, decoration: BoxDecoration(color: const Color(0xB3FFFFFF), borderRadius: BorderRadius.circular(99))),
                      ),
                    if (!sil)
                      Positioned(
                        right: -14,
                        bottom: 20,
                        child: Container(width: 80, height: 28, decoration: BoxDecoration(color: const Color(0x99FFFFFF), borderRadius: BorderRadius.circular(99))),
                      ),
                    Critter(id, size: z.critter, silhouette: sil, mood: mood),
                    if (big && !sil) Positioned(top: 8, right: 8, child: Stars(n: s.rarity, size: 14)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ClipRect(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sil ? 'Undiscovered' : s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tUi(z.name, weight: FontWeight.w700, height: 1.15)),
                      if (big)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(sil ? 'Keep opening packs to find it.' : s.tagline,
                              maxLines: 2, overflow: TextOverflow.ellipsis, style: tUi(z.tag, color: C.ink2, height: 1.3)),
                        ),
                      if (big && !sil)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final x in s.stats)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: t.soft, borderRadius: BorderRadius.circular(8)),
                                  child: Text(x, style: tUi(12, weight: FontWeight.w700, color: t.ink)),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text((sil ? 'Not found' : t.label).toUpperCase(),
                        maxLines: 1, overflow: TextOverflow.clip, style: tUi(12, weight: FontWeight.w700, spacing: 1.2, color: sil ? C.ink3 : t.ink)),
                  ),
                  if (!sil)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: level == 2 ? null : const Color(0xFFEEF1FB),
                        gradient: level == 2 ? const LinearGradient(colors: [C.flamingo, C.grape, C.blue]) : null,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(svcLevelLabel(level).toUpperCase(),
                          style: tUi(12, weight: FontWeight.w700, spacing: 1.2, color: level == 2 ? Colors.white : C.ink2)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardBackLogo extends StatelessWidget {
  const CardBackLogo({super.key, this.size = 'lg'});
  final String size;

  @override
  Widget build(BuildContext context) {
    final z = cardSize(size);
    final r = z.radius;
    final lg = size == 'lg';
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: const Color(0xE61D2352), borderRadius: BorderRadius.circular(r)),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: C.cotton, borderRadius: BorderRadius.circular(r - 2)),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: const Color(0xE61D2352), borderRadius: BorderRadius.circular(math.max(4.0, r - 9))),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: const Color(0xFF2B3170), borderRadius: BorderRadius.circular(math.max(2.0, r - 11))),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(child: CustomPaint(painter: _BackPattern())),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LogoMark(width: lg ? 96 : 56),
                    const SizedBox(height: 4),
                    Text('Nimbus', style: tDisplay(lg ? 26 : 16, color: Colors.white)),
                    Text('CLOUDEX', style: tUi(12, weight: FontWeight.w700, color: Colors.white70, spacing: 2.4)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackPattern extends CustomPainter {
  const _BackPattern();
  @override
  void paint(Canvas canvas, Size size) {
    final a = Paint()..color = const Color(0x29FFFFFF);
    final b = Paint()..color = const Color(0x1AFFFFFF);
    for (double y = 0; y < size.height; y += 26) {
      for (double x = 0; x < size.width; x += 26) {
        canvas.drawCircle(Offset(x + 6.5, y + 6.5), 6, a);
        canvas.drawCircle(Offset(x + 19.5, y + 19.5), 4, b);
      }
    }
  }

  @override
  bool shouldRepaint(_BackPattern oldDelegate) => false;
}

class CardInfoBack extends StatelessWidget {
  const CardInfoBack({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final s = kSvc[id]!;
    final t = s.t;
    final rows = [('Speed', s.power.speed), ('Scale', s.power.scale), ('Simplicity', s.power.simplicity), ('Thrift', s.power.thrift)];
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: const Color(0xE61D2352), borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(22)),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: const Color(0xE61D2352), borderRadius: BorderRadius.circular(16)),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: C.cotton, borderRadius: BorderRadius.circular(14)),
            child: LayoutBuilder(
              builder: (c, box) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: box.maxWidth,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text("${s.nick}'s stats", style: tDisplay(20))),
                            Critter(id, size: 40, shadow: false),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final r in rows)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                SizedBox(width: 82, child: Text(r.$1.toUpperCase(), style: tUi(12, weight: FontWeight.w700, spacing: 0.9, color: C.ink3))),
                                for (var i = 1; i <= 5; i++)
                                  Container(
                                    width: 22,
                                    height: 10,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: i <= r.$2 ? t.color : C.track,
                                      borderRadius: BorderRadius.circular(99),
                                      border: i <= r.$2 ? Border.all(color: const Color(0x991D2352), width: 1.5) : null,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: t.soft, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('EXAM WHISPER', style: tUi(12, weight: FontWeight.w700, spacing: 1.2, color: t.ink)),
                              const SizedBox(height: 2),
                              Text(s.examTip, style: tUi(13, color: t.ink, height: 1.3)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(text: 'Price tag: ', style: tUi(13, weight: FontWeight.w700, height: 1.3)),
                            TextSpan(text: s.price, style: tUi(13, color: C.ink2, height: 1.3)),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('PAIRS WITH', style: tUi(12, weight: FontWeight.w700, spacing: 0.9, color: C.ink3)),
                            const SizedBox(width: 8),
                            for (final p in s.pairs) Padding(padding: const EdgeInsets.only(right: 4), child: Critter(p, size: 34, shadow: false)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rainbow foil (colour-dodge) + pointer glare + sparkle grain for holo cards.
class FoilPainter extends CustomPainter {
  FoilPainter({required this.pos, required this.strength, required this.sparkle, required this.radius, Listenable? repaint}) : super(repaint: repaint);
  final Offset Function() pos;
  final double strength;
  final bool sparkle;
  final double radius;

  static const _rainbow = [0xFFFF4D7E, 0xFFFF4D7E, 0xFFFFC23D, 0xFF86CF4E, 0xFF4AA3FF, 0xFF8C7CFF, 0xFFFF4D7E];
  static const _alpha = [0.0, 0.42, 0.42, 0.42, 0.42, 0.42, 0.0];

  @override
  void paint(Canvas canvas, Size size) {
    final o = pos();
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final fx = 0.2 + o.dx * 0.6;
    final fy = 0.2 + o.dy * 0.6;
    final big = Rect.fromLTWH(-1.6 * w * fx, -1.6 * h * fy, w * 2.6, h * 2.6);
    final shader = LinearGradient(
      begin: const Alignment(-0.906, -0.423),
      end: const Alignment(0.906, 0.423),
      colors: [for (var i = 0; i < _rainbow.length; i++) Color(_rainbow[i]).withValues(alpha: _alpha[i] * strength)],
      stops: const [0.2, 0.3, 0.38, 0.46, 0.54, 0.62, 0.72],
    ).createShader(big);
    canvas.drawRect(rect, Paint()
      ..shader = shader
      ..blendMode = BlendMode.colorDodge);

    final c = Offset(o.dx * w, o.dy * h);
    final far = [Offset.zero, Offset(w, 0), Offset(0, h), Offset(w, h)].fold<double>(1.0, (m, k) => math.max(m, (k - c).distance));
    final glare = RadialGradient(
      colors: [Colors.white.withValues(alpha: 0.65 * strength), Colors.white.withValues(alpha: 0.0)],
      stops: const [0.0, 0.38],
    ).createShader(Rect.fromCircle(center: c, radius: far));
    canvas.drawRect(rect, Paint()
      ..shader = glare
      ..blendMode = BlendMode.colorDodge);

    if (sparkle) {
      final p1 = Paint()
        ..color = const Color(0xCCFFFFFF)
        ..blendMode = BlendMode.overlay;
      for (double y = 0; y < h; y += 23) {
        for (double x = 0; x < w; x += 23) {
          canvas.drawCircle(Offset(x + 11.5, y + 11.5), 1.2, p1);
        }
      }
      final p2 = Paint()
        ..color = const Color(0x99FFFFFF)
        ..blendMode = BlendMode.overlay;
      // Offset grid (17 - 37, 11 - 37) written as double literals so Dart accepts them.
      for (double y = -20.0; y < h; y += 37) {
        for (double x = -26.0; x < w; x += 37) {
          canvas.drawCircle(Offset(x + 18.5, y + 18.5), 0.9, p2);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FoilPainter oldDelegate) => oldDelegate.strength != strength || oldDelegate.sparkle != sparkle || oldDelegate.radius != radius;
}

class HoloCard extends StatefulWidget {
  const HoloCard({
    super.key,
    required this.id,
    this.size = 'lg',
    this.level,
    this.flipped = false,
    this.back = 'info',
    this.tilt = true,
    this.idle = true,
    this.silhouette = false,
    this.onTap,
    this.mood = 'happy',
  });
  final String id;
  final String size;
  final int? level;
  final bool flipped;
  final String back; // info | logo
  final bool tilt;
  final bool idle;
  final bool silhouette;
  final VoidCallback? onTap;
  final String mood;

  @override
  State<HoloCard> createState() => _HoloCardState();
}

class _HoloCardState extends State<HoloCard> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  double _px = 0.5;
  double _py = 0.5;
  double _rx = 0;
  double _ry = 0;
  double _trx = 0;
  double _try = 0;
  bool _hover = false;
  bool _rm = false;

  bool get _idleOn => widget.idle && widget.tilt && !_rm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rm = reduceMotion(context);
    _sync();
  }

  @override
  void didUpdateWidget(HoloCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!_idleOn && !_hover) {
      _trx = 0;
      _try = 0;
    }
    _start();
  }

  void _start() {
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration e) {
    if (_idleOn && !_hover) {
      final k = e.inMicroseconds / 1e6;
      final px = 0.5 + math.sin(k * 0.9) * 0.32;
      final py = 0.5 + math.cos(k * 0.7) * 0.22;
      _try = (px - 0.5) * 18;
      _trx = -(py - 0.5) * 14;
      _px = px;
      _py = py;
    }
    _rx += (_trx - _rx) * 0.16;
    _ry += (_try - _ry) * 0.16;
    _frame.value++;
    if (!_idleOn && !_hover && (_rx - _trx).abs() < 0.05 && (_ry - _try).abs() < 0.05) {
      _rx = _trx;
      _ry = _try;
      _ticker.stop();
    }
  }

  void _point(Offset local, Size size) {
    if (!widget.tilt || _rm) return;
    final px = (local.dx / size.width).clamp(0.0, 1.0).toDouble();
    final py = (local.dy / size.height).clamp(0.0, 1.0).toDouble();
    _hover = true;
    _try = (px - 0.5) * 26;
    _trx = -(py - 0.5) * 26;
    _px = px;
    _py = py;
    _start();
  }

  void _leave() {
    _hover = false;
    if (!widget.idle) {
      _trx = 0;
      _try = 0;
    }
    _start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final z = cardSize(widget.size);
    final h = z.h;
    final st = watch(context).state;
    final lvl = widget.level ?? st.collected[widget.id]?.level ?? 0;
    final sil = widget.silhouette;
    final double foil = sil ? 0.0 : (lvl == 2 ? 0.95 : (lvl == 1 ? 0.55 : 0.32));
    final s = kSvc[widget.id];

    final front = Stack(
      children: [
        Positioned.fill(child: CardFront(id: widget.id, size: widget.size, level: lvl, silhouette: sil, mood: widget.mood)),
        if (foil > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: FoilPainter(pos: () => Offset(_px, _py), strength: foil, sparkle: lvl == 2, radius: z.radius, repaint: _frame),
              ),
            ),
          ),
      ],
    );
    final back = widget.back == 'logo' ? CardBackLogo(size: widget.size) : CardInfoBack(id: widget.id);
    final flip = widget.flipped ? 1.0 : 0.0;

    final flipper = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: flip, end: flip),
      duration: _rm ? Duration.zero : const Duration(milliseconds: 560),
      curve: const Cubic(0.34, 1.25, 0.64, 1),
      builder: (c, v, _) {
        final angle = v * math.pi;
        final showFront = math.cos(angle) >= 0;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0011)
            ..rotateY(angle),
          child: showFront ? front : Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: back),
        );
      },
    );

    final tilted = AnimatedBuilder(
      animation: _frame,
      builder: (c, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateX(-_rx * math.pi / 180)
          ..rotateY(-_ry * math.pi / 180),
        child: child,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(z.radius),
          boxShadow: const [BoxShadow(color: Color(0x471D2352), offset: Offset(0, 18), blurRadius: 22, spreadRadius: -6)],
        ),
        child: flipper,
      ),
    );

    final size = Size(z.w, h);
    return Semantics(
      button: widget.onTap != null,
      label: sil ? 'Undiscovered Cloudling card' : '${s?.nick ?? 'Cloudling'} card, ${svcLevelLabel(lvl)}',
      child: SizedBox(
        width: z.w,
        height: h,
        child: MouseRegion(
          cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          onHover: (e) => _point(e.localPosition, size),
          onExit: (_) => _leave(),
          child: Listener(
            onPointerDown: (e) => _point(e.localPosition, size),
            onPointerMove: (e) => _point(e.localPosition, size),
            onPointerUp: (_) => _leave(),
            onPointerCancel: (_) => _leave(),
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: tilted),
          ),
        ),
      ),
    );
  }
}
