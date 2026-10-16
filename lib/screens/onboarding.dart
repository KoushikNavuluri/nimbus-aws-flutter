import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/art.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/kit.dart';

const kGoals = [
  ('clf', 'Cloud Practitioner', 'The friendly first badge'),
  ('saa', 'Solutions Architect', 'Associate: design like a pro'),
  ('dva', 'Developer', 'Associate: build and ship'),
  ('curious', 'Just curious', 'No exam, all vibes'),
];

const kMinutes = [
  (5, 'Quick puff', '5 min a day'),
  (10, 'Steady drift', '10 min a day'),
  (20, 'Storm chaser', '20 min a day'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  late String _goal;
  late int _minutes;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    final p = readStore(context).state.profile;
    _goal = p.goal;
    _minutes = p.minutes;
    _name = TextEditingController(text: p.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _finish() {
    Sfx.play('win');
    Confetti.fire(y: 0.4);
    final n = _name.text.trim();
    FocusScope.of(context).unfocus();
    readStore(context).completeOnboarding(goal: _goal, minutes: _minutes, name: n.isEmpty ? 'Friend' : n);
  }

  @override
  Widget build(BuildContext context) {
    final mood = _step == 0 ? 'happy' : (_step == 1 ? 'think' : 'cheer');
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCFE0FF), Color(0xFFE7EEFF), Color(0xFFFFE6EE)],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _Clouds()),
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: Insets.topOf(context)),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            key: ValueKey(mood),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.elasticOut,
                            builder: (c, v, child) => Transform.translate(
                              offset: Offset(0, 10 * (1 - v)),
                              child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
                            ),
                            child: Bob(child: Puff(size: _step == 0 ? 210 : 150, mood: mood)),
                          ),
                          if (_step == 0) const Padding(padding: EdgeInsets.only(top: 8), child: _CritterRow()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: C.cotton,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                  boxShadow: kPopShadow,
                ),
                padding: EdgeInsets.fromLTRB(24, 24, 24, math.max(Insets.bottomOf(context) + 18, kb + 12)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'Step ${_step + 1} of 3',
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: kEase,
                              margin: const EdgeInsets.only(right: 6),
                              width: i == _step ? 32 : 12,
                              height: 6,
                              decoration: BoxDecoration(color: i == _step ? C.flamingo : C.line, borderRadius: BorderRadius.circular(99)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: kEase,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim), child: child),
                      ),
                      layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topLeft, children: [...prev, if (cur != null) cur]),
                      child: KeyedSubtree(key: ValueKey(_step), child: _body()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hi, I'm Puff.", style: tDisplay(32, height: 1.05)),
          const SizedBox(height: 8),
          Text("I'll help you fall for AWS, one tiny cloud creature at a time. Collect them, learn them, build with them.",
              style: tUi(16, color: C.ink2, height: 1.6)),
          const SizedBox(height: 24),
          NBtn(label: 'Hi Puff!', trailingIcon: Icons.arrow_forward_rounded, expand: true, onTap: () => setState(() => _step = 1)),
        ],
      );
    }
    if (_step == 1) {
      Widget tile((String, String, String) g) {
        final on = _goal == g.$1;
        return Press(
          label: g.$2,
          onTap: () => setState(() => _goal = g.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: on ? C.ink : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: on ? C.ink : C.line, width: 1.5),
              boxShadow: [BoxShadow(color: on ? const Color(0xFF0E1236) : C.line, offset: const Offset(0, 4))],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.$2, style: tUi(15, weight: FontWeight.w700, color: on ? Colors.white : C.ink, height: 1.2)),
                      const SizedBox(height: 4),
                      Text(g.$3, style: tUi(13, color: on ? const Color(0xBFFFFFFF) : C.ink3, height: 1.3)),
                    ],
                  ),
                ),
                if (on) const Positioned(top: 0, right: 0, child: Icon(Icons.check_rounded, size: 17, color: C.butter)),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where are we flying?', style: tDisplay(28, height: 1.05)),
          const SizedBox(height: 16),
          for (var r = 0; r < 2; r++)
            Padding(
              padding: EdgeInsets.only(bottom: r == 0 ? 10 : 0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tile(kGoals[r * 2])),
                    const SizedBox(width: 10),
                    Expanded(child: tile(kGoals[r * 2 + 1])),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          NBtn(label: 'Next', trailingIcon: Icons.arrow_forward_rounded, expand: true, onTap: () => setState(() => _step = 2)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How long a sky break?', style: tDisplay(28, height: 1.05)),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 0; i < kMinutes.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Press(
                  label: kMinutes[i].$2,
                  onTap: () => setState(() => _minutes = kMinutes[i].$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      color: _minutes == kMinutes[i].$1 ? C.flamingo : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _minutes == kMinutes[i].$1 ? C.flamingo : C.line, width: 1.5),
                      boxShadow: [BoxShadow(color: _minutes == kMinutes[i].$1 ? C.flamingoDeep : C.line, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Text('${kMinutes[i].$1}',
                            style: tDisplay(22, weight: FontWeight.w700, height: 1.0, color: _minutes == kMinutes[i].$1 ? Colors.white : C.ink).copyWith(fontFeatures: kTabular)),
                        const SizedBox(height: 4),
                        Text(kMinutes[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tUi(12, weight: FontWeight.w700, color: _minutes == kMinutes[i].$1 ? const Color(0xD9FFFFFF) : C.ink3)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        const Eyebrow('What should I call you?'),
        const SizedBox(height: 6),
        TextField(
          controller: _name,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          style: tUi(16, weight: FontWeight.w600),
          onSubmitted: (_) => _finish(),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            hintText: 'Your name',
            hintStyle: tUi(16, color: C.ink3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.line, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0x66FF4D7E), width: 3)),
          ),
        ),
        const SizedBox(height: 20),
        NBtn(label: "Let's fly", expand: true, sound: null, onTap: _finish),
      ],
    );
  }
}

class _CritterRow extends StatelessWidget {
  const _CritterRow();
  static const _ids = ['s3', 'lambda', 'iam', 'sqs', 'cloudwatch'];

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (c, t, _) => SizedBox(
        width: 58 + 46.0 * (_ids.length - 1),
        height: 64,
        child: Stack(
          children: [
            for (var i = 0; i < _ids.length; i++)
              Positioned(
                left: 46.0 * i,
                top: 0,
                child: Builder(builder: (c) {
                  final local = kEase.transform(((t * 1000 - 150 - i * 80) / 420).clamp(0.0, 1.0).toDouble());
                  return Opacity(
                    opacity: local,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - local)),
                      child: Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: C.ink, width: 2.5)),
                        child: Critter(_ids[i], size: 46, shadow: false),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _Clouds extends StatefulWidget {
  const _Clouds();
  @override
  State<_Clouds> createState() => _CloudsState();
}

class _CloudsState extends State<_Clouds> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 120));
  static const _rows = [(0.12, 0.0, 26.0), (0.30, 6.0, 34.0), (0.58, 2.0, 30.0), (0.76, 9.0, 40.0)];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
      _c.value = 0.1;
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
    return IgnorePointer(
      child: LayoutBuilder(builder: (c, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return AnimatedBuilder(
          animation: _c,
          builder: (c, _) {
            final secs = _c.value * 120;
            return Stack(
              children: [
                for (final r in _rows)
                  Positioned(
                    top: h * r.$1,
                    left: -170 + (w + 200) * (((secs + r.$2 * 3) / r.$3) % 1.0),
                    child: const CustomPaint(size: Size(160, 40), painter: _CloudPainter()),
                  ),
              ],
            );
          },
        );
      }),
    );
  }
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final a = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 8, 112, 36), const Radius.circular(18)));
    final b = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(26, -2, 108, 32), const Radius.circular(16)));
    final d = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(56, 14, 100, 24), const Radius.circular(12)));
    final u = Path.combine(PathOperation.union, Path.combine(PathOperation.union, a, b), d);
    canvas.drawPath(u, Paint()..color = const Color(0xCCFFFFFF));
  }

  @override
  bool shouldRepaint(_CloudPainter o) => false;
}
