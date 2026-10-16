import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/art.dart';
import '../data/books.dart';
import '../data/lab.dart';
import '../data/path.dart';
import '../data/quiz.dart';
import '../data/services.dart';
import '../nav.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/kit.dart';
import '../ui/motion.dart';

const _noSwipe = {'widget', 'sort', 'cli', 'pick'};
const _paper = [Color(0xFFFFE3EB), Color(0xFFDDF8F0), Color(0xFFECE9FF), Color(0xFFE1F0FF), Color(0xFFFFF1D9), Color(0xFFEBF8DF)];

Widget _h(String? t) => Text(t ?? '', style: tDisplay(26, height: 1.08));
Widget _p(String? t, [double size = 16]) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(t ?? '', style: tUi(size, color: C.ink2, height: 1.6)));
BoxDecoration _box([Color c = Colors.white]) => BoxDecoration(color: c, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.line, width: 1.5));

class BookScreen extends StatefulWidget {
  const BookScreen({super.key, required this.bookId, this.lessonId});
  final String bookId;
  final String? lessonId;
  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  late final Book? _book = getBook(widget.bookId);
  int _i = 0;
  int _dir = 1;
  final Map<int, int> _answers = {};
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final n = _book?.pages.length ?? 1;
    _i = math.min(readStore(context).state.bookPos[widget.bookId] ?? 0, n - 1);
  }

  Lesson? get _lesson => kLesson[widget.lessonId ?? ''] ?? kLesson[widget.bookId];

  void _goTo(int j) {
    final b = _book;
    if (b == null || j < 0 || j >= b.pages.length) return;
    Sfx.play('flip');
    setState(() {
      _dir = j > _i ? 1 : -1;
      _i = j;
    });
    readStore(context).setBookPos(widget.bookId, j);
  }

  void _finish() {
    if (_finished) return;
    final store = readStore(context);
    final lesson = _lesson;
    final xp = lesson?.xp ?? 30;
    final already = lesson != null && store.state.done.containsKey(lesson.id);
    setState(() => _finished = true);
    Sfx.play('win');
    Confetti.fire(y: 0.35);
    if (lesson != null) store.markLesson(lesson.id);
    final svc = _book?.svc;
    if (svc != null) store.collect(svc, 1);
    if (widget.bookId == 's3') store.hero('book');
    store.addXP(already ? (xp / 4).round() : xp, (lesson?.mins ?? 3).toDouble());
    store.setBookPos(widget.bookId, 0);
    store.stamp('first-flight');
  }

  @override
  Widget build(BuildContext context) {
    final b = _book;
    if (b == null) {
      return NScreen(
        child: Column(children: [
          const TopBar(title: 'Pocket Book', close: true),
          Expanded(child: Center(child: EmptyState(art: const Puff(size: 110, mood: 'think'), title: 'This book wandered off.', body: 'Head back to the Skyway and pick another.'))),
        ]),
      );
    }
    final n = b.pages.length;
    final page = b.pages[_i];
    final svc = b.svc;
    final tone = svc != null ? kSvc[svc]!.t : null;
    final gate = page.t == 'pick' && !_answers.containsKey(_i);
    final isLast = _i == n - 1;
    final xp = _lesson?.xp ?? 30;
    return NScreen(
      color: const Color(0xFFF3F0FF),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 224,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [tone?.soft ?? C.flamingoSoft, const Color(0x00F3F0FF)]),
              ),
            ),
          ),
          Column(
            children: [
              TopBar(title: b.title, sub: 'Page ${_i + 1} of $n', close: true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  for (var k = 0; k < n; k++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: k <= _i ? (tone?.color ?? C.flamingo) : const Color(0x1F1D2352), borderRadius: BorderRadius.circular(99)),
                      ),
                    ),
                ]),
              ),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: _noSwipe.contains(page.t)
                      ? null
                      : (d) {
                          final v = d.primaryVelocity ?? 0;
                          if (v < -250 && !gate && !isLast) _goTo(_i + 1);
                          if (v > 250) _goTo(_i - 1);
                        },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: kEase,
                      layoutBuilder: (cur, prev) => Stack(fit: StackFit.expand, children: [...prev, if (cur != null) cur]),
                      transitionBuilder: (child, anim) => AnimatedBuilder(
                        animation: anim,
                        child: child,
                        builder: (c, ch) => Opacity(
                          opacity: anim.value.clamp(0.0, 1.0).toDouble(),
                          child: Transform(
                            alignment: _dir > 0 ? Alignment.centerLeft : Alignment.centerRight,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0012)
                              ..rotateY((1 - anim.value) * 0.9 * _dir),
                            child: ch,
                          ),
                        ),
                      ),
                      child: Container(
                        key: ValueKey(_i),
                        decoration: const BoxDecoration(
                          color: C.cotton,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                          boxShadow: [BoxShadow(color: Color(0x591D2352), offset: Offset(0, 20), blurRadius: 40, spreadRadius: -20)],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 24, 20, 24),
                            child: _render(page, b, xp),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, Insets.bottomOf(context) + 10),
                color: C.cotton,
                child: _finished
                    ? Row(children: [
                        if (svc != null && questionsFor(svc).length >= 3) ...[
                          Expanded(child: NBtn(label: 'Take the ${kSvc[svc]!.nick} quiz', icon: Icons.emoji_events_rounded, expand: true, onTap: () => Nav.replace('quiz', {'svc': svc}))),
                          const SizedBox(width: 8),
                        ],
                        NBtn(
                          label: svc == null ? 'Back to the Skyway' : null,
                          icon: Icons.route_rounded,
                          kind: svc == null ? Btn.primary : Btn.soft,
                          semantic: 'Back to the Skyway',
                          padH: 16,
                          onTap: () => Nav.tab(readStore(context), 'path'),
                        ),
                      ])
                    : Row(children: [
                        NBtn(icon: Icons.chevron_left_rounded, kind: Btn.soft, padH: 12, semantic: 'Previous page', enabled: _i > 0, sound: null, onTap: () => _goTo(_i - 1)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: isLast
                              ? NBtn(label: 'Finish book', icon: Icons.check_rounded, expand: true, sound: null, onTap: _finish)
                              : NBtn(
                                  label: gate ? 'Answer to continue' : 'Next',
                                  trailingIcon: gate ? null : Icons.chevron_right_rounded,
                                  expand: true,
                                  enabled: !gate,
                                  sound: null,
                                  onTap: () => _goTo(_i + 1),
                                ),
                        ),
                      ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _render(BookPage p, Book b, int xp) {
    final svc = b.svc;
    switch (p.t) {
      case 'cover':
        return _Cover(page: p, color: b.color);
      case 'text':
        return _TextPage(page: p);
      case 'reveal':
        return _Reveal(page: p);
      case 'deal':
        return _Deal(page: p, svc: svc);
      case 'compare':
        return _Compare(page: p);
      case 'sort':
        return _Sort(page: p);
      case 'pick':
        return _Pick(page: p, answer: _answers[_i], onAnswer: (a) => setState(() => _answers[_i] = a));
      case 'power':
        return _Power(page: p);
      case 'note':
        return _Note(page: p, svc: svc);
      case 'cli':
        return _Cli(page: p);
      case 'widget':
        return _WidgetPage(page: p);
      case 'recap':
        return _Recap(page: p, svc: p.svc ?? svc, xp: xp, finished: _finished);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.page, this.color});
  final BookPage page;
  final int? color;
  @override
  Widget build(BuildContext context) {
    final sid = page.svc;
    final s = sid != null ? kSvc[sid] : null;
    final c = s != null ? s.t.color : Color(color ?? 0xFFFF8FB0);
    return Column(children: [
      const SizedBox(height: 12),
      Container(
        width: 230,
        height: 230,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(center: const Alignment(-0.2, -0.3), colors: [Colors.white, c.withValues(alpha: 0.33)], stops: const [0.0, 0.7]),
          border: Border.all(color: c, width: 3),
        ),
        child: Bob(child: s != null ? Critter(s.id, size: 190, mood: 'cheer') : const Puff(size: 190, mood: 'cheer')),
      ),
      const SizedBox(height: 22),
      if (s != null) Eyebrow('${s.t.label} · Pocket Book', color: s.t.ink),
      const SizedBox(height: 4),
      Text(page.title ?? '', textAlign: TextAlign.center, style: tDisplay(34, height: 1.02)),
      const SizedBox(height: 8),
      Text(page.sub ?? '', textAlign: TextAlign.center, style: tUi(17, color: C.ink2, height: 1.4)),
      const SizedBox(height: 20),
      Text('Swipe or tap Next', style: tUi(13, weight: FontWeight.w700, color: C.ink3)),
    ]);
  }
}

class _TextPage extends StatelessWidget {
  const _TextPage({required this.page});
  final BookPage page;
  @override
  Widget build(BuildContext context) {
    final cr = page.critter;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (cr != null) Center(child: Bob(child: Critter(cr, size: 150))),
      _h(page.h),
      _p(page.body, 17),
      if (page.aside != null)
        Transform.rotate(
          angle: -0.017,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: C.note, borderRadius: BorderRadius.circular(24)),
            child: Text(page.aside!, style: tHand(19, height: 1.3)),
          ),
        ),
    ]);
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.page});
  final BookPage page;
  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  final Set<int> _open = {};
  @override
  Widget build(BuildContext context) {
    final items = widget.page.reveal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h(widget.page.h),
      const SizedBox(height: 4),
      Text('Tap to flip · ${_open.length}/${items.length} revealed', style: tUi(14, weight: FontWeight.w700, color: C.ink3)),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (c, box) {
        final w = (box.maxWidth - 10) / 2;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (var i = 0; i < items.length; i++)
            Press(
              sound: 'flip',
              label: _open.contains(i) ? items[i].back : 'Reveal: ${items[i].front}',
              onTap: () => setState(() => _open.contains(i) ? _open.remove(i) : _open.add(i)),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: _open.contains(i) ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 420),
                curve: kEase,
                builder: (c, v, _) {
                  final back = v > 0.5;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(v * math.pi + (back ? math.pi : 0)),
                    child: Container(
                      width: w,
                      height: 118,
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: back ? Colors.white : _paper[i % _paper.length],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: C.ink, width: 2),
                        boxShadow: const [BoxShadow(color: C.ink, offset: Offset(0, 4))],
                      ),
                      child: Text(back ? items[i].back : items[i].front,
                          textAlign: TextAlign.center, style: back ? tUi(14, weight: FontWeight.w600, height: 1.3) : tDisplay(17, height: 1.15)),
                    ),
                  );
                },
              ),
            ),
        ]);
      }),
    ]);
  }
}

class _Deal extends StatefulWidget {
  const _Deal({required this.page, this.svc});
  final BookPage page;
  final String? svc;
  @override
  State<_Deal> createState() => _DealState();
}

class _DealState extends State<_Deal> {
  int _n = 1;
  @override
  Widget build(BuildContext context) {
    final items = widget.page.items;
    final sid = widget.svc;
    final c = sid != null ? kSvc[sid]!.t.color : C.blue;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h(widget.page.h),
      const SizedBox(height: 16),
      for (var i = 0; i < math.min(_n, items.length); i++)
        TweenAnimationBuilder<double>(
          key: ValueKey(i),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: kEase,
          builder: (ctx, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: Transform.rotate(angle: -0.035 * (1 - v), child: child))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _box(),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(margin: const EdgeInsets.only(top: 4), width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: C.ink, width: 2))),
              const SizedBox(width: 12),
              Expanded(child: Text(items[i], style: tUi(15, height: 1.4))),
            ]),
          ),
        ),
      const SizedBox(height: 6),
      if (_n < items.length)
        NBtn(label: 'Deal the next one (${items.length - _n} left)', icon: Icons.auto_awesome_rounded, kind: Btn.soft, expand: true, sound: 'flip', onTap: () => setState(() => _n++))
      else
        Center(child: Text('All four dealt. Nice.', style: tUi(14, weight: FontWeight.w700, color: C.mintDark))),
    ]);
  }
}

class _Compare extends StatelessWidget {
  const _Compare({required this.page});
  final BookPage page;
  @override
  Widget build(BuildContext context) {
    Color inkFor(int tone) => tone == 0xFFFFB547 ? const Color(0xFF8A4B00) : (tone == 0xFF8C7CFF ? const Color(0xFF3B2BA8) : const Color(0xFFC21D4E));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h(page.h),
      const SizedBox(height: 16),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < page.cols.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(page.cols[i].tone), width: 2)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(page.cols[i].title, style: tDisplay(20, weight: FontWeight.w700, color: inkFor(page.cols[i].tone))),
                  const SizedBox(height: 8),
                  for (final pt in page.cols[i].points) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(pt, style: tUi(13, height: 1.35))),
                ]),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }
}

class _Sort extends StatefulWidget {
  const _Sort({required this.page});
  final BookPage page;
  @override
  State<_Sort> createState() => _SortState();
}

class _SortState extends State<_Sort> {
  final Map<int, String> _placed = {};
  final Map<String, int> _shake = {};
  int? _sel;

  void _drop(String bin) {
    final sel = _sel;
    if (sel == null) return;
    final items = widget.page.sortItems;
    if (items[sel].bin == bin) {
      Sfx.play('correct');
      setState(() {
        _placed[sel] = bin;
        _sel = null;
      });
      if (_placed.length == items.length) {
        Confetti.fire(y: 0.5, count: 70);
        Sfx.play('win');
      }
    } else {
      Sfx.play('wrong');
      setState(() => _shake[bin] = (_shake[bin] ?? 0) + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.page.sortItems;
    final left = items.length - _placed.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h(widget.page.h),
      const SizedBox(height: 4),
      Text(left > 0 ? (widget.page.prompt ?? '') : 'All sorted! You get it.', style: tUi(14, weight: FontWeight.w700, color: left > 0 ? C.ink3 : C.mintDark)),
      const SizedBox(height: 12),
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < items.length; i++)
            if (!_placed.containsKey(i)) NChip(label: items[i].label, on: _sel == i, height: 40, onTap: () => setState(() => _sel = _sel == i ? null : i)),
        ]),
      ),
      const SizedBox(height: 16),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var b = 0; b < widget.page.bins.length; b++) ...[
            if (b > 0) const SizedBox(width: 8),
            Expanded(
              child: Shake(
                trigger: _shake[widget.page.bins[b]] ?? 0,
                child: Press(
                  label: 'Drop into ${widget.page.bins[b]}',
                  sound: null,
                  onTap: () => _drop(widget.page.bins[b]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: 170),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _sel != null ? Colors.white : const Color(0x99FFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _sel != null ? C.flamingo : C.line, width: _sel != null ? 2.5 : 2),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(widget.page.bins[b], textAlign: TextAlign.center, style: tDisplay(18, weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      for (var i = 0; i < items.length; i++)
                        if (_placed[i] == widget.page.bins[b])
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(color: C.mintSoft, borderRadius: BorderRadius.circular(12)),
                            child: Text(items[i].label, style: tUi(12, weight: FontWeight.w700, color: const Color(0xFF06654A), height: 1.2)),
                          ),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }
}

class _Pick extends StatelessWidget {
  const _Pick({required this.page, required this.answer, required this.onAnswer});
  final BookPage page;
  final int? answer;
  final ValueChanged<int> onAnswer;
  @override
  Widget build(BuildContext context) {
    final ans = answer;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Eyebrow(page.h ?? 'Quick check'),
      const SizedBox(height: 4),
      Text(page.q ?? '', style: tDisplay(23, height: 1.12)),
      const SizedBox(height: 16),
      for (var i = 0; i < page.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OptionTile(
            text: page.options[i],
            state: ans == null ? 0 : (i == page.a ? 1 : (ans == i ? 2 : 0)),
            onTap: ans != null
                ? null
                : () {
                    onAnswer(i);
                    Sfx.play(i == page.a ? 'correct' : 'wrong');
                    if (i == page.a) Confetti.fire(y: 0.55, count: 50);
                  },
          ),
        ),
      if (ans != null) WhyBox(right: ans == page.a, why: page.why ?? ''),
    ]);
  }
}

/// Answer option: state 0 = neutral, 1 = correct, 2 = wrong pick.
class OptionTile extends StatelessWidget {
  const OptionTile({super.key, required this.text, required this.state, this.onTap});
  final String text;
  final int state;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final bg = state == 1 ? C.mint : (state == 2 ? const Color(0xFFFFE1E2) : Colors.white);
    final fg = state == 1 ? Colors.white : (state == 2 ? C.dangerInk : C.ink);
    return Press(
      onTap: onTap,
      sound: null,
      label: text,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: state == 1 ? C.mint : (state == 2 ? C.danger : C.line), width: state == 0 ? 1.5 : 2),
          boxShadow: [BoxShadow(color: state == 1 ? C.mintDeep : (state == 2 ? Colors.transparent : C.line), offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Expanded(child: Text(text, style: tUi(15, weight: FontWeight.w600, color: fg, height: 1.3))),
          if (state == 1) const Icon(Icons.check_rounded, size: 21, color: Colors.white),
          if (state == 2) const Icon(Icons.close_rounded, size: 21, color: C.dangerInk),
        ]),
      ),
    );
  }
}

class WhyBox extends StatelessWidget {
  const WhyBox({super.key, required this.right, required this.why});
  final bool right;
  final String why;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 320),
        builder: (c, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 8 * (1 - v)), child: child)),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: _box(),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Puff(size: 56, mood: right ? 'cheer' : 'soft', blink: false),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: right ? 'Yes! ' : 'Not quite. ', style: tUi(15, weight: FontWeight.w800, height: 1.4)),
                TextSpan(text: why),
              ]), style: tUi(15, height: 1.4)),
            ),
          ]),
        ),
      );
}

class _Power extends StatelessWidget {
  const _Power({required this.page});
  final BookPage page;
  @override
  Widget build(BuildContext context) {
    final s = kSvc[page.svc ?? 's3']!;
    final t = s.t;
    final rows = [
      ('Speed', s.power.speed, 'How fast it responds'),
      ('Scale', s.power.scale, 'How big it can grow'),
      ('Simplicity', s.power.simplicity, 'How little you manage'),
      ('Thrift', s.power.thrift, 'How kind to your wallet'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h(page.h),
      Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: t.color, width: 2)),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(rows[i].$1, style: tUi(15, weight: FontWeight.w700))),
                  Text(rows[i].$3, style: tUi(12, weight: FontWeight.w700, color: C.ink3)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  for (var j = 1; j <= 5; j++)
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + i * 80 + j * 40),
                        curve: kEase,
                        builder: (c, v, _) => Container(
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(color: C.track, borderRadius: BorderRadius.circular(99)),
                          child: FractionallySizedBox(
                            widthFactor: j <= rows[i].$2 ? v : 0.0,
                            heightFactor: 1,
                            child: Container(decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0x8C1D2352), width: 1.5))),
                          ),
                        ),
                      ),
                    ),
                ]),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final x in s.stats)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: t.soft, borderRadius: BorderRadius.circular(12)),
            child: Text(x, style: tUi(14, weight: FontWeight.w700, color: t.ink)),
          ),
      ]),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: 'Price tag: ', style: tUi(15, weight: FontWeight.w700)),
          TextSpan(text: s.price),
        ]), style: tUi(15, color: C.ink2, height: 1.5)),
      ),
    ]);
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.page, this.svc});
  final BookPage page;
  final String? svc;
  @override
  Widget build(BuildContext context) {
    final sid = svc;
    return Column(children: [
      const SizedBox(height: 20),
      Eyebrow(page.h ?? ''),
      const SizedBox(height: 14),
      Transform.rotate(
        angle: -0.026,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: C.note,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x991D2352), offset: Offset(0, 16), blurRadius: 30, spreadRadius: -18)],
          ),
          child: Text(page.body ?? '', style: tHand(24, height: 1.3)),
        ),
      ),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (sid != null) Critter(sid, size: 110, mood: 'cheer'),
        const SizedBox(width: 8),
        const Puff(size: 110),
      ]),
    ]);
  }
}

class _Cli extends StatefulWidget {
  const _Cli({required this.page});
  final BookPage page;
  @override
  State<_Cli> createState() => _CliState();
}

class _CliState extends State<_Cli> {
  final Set<int> _ran = {};
  final List<(String, List<String>, bool)> _hist = [];
  final TextEditingController _val = TextEditingController();

  @override
  void dispose() {
    _val.dispose();
    super.dispose();
  }

  String _norm(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

  void _run(String raw) {
    final t = _norm(raw);
    if (t.isEmpty) return;
    final lines = widget.page.lines;
    final match = lines.indexWhere((l) => _norm(l.cmd) == t);
    List<String> out;
    var ok = true;
    if (match >= 0) {
      out = lines[match].out;
      _ran.add(match);
    } else if (t == 'clear') {
      setState(() => _hist.clear());
      _val.clear();
      return;
    } else if (t == 'aws --version') {
      out = ['aws-cli/2.x Python/3.x (pocket terminal, simulated)'];
    } else if (t == 'help' || t == 'aws help') {
      out = ["This pocket terminal knows today's commands:", for (final l in lines) '  ${l.cmd}'];
    } else if (!t.startsWith('aws ')) {
      ok = false;
      out = ['${t.split(' ').first}: command not found. AWS commands start with "aws".'];
    } else {
      ok = false;
      out = ["aws: error: this pocket terminal only knows today's lesson commands.", 'Try: help'];
    }
    Sfx.play(ok ? 'correct' : 'wrong');
    setState(() => _hist.add((t, out, ok)));
    _val.clear();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.page.lines;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h(widget.page.h),
      _p(widget.page.body, 15),
      const SizedBox(height: 12),
      for (var i = 0; i < lines.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.line, width: 1.5)),
                child: Text(lines[i].cmd, style: tMono(12, height: 1.4)),
              ),
            ),
            const SizedBox(width: 8),
            Press(
              label: 'Run ${lines[i].cmd}',
              sound: null,
              onTap: () => _run(lines[i].cmd),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: _ran.contains(i) ? C.mint : C.ink, borderRadius: BorderRadius.circular(12)),
                child: Icon(_ran.contains(i) ? Icons.check_rounded : Icons.play_arrow_rounded, size: 20, color: Colors.white),
              ),
            ),
          ]),
        ),
      Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 120, maxHeight: 210),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: C.terminal, borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          reverse: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: 'koushi@nimbus:~\$ ', style: tMono(12, color: const Color(0xFF8E96D6))),
              TextSpan(text: 'ready', style: tMono(12, color: const Color(0x99FFFFFF))),
            ])),
            for (final h in _hist) ...[
              const SizedBox(height: 6),
              Text.rich(TextSpan(children: [
                TextSpan(text: '\$ ', style: tMono(12, color: const Color(0xFF7CF0C5))),
                TextSpan(text: h.$1, style: tMono(12, color: Colors.white)),
              ])),
              for (final o in h.$2) Text(o, style: tMono(12, color: h.$3 ? const Color(0xFFC8D1FF) : const Color(0xFFFFB1B6), height: 1.5)),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: C.terminal, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Text('\$', style: tMono(14, color: const Color(0xFF7CF0C5))),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _val,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: tMono(14, color: Colors.white),
                  cursorColor: const Color(0xFF7CF0C5),
                  onSubmitted: _run,
                  decoration: InputDecoration.collapsed(hintText: 'type a command…', hintStyle: tMono(14, color: const Color(0x66FFFFFF))),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        Press(
          label: 'Run typed command',
          sound: null,
          onTap: () => _run(_val.text),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: C.flamingo, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.keyboard_return_rounded, size: 19, color: Colors.white),
          ),
        ),
      ]),
    ]);
  }
}

class _WidgetPage extends StatelessWidget {
  const _WidgetPage({required this.page});
  final BookPage page;
  @override
  Widget build(BuildContext context) {
    final Widget w;
    if (page.w == 'bucketDrop') {
      w = const _BucketDrop();
    } else if (page.w == 'nines') {
      w = const _Nines();
    } else if (page.w == 'storageClass') {
      w = const _StorageClass();
    } else {
      w = const _PublicAccess();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_h(page.h), _p(page.body, 15), const SizedBox(height: 12), w]);
  }
}

const _files = [
  ('diwali.jpg', '2026/diwali.jpg', '2.4 MB', 'image/jpeg', Icons.image_rounded, Color(0xFFFFE3EB)),
  ('resume.pdf', 'docs/resume.pdf', '180 KB', 'application/pdf', Icons.description_rounded, Color(0xFFE1F0FF)),
  ('lofi-mix.mp3', 'music/lofi-mix.mp3', '6.1 MB', 'audio/mpeg', Icons.music_note_rounded, Color(0xFFECE9FF)),
];

class _BucketDrop extends StatefulWidget {
  const _BucketDrop();
  @override
  State<_BucketDrop> createState() => _BucketDropState();
}

class _BucketDropState extends State<_BucketDrop> {
  final List<int> _in = [];
  int _cheer = 0;
  @override
  Widget build(BuildContext context) {
    final last = _in.isEmpty ? null : _files[_in.last];
    return Column(children: [
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < _files.length; i++)
          if (!_in.contains(i))
            Press(
              label: 'Upload ${_files[i].$1}',
              sound: 'pop',
              onTap: () => setState(() {
                _in.add(i);
                _cheer++;
              }),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: _files[i].$6, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.line, width: 1.5)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_files[i].$5, size: 16, color: C.ink), const SizedBox(width: 6), Text(_files[i].$1, style: tUi(13, weight: FontWeight.w600))]),
              ),
            ),
        if (_in.length == _files.length) Text('All three stored!', style: tUi(14, weight: FontWeight.w700, color: C.mintDark)),
      ]),
      const SizedBox(height: 8),
      TweenAnimationBuilder<double>(
        key: ValueKey(_cheer),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (c, v, child) => Transform.translate(offset: Offset(0, -10 * math.sin(v * math.pi)), child: child),
        child: Critter('s3', size: 150, mood: _cheer > 0 ? 'cheer' : 'happy'),
      ),
      Text('s3://koushi-memories', style: tMono(12, weight: FontWeight.w700, color: C.ink2)),
      const SizedBox(height: 6),
      SizedBox(
        height: 28,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final i in _in)
            PopIn(
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: _files[i].$6, borderRadius: BorderRadius.circular(8), border: Border.all(color: C.ink, width: 1.5)),
                child: Icon(_files[i].$5, size: 14, color: C.ink),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      if (last == null)
        Text('Tap a file above to upload it.', style: tUi(14, weight: FontWeight.w600, color: C.ink3))
      else
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _box(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Eyebrow('Object anatomy · ${_in.length} object${_in.length > 1 ? 's' : ''} stored'),
            const SizedBox(height: 8),
            for (final r in [('Bucket', 'koushi-memories'), ('Key', last.$2), ('Size', last.$3), ('Metadata', 'Content-Type: ${last.$4}'), ('Class', 'S3 Standard')])
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 86, child: Text(r.$1, style: tUi(14, weight: FontWeight.w700, color: C.ink3))),
                  Expanded(child: Text(r.$2, style: r.$1 == 'Key' ? tMono(13, weight: FontWeight.w700, color: C.flamingoDeep) : tMono(13))),
                ]),
              ),
            const SizedBox(height: 6),
            Text('Folders are an illusion: "${last.$2.split('/').first}/" is just a prefix of the key.', style: tUi(13, color: C.ink2, height: 1.35)),
          ]),
        ),
    ]);
  }
}

class _Nines extends StatefulWidget {
  const _Nines();
  @override
  State<_Nines> createState() => _NinesState();
}

class _NinesState extends State<_Nines> {
  static const _steps = [1e3, 1e4, 1e5, 1e6, 1e7, 1e8];
  int _i = 4;
  @override
  Widget build(BuildContext context) {
    final n = _steps[_i];
    final years = 1 / (n * 1e-11);
    final compare = years >= 66e6
        ? 'Longer than since the dinosaurs vanished.'
        : years >= 3e5
            ? 'Longer than humans have existed.'
            : years >= 5000
                ? 'Longer than the pyramids have stood.'
                : 'Still longer than any civilisation so far.';
    const digits = '99.999999999%';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
        child: Semantics(
          label: '99.999999999 percent',
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var k = 0; k < digits.length; k++)
              Rise(index: k, step: 40, child: Text(digits[k], style: tDisplay(30, weight: FontWeight.w700, color: digits[k] == '9' ? const Color(0xFF00866A) : C.ink))),
          ]),
        ),
      ),
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('If you store', style: tUi(14, weight: FontWeight.w700, color: C.ink3)),
          Text('${fmtIN(n)} objects', style: tDisplay(28, weight: FontWeight.w700, height: 1.2)),
          NSlider(value: _i.toDouble(), min: 0, max: 5, divisions: 5, label: 'Number of objects', onChanged: (v) => setState(() => _i = v.round())),
          Text("you'd expect to lose one about every", style: tUi(14, weight: FontWeight.w700, color: C.ink3)),
          Text('${fmtIN(years)} years', style: tDisplay(28, weight: FontWeight.w700, color: C.flamingoDeep, height: 1.2)),
          const SizedBox(height: 4),
          Text(compare, style: tUi(14, color: C.ink2)),
        ]),
      ),
      const SizedBox(height: 12),
      Text('S3 quietly copies every object across at least three Availability Zones. Durability means "won\'t lose it". Availability means "can reach it right now".',
          style: tUi(13, color: C.ink3, height: 1.4)),
    ]);
  }
}

class _StorageClass extends StatefulWidget {
  const _StorageClass();
  @override
  State<_StorageClass> createState() => _StorageClassState();
}

class _StorageClassState extends State<_StorageClass> {
  static const _freq = ['Every day', 'Every week', 'Every month', 'Every few months', 'Almost never'];
  static const _rec = ['std', 'std', 'ia', 'gir', 'gda'];
  static const _gbs = [50, 200, 1000, 5000];
  int _f = 3;
  int _gb = 200;
  @override
  Widget build(BuildContext context) {
    final rec = _rec[_f];
    double priceOf(S3Class c) => c.id == 'it' ? (_f <= 1 ? 0.023 : (_f == 2 ? 0.0125 : 0.004)) : c.price;
    final maxUsd = kS3Classes.map((c) => priceOf(c) * _gb).fold<double>(0.0001, math.max);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("I'll open these files", style: tUi(14, weight: FontWeight.w700, color: C.ink3)),
          Text(_freq[_f], style: tDisplay(22, weight: FontWeight.w700)),
          NSlider(value: _f.toDouble(), min: 0, max: 4, divisions: 4, label: 'How often you open the files', onChanged: (v) => setState(() => _f = v.round())),
          Row(children: [
            for (var k = 0; k < _gbs.length; k++) ...[
              if (k > 0) const SizedBox(width: 6),
              Expanded(child: NChip(label: _gbs[k] >= 1000 ? '${_gbs[k] ~/ 1000} TB' : '${_gbs[k]} GB', on: _gb == _gbs[k], expand: true, fontSize: 13, onTap: () => setState(() => _gb = _gbs[k]))),
            ],
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      for (final c in kS3Classes)
        Builder(builder: (ctx) {
          final usd = priceOf(c) * _gb;
          final on = c.id == rec;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: on ? C.ink : const Color(0xB3FFFFFF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: on ? const [BoxShadow(color: Color(0xFF0E1236), offset: Offset(0, 4))] : null,
            ),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: Row(children: [
                    Flexible(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tUi(14, weight: FontWeight.w700, color: on ? Colors.white : C.ink))),
                    if (on)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: C.butter, borderRadius: BorderRadius.circular(99)),
                        child: Text("Bucky's pick", style: tUi(12, weight: FontWeight.w700)),
                      ),
                  ]),
                ),
                Text('₹${fmtIN(usd * kInr)}', style: tUi(14, weight: FontWeight.w700, color: on ? Colors.white : C.ink).copyWith(fontFeatures: kTabular)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: PBar(pct: math.max(0.02, usd / maxUsd), h: 6, color: on ? C.butter : const Color(0xFF2FCCAA), track: on ? const Color(0x33FFFFFF) : C.track)),
                SizedBox(width: 112, child: Text(c.access, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: tUi(12, weight: FontWeight.w600, color: on ? const Color(0xBFFFFFFF) : C.ink3))),
              ]),
            ]),
          );
        }),
      Text('Monthly storage at approx. list prices (₹${kInr.round()}/\$). Colder classes add retrieval fees and minimum storage days. Unsure? Intelligent-Tiering moves files for you.',
          style: tUi(12, color: C.ink3, height: 1.4)),
    ]);
  }
}

class _PublicAccess extends StatefulWidget {
  const _PublicAccess();
  @override
  State<_PublicAccess> createState() => _PublicAccessState();
}

class _PublicAccessState extends State<_PublicAccess> {
  bool _block = true;
  int _sent = 0;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Column(children: [
          Row(children: [
            Icon(_block ? Icons.verified_user_rounded : Icons.gpp_bad_rounded, size: 26, color: _block ? C.mint : C.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Block Public Access', style: tUi(15, weight: FontWeight.w700)),
                Text(_block ? 'On (the default for new buckets)' : 'Off: policies could expose objects', style: tUi(13, color: C.ink3)),
              ]),
            ),
            NSwitch(value: _block, onColor: C.mint, label: 'Block Public Access', onChanged: (v) => setState(() {
                  _block = v;
                  _sent = 0;
                })),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.lock_rounded, size: 24, color: C.ink2),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Default encryption (SSE-S3)', style: tUi(15, weight: FontWeight.w700)),
                Text('Always on for new objects', style: tUi(13, color: C.ink3)),
              ]),
            ),
            Opacity(opacity: 0.6, child: IgnorePointer(child: NSwitch(value: true, onChanged: (_) {}))),
          ]),
        ]),
      ),
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.terminal, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('GET https://koushi-memories.s3.ap-south-2.amazonaws.com/2026/diwali.jpg', style: tMono(12, color: const Color(0xFFC8D1FF), height: 1.4)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: LayoutBuilder(builder: (c, box) {
                  final w = box.maxWidth;
                  return Stack(children: [
                    Positioned(left: 48, right: 48, top: 19, child: Container(height: 2, color: const Color(0x40FFFFFF))),
                    Positioned(
                      left: 0,
                      child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(12)), child: Text('You?', style: tUi(12, weight: FontWeight.w700, color: Colors.white))),
                    ),
                    if (_sent > 0)
                      TweenAnimationBuilder<double>(
                        key: ValueKey(_sent),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 700),
                        curve: kEase,
                        builder: (c, v, _) => Positioned(left: 44 + (w - 100) * v, top: 14, child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: C.butter, shape: BoxShape.circle))),
                      ),
                    Positioned(right: 0, child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Critter('s3', size: 34, shadow: false))),
                  ]);
                }),
              ),
            ),
            const SizedBox(width: 12),
            NBtn(label: 'Send', icon: Icons.send_rounded, height: 40, fontSize: 14, padH: 12, sound: 'whoosh', onTap: () => setState(() => _sent++)),
          ]),
          if (_sent > 0)
            Rise(
              key: ValueKey('r$_sent$_block'),
              index: 13,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: _block ? C.mintDark : const Color(0xFFFFB1B6), borderRadius: BorderRadius.circular(12)),
                child: Text(_block ? '403 Access Denied · your file is safe' : '200 OK · a stranger downloaded it',
                    style: tMono(13, weight: FontWeight.w700, color: _block ? Colors.white : const Color(0xFF5E0B10))),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      Text('Want a public website? Keep the bucket private and put CloudFront with Origin Access Control in front.', style: tUi(13, color: C.ink2, height: 1.4)),
    ]);
  }
}

class _Recap extends StatelessWidget {
  const _Recap({required this.page, required this.svc, required this.xp, required this.finished});
  final BookPage page;
  final String? svc;
  final int xp;
  final bool finished;
  @override
  Widget build(BuildContext context) {
    final sid = svc;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Bob(child: sid != null ? Critter(sid, size: 140, mood: 'cheer') : const Puff(size: 140, mood: 'cheer'))),
      _h(finished ? 'Book complete!' : 'The three things to keep'),
      const SizedBox(height: 12),
      for (final p in page.points)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: _box(),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 24, height: 24, decoration: const BoxDecoration(color: C.mint, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 15, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Text(p, style: tUi(15, weight: FontWeight.w600, height: 1.35))),
          ]),
        ),
      const SizedBox(height: 8),
      Center(child: Text(finished ? '+$xp XP earned' : 'Finish for +$xp XP', style: tUi(14, weight: FontWeight.w700, color: const Color(0xFF8A5A00)))),
    ]);
  }
}
