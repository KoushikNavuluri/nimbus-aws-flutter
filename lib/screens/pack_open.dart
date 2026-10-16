import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/art.dart';
import '../data/services.dart';
import '../nav.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/holo_card.dart';
import '../ui/kit.dart';
import '../ui/pack.dart';

class PackOpenScreen extends StatefulWidget {
  const PackOpenScreen({super.key});
  @override
  State<PackOpenScreen> createState() => _PackOpenScreenState();
}

class _PackOpenScreenState extends State<PackOpenScreen> {
  String _phase = 'ready'; // ready | tearing | rising | flip | revealed
  String? _card;
  bool _dupe = false;
  late final bool _available;
  late final bool _bonus;
  final List<Timer> _timers = [];
  double? _startX;

  @override
  void initState() {
    super.initState();
    final st = readStore(context).state;
    _available = st.packAvailable;
    _bonus = st.pack.opened == dayKey();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _later(int ms, VoidCallback fn) {
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (mounted) fn();
    }));
  }

  void _tear() {
    if (_phase != 'ready' || !_available) return;
    final store = readStore(context);
    final id = store.openPack();
    if (id == null) return;
    final was = store.state.collected.containsKey(id);
    setState(() {
      _card = id;
      _dupe = was;
      _phase = 'tearing';
    });
    Sfx.play('tear');
    _later(450, () {
      setState(() => _phase = 'rising');
      Sfx.play('whoosh');
    });
    _later(1250, () {
      setState(() => _phase = 'flip');
      Sfx.play('flip');
    });
    _later(1850, () {
      setState(() => _phase = 'revealed');
      Sfx.play('sparkle');
      Confetti.fire(y: 0.42, count: 150);
      store.collect(id, 0);
      store.addXP(was ? 25 : 10, 0.5);
      store.hero('pack');
      store.stamp('first-pack');
    });
  }

  void _close() => Nav.pop();

  @override
  Widget build(BuildContext context) {
    final store = watch(context);
    final card = _card;
    final s = card != null ? kSvc[card] : null;
    final top = Insets.topOf(context);
    final bottom = Insets.bottomOf(context);
    final revealed = _phase == 'revealed';
    final cardUp = _phase == 'flip' || revealed;

    Widget content;
    if (!_available && _phase == 'ready') {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Puff(size: 140, mood: 'sleepy', cap: true),
              const SizedBox(height: 12),
              Text('No packs left today.', textAlign: TextAlign.center, style: tDisplay(26, color: Colors.white)),
              const SizedBox(height: 4),
              Text('A fresh one lands at midnight. Ace a quiz to earn a bonus pack.', textAlign: TextAlign.center, style: tUi(15, color: const Color(0xBFFFFFFF), height: 1.4)),
              const SizedBox(height: 20),
              NBtn(label: 'Okay, Puff', onTap: _close),
            ],
          ),
        ),
      );
    } else {
      final Widget title;
      if (_phase == 'ready') {
        title = Column(
          key: const ValueKey('t1'),
          children: [
            Eyebrow(_bonus ? 'Bonus Sky Pack' : "Today's Sky Pack", color: const Color(0xB3FFFFFF)),
            const SizedBox(height: 4),
            Text('Swipe to tear it open', style: tDisplay(28, color: Colors.white)),
          ],
        );
      } else if (revealed && s != null) {
        title = Column(
          key: const ValueKey('t3'),
          children: [
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: s.t.color, borderRadius: BorderRadius.circular(99)),
              child: Text(_dupe ? 'DUPLICATE · +25 XP' : 'NEW CLOUDLING!', style: tUi(13, weight: FontWeight.w700, color: C.ink, spacing: 1.5)),
            ),
            const SizedBox(height: 8),
            Text(s.nick, style: tDisplay(34, color: Colors.white, height: 1.0)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.name, style: tUi(15, weight: FontWeight.w600, color: const Color(0xCCFFFFFF))),
                const SizedBox(width: 8),
                Stars(n: s.rarity, size: 13),
              ],
            ),
          ],
        );
      } else {
        title = Padding(key: const ValueKey('t2'), padding: const EdgeInsets.only(top: 24), child: Text('Ooh…', style: tDisplay(28, color: Colors.white)));
      }

      final cardWidget = card == null
          ? const SizedBox.shrink()
          : AnimatedContainer(
              duration: const Duration(milliseconds: 620),
              curve: const Cubic(0.3, 1.25, 0.6, 1),
              transformAlignment: Alignment.center,
              transform: _phase == 'tearing'
                  ? (Matrix4.translationValues(0, 40, 0)..scale(0.72))
                  : _phase == 'rising'
                      ? (Matrix4.translationValues(0, -150, 0)..scale(0.72))
                      : Matrix4.identity(),
              child: HoloCard(
                id: card,
                size: 'lg',
                level: store.state.collected[card]?.level ?? 0,
                flipped: !cardUp,
                back: 'logo',
                idle: revealed,
              ),
            );

      final packWidget = Positioned(
        left: 18,
        top: 10,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 420),
          opacity: cardUp ? 0.0 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: kEase,
            transformAlignment: Alignment.center,
            transform: _phase == 'ready'
                ? Matrix4.identity()
                : cardUp
                    ? (Matrix4.translationValues(0, 520, 0)..rotateZ(8 * math.pi / 180))
                    : Matrix4.translationValues(0, 60, 0),
            child: Listener(
              onPointerDown: (e) => _startX = e.position.dx,
              onPointerMove: (e) {
                final sx = _startX;
                if (sx != null && (e.position.dx - sx).abs() > 70) {
                  _startX = null;
                  _tear();
                }
              },
              onPointerUp: (_) => _startX = null,
              child: Semantics(
                button: true,
                label: 'Tear open the Sky Pack',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _tear,
                  child: Wobble(
                    enabled: _phase == 'ready',
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PackArt(w: 240, torn: _phase != 'ready'),
                        if (_phase == 'ready')
                          const Positioned(left: 0, top: 0, child: PackStrip(w: 240))
                        else if (!cardUp)
                          const Positioned(left: 0, top: 0, child: _FlyAway(child: PackStrip(w: 240))),
                        if (_phase == 'ready') const Positioned(top: -40, left: 16, child: IgnorePointer(child: _SwipeHint())),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final Widget actions;
      if (_phase == 'ready') {
        actions = Center(key: const ValueKey('b1'), child: NBtn(label: 'or tap to open', kind: Btn.glass, sound: null, fontSize: 15, padH: 24, onTap: _tear));
      } else if (revealed && s != null) {
        actions = Column(
          key: const ValueKey('b2'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.tagline, textAlign: TextAlign.center, style: tUi(15, color: const Color(0xD9FFFFFF))),
            const SizedBox(height: 12),
            NBtn(
              label: "Read ${s.nick}'s Pocket Book",
              icon: Icons.menu_book_rounded,
              expand: true,
              onTap: () {
                Navigator.of(context).pop();
                Nav.push('book', {'bookId': s.id, 'lessonId': s.id});
              },
            ),
            const SizedBox(height: 8),
            NBtn(label: 'Add to Cloudex', kind: Btn.glass, expand: true, fontSize: 15, onTap: _close),
          ],
        );
      } else {
        actions = const SizedBox.shrink(key: ValueKey('b0'));
      }

      content = Stack(
        children: [
          if (revealed && s != null) Positioned.fill(child: IgnorePointer(child: _Rays(color: s.t.color))),
          Positioned(
            top: top + 76,
            left: 16,
            right: 16,
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: title),
          ),
          Align(
            alignment: const Alignment(0, 0.06),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 276,
                height: 386,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: cardUp ? [packWidget, Positioned.fill(child: cardWidget)] : [Positioned.fill(child: cardWidget), packWidget],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: bottom + 18,
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: actions),
          ),
        ],
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.24),
            radius: 1.1,
            colors: [Color(0xFF4B52A8), Color(0xFF262B6E), Color(0xFF14173F)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: StarField(count: 26, seed: 9)),
            Positioned.fill(child: content),
            Positioned(
              left: 16,
              top: top + 6,
              child: Press(
                label: 'Close',
                onTap: _close,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.close_rounded, size: 22, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlyAway extends StatelessWidget {
  const _FlyAway({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: kEase,
        builder: (c, t, ch) => Opacity(
          opacity: (1 - t).clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(
            offset: Offset(180 * t, -140 * t),
            child: Transform.rotate(angle: 38 * t * math.pi / 180, child: ch),
          ),
        ),
        child: child,
      );
}

class _SwipeHint extends StatefulWidget {
  const _SwipeHint();
  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
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
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (c, child) => Transform.translate(offset: Offset(150 * (0.5 - 0.5 * math.cos(_c.value * 2 * math.pi)), 0), child: child),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RotatedBox(quarterTurns: 1, child: Icon(Icons.pan_tool_rounded, size: 22, color: Colors.white)),
            const SizedBox(width: 4),
            Text('swipe', style: tUi(14, weight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      );
}

/// Slowly turning light rays behind a revealed card.
class _Rays extends StatefulWidget {
  const _Rays({required this.color});
  final Color color;
  @override
  State<_Rays> createState() => _RaysState();
}

class _RaysState extends State<_Rays> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 40));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
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
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: kEase,
        builder: (c, v, child) => Opacity(opacity: v, child: Transform.scale(scale: 0.6 + 0.4 * v, child: child)),
        child: CustomPaint(painter: _RaysPainter(_c, widget.color)),
      );
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.anim, this.color) : super(repaint: anim);
  final Animation<double> anim;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.38);
    const r = 540.0;
    final shader = RadialGradient(
      colors: [color.withValues(alpha: 0.34), color.withValues(alpha: 0.34), color.withValues(alpha: 0.0)],
      stops: const [0.0, 0.15, 0.6],
    ).createShader(Rect.fromCircle(center: c, radius: r));
    final p = Paint()..shader = shader;
    final base = anim.value * math.pi * 2;
    const step = 24 * math.pi / 180;
    const sweep = 9 * math.pi / 180;
    for (var k = 0; k < 15; k++) {
      final a = base + k * step;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r)
        ..lineTo(c.dx + math.cos(a + sweep) * r, c.dy + math.sin(a + sweep) * r)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter o) => o.color != color;
}
