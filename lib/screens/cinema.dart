import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/art.dart';
import '../data/path.dart';
import '../nav.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/kit.dart';
import '../ui/motion.dart';

const Map<String, (String, List<(String, String, List<String>)>)> kFilms = {
  'regions': ('Where the cloud lives', [
    ('A Region is a place', 'Like Hyderabad: ap-south-2. Each Region is its own island of AWS.', ['ec2', 's3']),
    ('Three or more AZs', 'Each Availability Zone is one or more data centers with separate power, cooling and network.', ['ec2', 'rds', 'elb']),
    ('Linked by fast fiber', 'AZs talk over private, low-latency links. Run in two and one can fail.', ['elb', 'ec2']),
    ('Edges near you', '600+ edge locations cache content close to users.', ['cloudfront', 'route53']),
    ('Choosing a Region', 'Pick by latency to users, data laws, which services exist there, and price.', ['iam', 'cloudwatch']),
  ]),
  'request': ('Life of a request', [
    ('You type nimbus.dev', 'Route 53 turns the name into an address.', ['route53']),
    ('Jet checks the edge', 'CloudFront serves cached files from a city near you.', ['cloudfront']),
    ('Juggles picks a server', 'The load balancer sends you to a healthy instance.', ['elb', 'ec2']),
    ('Servo asks Rory', 'The app reads your data from the database.', ['ec2', 'rds']),
    ('Hoot is watching', 'CloudWatch tracks latency and errors the whole way.', ['cloudwatch']),
  ]),
};

class CinemaScreen extends StatefulWidget {
  const CinemaScreen({super.key, required this.id, this.lessonId});
  final String id;
  final String? lessonId;
  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen> with SingleTickerProviderStateMixin {
  late final (String, List<(String, String, List<String>)>) _film = kFilms[widget.id] ?? kFilms['regions']!;
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
  int _i = 0;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _advance();
    });
    _c.forward();
  }

  void _advance() {
    if (!mounted) return;
    if (_i < _film.$2.length - 1) {
      Sfx.play('whoosh');
      setState(() => _i++);
      _c.forward(from: 0);
    } else if (!_ended) {
      _end();
    }
  }

  void _end() {
    final store = readStore(context);
    final first = store.state.cinema[widget.id] != true;
    store.markCinema(widget.id);
    final lid = widget.lessonId ?? (widget.id == 'regions' ? 'gi-1' : 'gi-3');
    final lesson = kLesson[lid];
    if (lesson != null) store.markLesson(lesson.id);
    store.addXP(first ? (lesson?.xp ?? 25) : 5, 2);
    store.stamp('cinephile');
    Sfx.play('win');
    Confetti.fire(y: 0.4);
    setState(() => _ended = true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scenes = _film.$2;
    final sc = scenes[_i];
    return NScreen(
      color: const Color(0xFF14173F),
      child: Stack(children: [
        const Positioned.fill(child: StarField(count: 30, seed: 21)),
        Column(children: [
          TopBar(title: _film.$1, sub: 'Cloud Cinema · 2 min', close: true, dark: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedBuilder(
              animation: _c,
              builder: (c, _) => Row(children: [
                for (var k = 0; k < scenes.length; k++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(99)),
                      child: FractionallySizedBox(
                        widthFactor: k < _i || _ended ? 1.0 : (k == _i ? _c.value : 0.0),
                        child: Container(decoration: BoxDecoration(color: C.butter, borderRadius: BorderRadius.circular(99))),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _ended ? null : _advance,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(
                    height: 170,
                    child: Stack(alignment: Alignment.center, children: [
                      AnimatedBuilder(animation: _c, builder: (c, _) => CustomPaint(size: const Size(300, 20), painter: _PacketPainter(_c.value))),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (var k = 0; k < sc.$3.length; k++)
                          PopIn(key: ValueKey('$_i-$k'), delay: k * 140, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Bob(child: Critter(sc.$3[k], size: sc.$3.length > 2 ? 90 : 120, mood: 'cheer')))),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Rise(key: ValueKey('t$_i'), child: Text(sc.$1, textAlign: TextAlign.center, style: tDisplay(28, color: Colors.white))),
                  const SizedBox(height: 8),
                  Rise(key: ValueKey('b$_i'), index: 2, child: Text(sc.$2, textAlign: TextAlign.center, style: tUi(17, color: const Color(0xD9FFFFFF), height: 1.5))),
                ]),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, Insets.bottomOf(context) + 12),
            child: _ended
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('The end. +XP, and a new stamp.', style: tUi(15, weight: FontWeight.w700, color: C.butter)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: NBtn(
                          label: 'Watch again',
                          kind: Btn.glass,
                          expand: true,
                          onTap: () {
                            setState(() {
                              _i = 0;
                              _ended = false;
                            });
                            _c.forward(from: 0);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: NBtn(label: 'Done', icon: Icons.check_rounded, expand: true, onTap: Nav.pop)),
                    ]),
                  ])
                : Row(children: [
                    NBtn(
                      icon: _c.isAnimating ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      kind: Btn.glass,
                      padH: 14,
                      semantic: 'Play or pause',
                      onTap: () => setState(() => _c.isAnimating ? _c.stop() : _c.forward()),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: NBtn(label: 'Next scene', trailingIcon: Icons.chevron_right_rounded, kind: Btn.white, expand: true, onTap: _advance)),
                  ]),
          ),
        ]),
      ]),
    );
  }
}

class _PacketPainter extends CustomPainter {
  _PacketPainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 3;
    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 6, size.width), y), line);
    }
    canvas.drawCircle(Offset(size.width * t, y), 7, Paint()..color = C.butter);
  }

  @override
  bool shouldRepaint(_PacketPainter o) => o.t != t;
}
