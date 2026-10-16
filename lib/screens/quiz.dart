import 'package:flutter/material.dart';

import '../art/art.dart';
import '../data/path.dart';
import '../data/quiz.dart';
import '../data/services.dart';
import '../nav.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/holo_card.dart';
import '../ui/kit.dart';
import 'book.dart' show OptionTile, WhyBox;

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.svc, this.mode, this.lessonId});
  final String? svc;
  final String? mode;
  final String? lessonId;
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> _qs;
  int _i = 0;
  int? _picked;
  int _correct = 0;
  bool _done = false;
  int _xp = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final seed = DateTime.now().millisecondsSinceEpoch;
    final svc = widget.svc;
    final List<Question> qs = widget.mode == 'mock' || svc == null ? List<Question>.of(mockExam(seed)) : List<Question>.of(questionsFor(svc));
    _qs = qs.isEmpty ? List<Question>.of(mockExam(seed, 5)) : qs;
    _i = 0;
    _picked = null;
    _correct = 0;
    _done = false;
  }

  void _pick(int k) {
    if (_picked != null) return;
    final right = k == _qs[_i].a;
    setState(() {
      _picked = k;
      if (right) _correct++;
    });
    Sfx.play(right ? 'correct' : 'wrong');
    if (right) Confetti.fire(y: 0.6, count: 40);
  }

  void _next() {
    if (_i < _qs.length - 1) {
      setState(() {
        _i++;
        _picked = null;
      });
      return;
    }
    final store = readStore(context);
    final total = _qs.length;
    final perfect = _correct == total;
    final svc = widget.svc;
    store.recordQuiz(svc ?? 'mock', _correct, total);
    _xp = _correct * 10 + (perfect ? 20 : 0);
    store.addXP(_xp, total * 0.5);
    if (perfect) {
      store.stamp('perfect');
      store.grantBonusPack();
      if (svc != null) store.collect(svc, 2);
    }
    if (svc == 's3') store.hero('quiz');
    final lid = widget.lessonId;
    if (lid != null && kLesson.containsKey(lid)) store.markLesson(lid);
    if (_correct / total >= 0.6) {
      Sfx.play('win');
      Confetti.fire(y: 0.3, count: 140);
    }
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    final s = svc != null ? kSvc[svc] : null;
    final title = s != null ? '${s.nick} quiz' : 'Mock exam';
    if (_done) return _result(title, s);
    final q = _qs[_i];
    final picked = _picked;
    return NScreen(
      child: Column(children: [
        TopBar(title: title, sub: 'Question ${_i + 1} of ${_qs.length}', close: true),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: PBar(pct: (_i + (picked != null ? 1 : 0)) / _qs.length, h: 8)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Column(
                key: ValueKey(_i),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (q.svc != null) Critter(q.svc!, size: 40, shadow: false) else const Puff(size: 40, blink: false),
                    const SizedBox(width: 8),
                    Expanded(child: Eyebrow(kDomains[q.d]?.$1 ?? 'AWS')),
                  ]),
                  const SizedBox(height: 8),
                  Text(q.q, style: tDisplay(23, height: 1.15)),
                  const SizedBox(height: 16),
                  for (var k = 0; k < q.options.length; k++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OptionTile(
                        text: q.options[k],
                        state: picked == null ? 0 : (k == q.a ? 1 : (k == picked ? 2 : 0)),
                        onTap: picked == null ? () => _pick(k) : null,
                      ),
                    ),
                  if (picked != null) WhyBox(right: picked == q.a, why: q.why),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, Insets.bottomOf(context) + 12),
          child: NBtn(
            label: picked == null ? 'Pick an answer' : (_i < _qs.length - 1 ? 'Next question' : 'See my score'),
            expand: true,
            enabled: picked != null,
            onTap: _next,
          ),
        ),
      ]),
    );
  }

  Widget _result(String title, Service? s) {
    final total = _qs.length;
    final perfect = _correct == total;
    final pct = _correct / total;
    return NScreen(
      child: Column(children: [
        TopBar(title: title, sub: 'Results', close: true),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Puff(size: 120, mood: pct >= 0.6 ? 'cheer' : 'soft'),
              const SizedBox(height: 8),
              Ring(
                pct: pct,
                size: 120,
                stroke: 12,
                color: pct >= 0.6 ? C.mint : C.butter,
                child: Text('$_correct/$total', style: tDisplay(28, weight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              Text(perfect ? 'Flawless!' : (pct >= 0.6 ? 'Nicely done.' : 'Good practice.'), style: tDisplay(28)),
              const SizedBox(height: 4),
              Text('+$_xp XP${perfect ? ' · bonus Sky Pack unlocked' : ''}', textAlign: TextAlign.center, style: tUi(15, weight: FontWeight.w700, color: const Color(0xFFA06A00))),
              if (perfect && s != null) ...[
                const SizedBox(height: 16),
                HoloCard(id: s.id, size: 'sm', level: 2),
                const SizedBox(height: 8),
                Text('${s.nick} went holo!', style: tUi(15, weight: FontWeight.w700)),
              ],
              if (!perfect)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('A perfect score turns the card holo and earns a bonus pack.', textAlign: TextAlign.center, style: tUi(14, color: C.ink2)),
                ),
            ]),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, Insets.bottomOf(context) + 12),
          child: Row(children: [
            Expanded(child: NBtn(label: 'Retry', icon: Icons.restart_alt_rounded, kind: Btn.soft, expand: true, onTap: () => setState(_load))),
            const SizedBox(width: 8),
            Expanded(child: NBtn(label: 'Done', icon: Icons.check_rounded, expand: true, onTap: Nav.pop)),
          ]),
        ),
      ]),
    );
  }
}
