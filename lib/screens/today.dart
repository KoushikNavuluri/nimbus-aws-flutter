import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/art.dart';
import '../data/books.dart';
import '../data/lab.dart';
import '../data/services.dart';
import '../nav.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/holo_card.dart';
import '../ui/kit.dart';
import '../ui/motion.dart';
import '../ui/pack.dart';
import 'common.dart';

const _tips = [
  'Security groups are stateful. NACLs are not. Stateful = remembers the reply.',
  'Multi-AZ is for availability. Read replicas are for speed.',
  '"Who deleted it?" is always CloudTrail.',
  'Data into AWS is free. Data out costs. Mind the direction.',
  "Lambda's limit is 15 minutes. Longer job? Think Fargate.",
  'Bucket names are global. Buckets themselves live in one Region.',
];

class SkyInfo {
  const SkyInfo(this.kind, this.greet, this.colors, this.dark, this.puff, this.say);
  final String kind;
  final String greet;
  final List<int> colors;
  final bool dark;
  final String puff;
  final String say;
}

SkyInfo skyFor([int? hour]) {
  final h = hour ?? DateTime.now().hour;
  if (h >= 20 || h < 5) {
    return SkyInfo('night', h < 5 ? 'Up late' : 'Evening', const [0xFF20255F, 0xFF373D8C, 0xFF5C61B4], true, 'sleepy', 'Late-night session? Short and sweet.');
  }
  if (h < 12) return const SkyInfo('morning', 'Good morning', [0xFFFFD6C6, 0xFFFFE7DE, 0xFFE7EEFF], false, 'happy', 'Fresh brain, fresh cloud.');
  if (h < 17) return const SkyInfo('day', 'Good afternoon', [0xFFB9D3FF, 0xFFD5E4FF, 0xFFE7EEFF], false, 'happy', 'Perfect weather for a lesson.');
  return const SkyInfo('evening', 'Evening', [0xFFFFC2D4, 0xFFEAD6FF, 0xFFE7EEFF], false, 'happy', 'Golden hour. One quick win?');
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watch(context);
    final cards = <Widget>[const _PackCard(), const _GoalCard(), const _UpNext(), const _Duo(), const _LabOfDay(), const _PuffNote()];
    return ListView(
      padding: EdgeInsets.only(bottom: Insets.bottomOf(context) + 20),
      children: [
        const _SkyBand(),
        Transform.translate(
          offset: const Offset(0, -84),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: Rise(index: i, child: cards[i])),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.bg, required this.child});
  final Color bg;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: child,
      );
}

class _SkyBand extends StatelessWidget {
  const _SkyBand();

  @override
  Widget build(BuildContext context) {
    final s = watch(context).state;
    final sky = skyFor();
    final lv = levelFor(s.xp).cur;
    final earned = s.lastActive == dayKey();
    final fg = sky.dark ? Colors.white : C.ink;
    final pillBg = sky.dark ? const Color(0x1FFFFFFF) : const Color(0xB3FFFFFF);
    final pillText = tUi(14, weight: FontWeight.w700, color: fg);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [for (final c in sky.colors) Color(c)],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      padding: EdgeInsets.only(top: Insets.topOf(context) + 8, bottom: 96),
      child: Stack(
        children: [
          if (sky.dark) const Positioned.fill(child: StarField(count: 22, seed: 3)),
          if (sky.dark) const Positioned(right: 34, top: 18, child: Moon(size: 34)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text('${sky.greet},\n${s.displayName}.', style: tDisplay(33, color: fg, height: 1.02))),
                    const SizedBox(width: 12),
                    AvatarButton(dark: sky.dark),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Pill(
                            bg: pillBg,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _Flame(earned: earned, dark: sky.dark),
                                const SizedBox(width: 6),
                                Num(s.streak, style: pillText),
                                Text(' day streak', style: pillText),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _Pill(
                            bg: pillBg,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 16, color: C.butter),
                                const SizedBox(width: 6),
                                Text('${lv.name} · ', style: pillText),
                                Num(s.xp, style: pillText),
                                Text(' XP', style: pillText),
                              ],
                            ),
                          ),
                          if (!earned && s.streak > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Earn any XP to make it ${s.streak + 1}.',
                                  style: tUi(14, weight: FontWeight.w600, color: sky.dark ? const Color(0xCCFFFFFF) : C.ink2)),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(5),
                              ),
                              boxShadow: kSoftShadow,
                            ),
                            child: Text(sky.say, style: tHand(15, height: 1.2)),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -2),
                            child: Bob(child: Puff(size: 96, mood: sky.puff, cap: sky.dark)),
                          ),
                        ],
                      ),
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
}

class _Flame extends StatelessWidget {
  const _Flame({required this.earned, required this.dark});
  final bool earned;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      earned ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
      size: 18,
      color: earned ? C.flamingo : (dark ? const Color(0x99FFFFFF) : C.ink3),
    );
    if (!earned || reduceMotion(context)) return icon;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (c, t, child) => Transform.scale(scale: 1 + 0.35 * math.sin(t * math.pi), child: child),
      child: icon,
    );
  }
}

class _PackCard extends StatefulWidget {
  const _PackCard();
  @override
  State<_PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<_PackCard> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _left() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day + 1);
    final m = math.max(0, (end.difference(now).inSeconds / 60).round());
    return '${m ~/ 60}h ${m % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final s = watch(context).state;
    final today = dayKey();
    final bonus = s.pack.opened == today && s.pack.bonus > 0;
    final lastId = s.pack.last;
    final last = lastId != null ? kSvc[lastId] : null;
    if (s.packAvailable) {
      return NCard(
        onTap: () => Nav.overlay('pack'),
        sound: 'pop',
        label: "Open today's Sky Pack",
        clip: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -56,
              top: -56,
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0xFFFFE3EB), Color(0x00FFE3EB)], stops: [0.0, 0.7]),
                ),
              ),
            ),
            Row(
              children: [
                const Wobble(child: PackArt(w: 96)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow(bonus ? 'Bonus pack${s.pack.bonus > 1 ? ' ×${s.pack.bonus}' : ''}' : "Today's Sky Pack", color: C.flamingoDeep),
                      const SizedBox(height: 4),
                      Text('One Cloudling inside.', style: tDisplay(23, height: 1.05)),
                      const SizedBox(height: 4),
                      Text("Who's it gonna be?", style: tUi(15, color: C.ink2)),
                      const SizedBox(height: 12),
                      IgnorePointer(
                        child: NBtn(label: 'Open it', icon: Icons.card_giftcard_rounded, height: 44, fontSize: 15, padH: 16, sound: null, onTap: () {}),
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
    return NCard(
      child: Row(
        children: [
          if (last != null)
            HoloCard(id: last.id, size: 'sm', tilt: false, idle: false, onTap: () {
              Nav.overlay('card', id: last.id);
            })
          else
            const PackArt(w: 96),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Pack opened'),
                const SizedBox(height: 4),
                Text(last != null ? '${last.nick} joined your Cloudex.' : 'See you tomorrow.', style: tDisplay(21, height: 1.08)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 15, color: C.ink3),
                    const SizedBox(width: 6),
                    Flexible(child: Text('Next pack in ${_left()}', style: tUi(14, weight: FontWeight.w600, color: C.ink3))),
                  ],
                ),
                if (last != null && getBook(last.id) != null && !s.done.containsKey(last.id))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: NBtn(
                      label: 'Pocket Book',
                      icon: Icons.menu_book_rounded,
                      kind: Btn.ink,
                      height: 44,
                      fontSize: 15,
                      padH: 14,
                      onTap: () => Nav.push('book', {'bookId': last.id, 'lessonId': last.id}),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context) {
    final s = watch(context).state;
    final goal = math.max(1, s.profile.minutes);
    final m = s.today.minutes;
    final pct = m / goal;
    final xpStyle = tUi(14, weight: FontWeight.w700, color: const Color(0xFFA06A00));
    return NCard(
      child: Row(
        children: [
          Ring(
            pct: pct,
            size: 72,
            stroke: 9,
            color: pct >= 1 ? C.mint : C.flamingo,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Num(m.floor(), style: tDisplay(20, weight: FontWeight.w700, height: 1.0)),
                Text('of $goal', style: tUi(12, weight: FontWeight.w700, color: C.ink3, height: 1.1)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pct >= 1 ? 'Daily goal smashed.' : 'Daily goal', style: tUi(16, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  pct >= 1 ? 'Anything more is bonus sky.' : '${math.max(1, (goal - m).ceil())} min to go. One lesson does it.',
                  style: tUi(14, color: C.ink2, height: 1.3),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('+', style: xpStyle),
                    Num(s.today.xp, style: xpStyle),
                    Text(' XP', style: xpStyle),
                    Text(' today', style: tUi(14, weight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpNext extends StatelessWidget {
  const _UpNext();

  @override
  Widget build(BuildContext context) {
    final s = watch(context).state;
    final cur = currentLesson(s);
    if (cur == null) {
      return NCard(
        child: Row(
          children: [
            const Puff(size: 64, mood: 'cheer'),
            const SizedBox(width: 12),
            Expanded(child: Text('Skyway complete. Time for a mock exam?', style: tDisplay(18, height: 1.2))),
          ],
        ),
      );
    }
    final book = cur.kind == 'book' ? getBook(cur.ref) : null;
    final pos = s.bookPos[cur.ref] ?? 0;
    final pages = book?.pages.length ?? 0;
    return NCard(
      onTap: () => openLesson(cur),
      label: 'Up next: ${cur.title}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Up next on your Skyway'),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: C.sky, borderRadius: BorderRadius.circular(16)),
                child: LessonArt(lesson: cur, size: 58),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cur.title, style: tDisplay(20, height: 1.15)),
                    const SizedBox(height: 2),
                    Text('${cur.mins} min · +${cur.xp} XP${book != null ? ' · $pages pages' : ''}', style: tUi(14, weight: FontWeight.w600, color: C.ink3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: C.flamingo,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: C.flamingoDeep, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.arrow_forward_rounded, size: 21, color: Colors.white),
              ),
            ],
          ),
          if (book != null && pos > 0 && pages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(child: PBar(pct: pos / (pages - 1), h: 8)),
                  const SizedBox(width: 8),
                  Text('p.${pos + 1}/$pages', style: tUi(12, weight: FontWeight.w700, color: C.ink3)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Duo extends StatelessWidget {
  const _Duo();

  @override
  Widget build(BuildContext context) {
    final s = watch(context).state;
    final due = dueCards(s).length;
    final film = s.cinema['request'] != true ? ('request', 'Life of a request') : ('regions', 'Where the cloud lives');
    const tilts = [-8.0, 4.0, 14.0];
    const tints = [Color(0xFFDDF8F0), Color(0xFFECE9FF), Color(0xFFFFE3EB)];
    Widget reel() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < 6; i++) Container(width: 8, height: 6, decoration: BoxDecoration(color: const Color(0x66FFFFFF), borderRadius: BorderRadius.circular(2))),
          ],
        );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: NCard(
              onTap: () => Nav.push('review'),
              label: 'Review flashcards',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 54,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Positioned(
                            left: 4 + i * 9.0,
                            top: 2,
                            child: Transform.rotate(
                              angle: tilts[i] * math.pi / 180,
                              child: Container(
                                width: 40,
                                height: 50,
                                decoration: BoxDecoration(color: tints[i], borderRadius: BorderRadius.circular(10), border: Border.all(color: C.ink, width: 2)),
                              ),
                            ),
                          ),
                        if (due > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              height: 30,
                              constraints: const BoxConstraints(minWidth: 30),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: C.flamingo, borderRadius: BorderRadius.circular(99)),
                              child: Text('$due', style: tDisplay(16, weight: FontWeight.w700, color: Colors.white, height: 1.0)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Review', style: tUi(16, weight: FontWeight.w700)),
                  Text(due > 0 ? '$due card${due > 1 ? 's' : ''} due' : 'All caught up', style: tUi(14, weight: FontWeight.w600, color: C.ink3)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: NCard(
              onTap: () => Nav.push('cinema', {'id': film.$1}),
              label: 'Cloud Cinema',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 54,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: const Color(0xFF20255F), borderRadius: BorderRadius.circular(12)),
                    child: Stack(
                      children: [
                        Positioned(top: 4, left: 0, right: 0, child: reel()),
                        Positioned(bottom: 4, left: 0, right: 0, child: reel()),
                        const Center(child: Icon(Icons.movie_rounded, size: 22, color: C.butter)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Cloud Cinema', style: tUi(16, weight: FontWeight.w700)),
                  Text('${film.$2} · 2 min', maxLines: 1, overflow: TextOverflow.ellipsis, style: tUi(14, weight: FontWeight.w600, color: C.ink3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabOfDay extends StatelessWidget {
  const _LabOfDay();

  @override
  Widget build(BuildContext context) {
    final s = watch(context).state;
    final sc = kScenarios.firstWhere((x) => (s.lab[x.id]?.best ?? 0) < 70, orElse: () => kScenarios.first);
    final best = s.lab[sc.id]?.best;
    return NCard(
      onTap: () => Nav.push('labBuild', {'id': sc.id}),
      label: 'Lab of the day: ${sc.title}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_rounded, size: 16, color: C.flamingoDeep),
              const SizedBox(width: 6),
              const Eyebrow('Lab of the day', color: C.flamingoDeep),
              const Spacer(),
              if (best != null) Text('Best $best', style: tUi(12, weight: FontWeight.w700, color: C.mintDark)),
            ],
          ),
          const SizedBox(height: 4),
          Text(sc.title, style: tDisplay(22)),
          const SizedBox(height: 2),
          Text(sc.briefLead, style: tUi(14, color: C.ink2, height: 1.35)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < sc.slots.length; i++) ...[
                CustomPaint(
                  painter: const DashedBorderPainter(color: Color(0xFFC3CDEE), radius: 16, dash: 5, gap: 4, width: 2),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: C.sky, borderRadius: BorderRadius.circular(16)),
                    child: Text('?', style: tDisplay(18, color: C.ink3)),
                  ),
                ),
                if (i < sc.slots.length - 1) const Expanded(child: SizedBox(height: 3, child: CustomPaint(painter: _DashLine()))),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DashLine extends CustomPainter {
  const _DashLine();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFC3CDEE)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (double x = 6; x < size.width - 4; x += 11) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 5, size.width - 4), y), p);
    }
  }

  @override
  bool shouldRepaint(_DashLine o) => false;
}

class _PuffNote extends StatelessWidget {
  const _PuffNote();

  @override
  Widget build(BuildContext context) {
    final day = DateTime.now().millisecondsSinceEpoch ~/ 86400000;
    return Transform.rotate(
      angle: -1 * math.pi / 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.fromLTRB(16, 16, 96, 16),
            decoration: BoxDecoration(
              color: C.note,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x801D2352), offset: Offset(0, 10), blurRadius: 20, spreadRadius: -14)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow("Puff's note", color: C.butterInk),
                const SizedBox(height: 4),
                Text(_tips[day % _tips.length], style: tHand(19, height: 1.3)),
              ],
            ),
          ),
          Positioned(
            top: -8,
            left: 32,
            child: Transform.rotate(
              angle: -4 * math.pi / 180,
              child: Container(width: 64, height: 20, decoration: BoxDecoration(color: const Color(0xB3FFFFFF), borderRadius: BorderRadius.circular(3))),
            ),
          ),
          const Positioned(right: 8, bottom: 8, child: Puff(size: 78)),
        ],
      ),
    );
  }
}
