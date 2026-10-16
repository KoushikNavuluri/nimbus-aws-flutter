import 'package:flutter/material.dart';

import '../art/art.dart';
import '../data/path.dart';
import '../data/quiz.dart';
import '../data/services.dart';
import '../nav.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/kit.dart';
import 'common.dart';

const _offs = [0.0, 72.0, 104.0, 72.0, 0.0, -72.0, -104.0, -72.0];
const double _row = 118;
const _kinds = {
  'book': ('Pocket Book', Icons.menu_book_rounded),
  'cinema': ('Cloud Cinema', Icons.movie_rounded),
  'quiz': ('Mock exam', Icons.emoji_events_rounded),
};

class PathScreen extends StatefulWidget {
  const PathScreen({super.key});
  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  final GlobalKey _cur = GlobalKey();
  final ScrollController _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _cur.currentContext;
      if (c != null && mounted) Scrollable.ensureVisible(c, alignment: 0.32);
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _openSheet(Lesson l, String st) {
    final idx = lessonIndex(l.id);
    final prev = idx > 0 ? kLessons[idx - 1] : null;
    final kind = _kinds[l.kind] ?? ('Lesson', Icons.menu_book_rounded);
    final mod = islandOf(l);
    final svc = l.svc;
    showNimbusSheet<void>(
      context,
      builder: (c) {
        void go() {
          Navigator.of(c).pop();
          openLesson(l);
        }

        final Widget primary;
        if (st == 'current') {
          primary = NBtn(label: 'Start', icon: Icons.play_arrow_rounded, expand: true, onTap: go);
        } else if (st == 'done') {
          primary = NBtn(label: 'Revisit', kind: Btn.ink, expand: true, onTap: go);
        } else {
          primary = NBtn(label: 'Peek anyway', icon: Icons.visibility_rounded, kind: Btn.soft, expand: true, onTap: go);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.sky, borderRadius: BorderRadius.circular(24)),
                  child: LessonArt(lesson: l, size: 74, locked: st == 'locked'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('${mod.title} · ${kind.$1}'),
                      const SizedBox(height: 2),
                      Text(l.title, style: tDisplay(24, height: 1.1)),
                      const SizedBox(height: 4),
                      Text('${l.mins} min · +${l.xp} XP${st == 'done' ? ' · done' : ''}', style: tUi(14, weight: FontWeight.w600, color: C.ink3)),
                    ],
                  ),
                ),
              ],
            ),
            if (svc != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(kSvc[svc]!.analogy, style: tUi(15, color: C.ink2, height: 1.6))),
            if (st == 'locked' && prev != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Unlocks after '),
                    TextSpan(text: prev.title, style: tUi(15, weight: FontWeight.w700)),
                    const TextSpan(text: ". Peeking is allowed. Puff won't tell."),
                  ]),
                  style: tUi(15, color: C.ink2, height: 1.5),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: primary),
                if (svc != null && questionsFor(svc).isNotEmpty && st != 'locked') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: NBtn(
                      label: 'Quiz',
                      icon: kind == _kinds['quiz'] ? Icons.emoji_events_rounded : Icons.emoji_events_outlined,
                      kind: Btn.soft,
                      expand: true,
                      onTap: () {
                        Navigator.of(c).pop();
                        Nav.push('quiz', {'svc': svc});
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = watch(context).state;
    final cur = currentLesson(s);
    String stateOf(Lesson l) => s.done.containsKey(l.id) ? 'done' : (cur != null && l.id == cur.id ? 'current' : 'locked');
    final doneCount = kLessons.where((l) => s.done.containsKey(l.id)).length;
    final sections = <Widget>[];
    var idx = 0;
    for (final m in kIslands) {
      sections.add(_IslandView(mod: m, start: idx, stateOf: stateOf, onTap: (l) => _openSheet(l, stateOf(l)), curKey: _cur));
      idx += m.lessons.length;
    }
    return Container(
      color: const Color(0xFF1E2260),
      child: SingleChildScrollView(
        controller: _sc,
        padding: EdgeInsets.only(bottom: Insets.bottomOf(context) + 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: C.sky,
              child: TabTitle(
                title: 'The Skyway.',
                sub: '$doneCount of ${kLessons.length} lessons. Dawn to midnight.',
                child: Padding(padding: const EdgeInsets.only(top: 12), child: PBar(pct: doneCount / kLessons.length, h: 10)),
              ),
            ),
            ...sections,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              child: Column(
                children: [
                  const Puff(size: 90, mood: 'sleepy', cap: true),
                  const SizedBox(height: 8),
                  Text('Summit reached?', style: tDisplay(20, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Then book that exam. You're ready.", textAlign: TextAlign.center, style: tUi(14, color: const Color(0xCCFFFFFF))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslandView extends StatelessWidget {
  const _IslandView({required this.mod, required this.start, required this.stateOf, required this.onTap, required this.curKey});
  final Island mod;
  final int start;
  final String Function(Lesson l) stateOf;
  final void Function(Lesson l) onTap;
  final GlobalKey curKey;

  @override
  Widget build(BuildContext context) {
    final n = mod.lessons.length;
    final done = mod.lessons.where((l) => stateOf(l) == 'done').length;
    final h = 140 + n * _row + 20;
    final dark = mod.dark;
    final fg = dark ? Colors.white : C.ink;
    return LayoutBuilder(builder: (context, box) {
      final cx = box.maxWidth / 2;
      final pts = [for (var i = 0; i < n; i++) Offset(cx + _offs[(start + i) % _offs.length], 140 + i * _row + 37)];
      return Container(
        height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(mod.sky[0]), Color(mod.sky[1])]),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (dark) Positioned.fill(child: StarField(count: 14, seed: start + 11)),
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _TrailPainter(pts, dark ? const Color(0x59FFFFFF) : const Color(0x2E1D2352))))),
            Positioned(
              left: 20,
              right: 20,
              top: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: dark ? const Color(0x1AFFFFFF) : const Color(0xB3FFFFFF), borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow('Island · $done/$n', color: dark ? const Color(0xB3FFFFFF) : C.ink3),
                          Text(mod.title, style: tDisplay(22, height: 1.15, color: fg)),
                          Text(mod.sub, style: tUi(14, weight: FontWeight.w600, color: dark ? const Color(0xBFFFFFFF) : C.ink2)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (done == n)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: C.mint, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 22, color: Colors.white),
                      )
                    else
                      SizedBox(
                        width: 64,
                        child: PBar(pct: done / n, h: 8, color: dark ? C.butter : C.flamingo, track: dark ? const Color(0x33FFFFFF) : C.track),
                      ),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < n; i++)
              Positioned(
                top: 140 + i * _row,
                left: pts[i].dx - 80,
                width: 160,
                child: _Node(
                  key: stateOf(mod.lessons[i]) == 'current' ? curKey : null,
                  lesson: mod.lessons[i],
                  st: stateOf(mod.lessons[i]),
                  dark: dark,
                  onTap: () => onTap(mod.lessons[i]),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _Node extends StatelessWidget {
  const _Node({super.key, required this.lesson, required this.st, required this.dark, required this.onTap});
  final Lesson lesson;
  final String st;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final svc = lesson.svc;
    final ring = svc != null ? kSvc[svc]!.t.color : C.grape;
    final locked = st == 'locked';
    final current = st == 'current';
    final done = st == 'done';
    final List<BoxShadow> shadows;
    if (current) {
      shadows = const [BoxShadow(color: C.flamingoDeep, offset: Offset(0, 8)), BoxShadow(color: C.flamingo, spreadRadius: 5)];
    } else if (done) {
      shadows = [const BoxShadow(color: Color(0x2E1D2352), offset: Offset(0, 6)), BoxShadow(color: ring, spreadRadius: 4)];
    } else {
      shadows = const [BoxShadow(color: Color(0xFFCBD3EE), offset: Offset(0, 5)), BoxShadow(color: Color(0xFFCBD3EE), spreadRadius: 3)];
    }
    final fg = dark ? Colors.white : C.ink;
    final label = '${lesson.title}${locked ? ' (locked)' : done ? ' (done)' : ''}';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Press(
              label: label,
              onTap: onTap,
              child: SizedBox(
                width: 74,
                height: 74,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (current) const PulseRing(size: 74),
                    Container(
                      width: 74,
                      height: 74,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: locked ? const Color(0xFFE4E9F8) : Colors.white, shape: BoxShape.circle, boxShadow: shadows),
                      child: LessonArt(lesson: lesson, size: 58, locked: locked, color: locked ? C.ink3 : C.ink),
                    ),
                    if (done)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: C.mint, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                          child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                        ),
                      ),
                    if (locked)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFCBD3EE), width: 2)),
                          child: const Icon(Icons.lock_rounded, size: 14, color: C.ink3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(lesson.title, textAlign: TextAlign.center, maxLines: 2, style: tUi(14, weight: FontWeight.w700, color: fg, height: 1.2)),
            ),
            const SizedBox(height: 2),
            Text('${lesson.mins} min · ${lesson.xp} XP', style: tUi(12, weight: FontWeight.w700, color: fg.withValues(alpha: 0.7))),
          ],
        ),
        if (current)
          const Positioned(
            top: -48,
            left: 0,
            right: 0,
            child: IgnorePointer(child: Center(child: Bob(child: Puff(size: 54, mood: 'cheer')))),
          ),
      ],
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.pts, this.color);
  final List<Offset> pts;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      final p = pts[i - 1];
      final q = pts[i];
      path.cubicTo(p.dx, p.dy + 60, q.dx, q.dy - 60, q.dx, q.dy);
    }
    final dot = Paint()..color = color;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 15) {
        final t = m.getTangentForOffset(d);
        if (t != null) canvas.drawCircle(t.position, 3, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter o) => o.color != color || o.pts.length != pts.length || (o.pts.isNotEmpty && o.pts.first != pts.first);
}
