import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/art.dart';
import '../data/lab.dart';
import '../data/services.dart';
import '../nav.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/kit.dart';
import '../ui/motion.dart';
import 'common.dart';

IconData chaosIconFor(String k) {
  if (k == 'zap') return Icons.bolt_rounded;
  if (k == 'power') return Icons.power_off_rounded;
  return Icons.notification_important_rounded;
}

class LabScreen extends StatelessWidget {
  const LabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = watch(context).state;
    const steps = [
      ('1.', 'Tap an empty slot, then pick a Cloudling.'),
      ('2.', 'Send traffic and read the scorecard.'),
      ('3.', 'Unleash chaos. Survive it to pass.'),
    ];
    return ListView(
      padding: EdgeInsets.only(bottom: Insets.bottomOf(context) + 100),
      children: [
        const TabTitle(title: 'Build Lab.', sub: 'Snap Cloudlings together. Then throw chaos at it.'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < kScenarios.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Rise(index: i, child: _ScenarioCard(sc: kScenarios[i], rec: s.lab[kScenarios[i].id])),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0x99FFFFFF), borderRadius: BorderRadius.circular(24), border: Border.all(color: C.line, width: 1.5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('How the Lab works'),
                    const SizedBox(height: 8),
                    for (final st in steps)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: '${st.$1} ', style: tUi(15, weight: FontWeight.w700)),
                            TextSpan(text: st.$2),
                          ]),
                          style: tUi(15, color: C.ink2, height: 1.4),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.sc, required this.rec});
  final Scenario sc;
  final LabRec? rec;

  @override
  Widget build(BuildContext context) {
    final r = rec;
    return NCard(
      onTap: () => Nav.push('labBuild', {'id': sc.id}),
      label: sc.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Eyebrow(sc.tag)),
              Semantics(
                label: 'Difficulty ${sc.level} of 3',
                child: Row(
                  children: [
                    for (var i = 1; i <= 3; i++)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(color: i <= sc.level ? C.flamingo : C.line, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sc.title, style: tDisplay(23)),
                    const SizedBox(height: 2),
                    Text(sc.briefLead, style: tUi(14, color: C.ink2, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (r != null)
                Ring(
                  pct: r.best / 100,
                  size: 58,
                  stroke: 7,
                  color: r.best >= 70 ? C.mint : C.butter,
                  child: Text('${r.best}', style: tDisplay(16, weight: FontWeight.w700).copyWith(fontFeatures: kTabular)),
                )
              else
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.flamingoSoft, borderRadius: BorderRadius.circular(99)),
                  child: Text('NEW', style: tUi(12, weight: FontWeight.w700, color: C.flamingoDeep, spacing: 1.2)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final sl in sc.slots)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: C.sky, borderRadius: BorderRadius.circular(8)),
                  child: Text(sl.label, style: tUi(12, weight: FontWeight.w700, color: C.ink2)),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: C.dangerSoft, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chaosIconFor(sc.chaosIcon), size: 13, color: C.dangerInk),
                    const SizedBox(width: 4),
                    Text(sc.chaos, style: tUi(12, weight: FontWeight.w700, color: C.dangerInk)),
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

class LabBuildScreen extends StatefulWidget {
  const LabBuildScreen({super.key, required this.id});
  final String id;
  @override
  State<LabBuildScreen> createState() => _LabBuildScreenState();
}

class _LabBuildScreenState extends State<LabBuildScreen> {
  late final Scenario sc = scenarioById(widget.id);
  final Map<String, String> _pick = {};
  final Map<String, bool> _opts = {};
  final Map<String, int> _shakes = {};
  final Map<String, GlobalKey> _keys = {};
  final List<Timer> _timers = [];
  final ScrollController _scroll = ScrollController();
  String? _sel;
  (String, String)? _hint;
  String _phase = 'build'; // build | running | result | chaos | final
  int _lit = -1;
  bool _briefOpen = true;
  (int, bool, int)? _fin;

  @override
  void initState() {
    super.initState();
    _sel = sc.slots.first.id;
    for (final s in sc.slots) {
      _keys[s.id] = GlobalKey();
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _later(int ms, VoidCallback fn) {
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (mounted) fn();
    }));
  }

  bool get _filled => sc.slots.every((s) => _pick.containsKey(s.id));
  LabResult? get _res => _filled ? sc.evaluate(_pick, _opts) : null;
  double get _slotScore => _filled ? sc.slots.fold<int>(0, (a, s) => a + (s.accept[_pick[s.id]] ?? 0)) / sc.slots.length : 0.0;

  void _focus(String id) {
    _later(60, () {
      final c = _keys[id]?.currentContext;
      if (c != null) {
        Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 300), curve: kEase, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      }
    });
  }

  void _toBottom(int ms) {
    _later(ms, () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 420), curve: kEase);
    });
  }

  SlotDef? _firstEmpty(Map<String, String> p) {
    for (final s in sc.slots) {
      if (!p.containsKey(s.id)) return s;
    }
    return null;
  }

  void _place(String cardId) {
    if (_phase != 'build') return;
    SlotDef? slot;
    for (final s in sc.slots) {
      if (s.id == _sel) slot = s;
    }
    slot ??= _firstEmpty(_pick);
    final target = slot;
    if (target == null) return;
    final svc = kSvc[cardId]!;
    if (target.accept.containsKey(cardId)) {
      Sfx.play('pop');
      setState(() {
        _pick[target.id] = cardId;
        final note = target.notes[cardId];
        _hint = note != null ? ('warn', note) : ('ok', '${svc.nick} fits: it ${target.need}.');
        final next = _firstEmpty(_pick);
        _sel = next?.id;
        _briefOpen = false;
        _focus(next?.id ?? target.id);
      });
    } else {
      Sfx.play('wrong');
      setState(() {
        _shakes[target.id] = (_shakes[target.id] ?? 0) + 1;
        _hint = ('bad', target.wrong[cardId] ?? '${svc.nick} is a ${svc.t.label.toLowerCase()} Cloudling. This slot needs something that ${target.need}.');
      });
    }
  }

  void _remove(String slotId) {
    if (_phase != 'build') return;
    setState(() {
      _pick.remove(slotId);
      _sel = slotId;
      _hint = null;
    });
  }

  void _run() {
    Sfx.play('whoosh');
    setState(() {
      _phase = 'running';
      _briefOpen = false;
      _hint = null;
    });
    final n = sc.slots.length;
    for (var k = 0; k < n; k++) {
      _later(350 * (k + 1), () => setState(() => _lit = k));
    }
    _later(350 * (n + 1) + 500, () {
      setState(() {
        _phase = 'result';
        _lit = n;
      });
      Sfx.play('correct');
      _toBottom(120);
    });
  }

  void _chaos() {
    Sfx.play('wrong');
    setState(() => _phase = 'chaos');
    _later(1700, () {
      final r = _res;
      if (r == null) return;
      final store = readStore(context);
      final pillars = r.pillars.values.toList();
      final double pillarsAvg = pillars.isEmpty ? 0.0 : pillars.reduce((a, b) => a + b) / pillars.length;
      final int score = math.max(0, math.min(100, (_slotScore * 0.6 + pillarsAvg * 0.4 - (r.survived ? 0 : 25)).round()));
      final pass = score >= 70 && r.survived;
      final prevBest = store.state.lab[sc.id]?.best ?? 0;
      store.saveLab(sc.id, score, r.survived);
      final xp = pass ? (sc.xp * (score / 100)).round() + (score > prevBest && prevBest >= 70 ? 10 : 0) : 10;
      store.addXP(xp, 3);
      if (pass) {
        store.stamp('architect');
        Confetti.fire(y: 0.3, count: 170);
        Sfx.play('win');
        if (sc.id == 'results-day') store.hero('lab');
      }
      if (r.survived) store.stamp('chaos');
      setState(() {
        if (!r.survived) {
          final f = r.failed ?? sc.slots.last.id;
          _shakes[f] = (_shakes[f] ?? 0) + 1;
        }
        _fin = (score, pass, xp);
        _phase = 'final';
      });
      _toBottom(150);
    });
  }

  void _reset() {
    setState(() {
      _pick.clear();
      _opts.clear();
      _sel = sc.slots.first.id;
      _phase = 'build';
      _lit = -1;
      _fin = null;
      _hint = null;
      _briefOpen = true;
    });
    if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 380), curve: kEase);
  }

  @override
  Widget build(BuildContext context) {
    final res = _res;
    final running = _phase == 'running' || _phase == 'chaos';
    final showFail = (_phase == 'chaos' || _phase == 'final') && res != null && !res.survived;
    final failedSlot = showFail ? (res.failed ?? sc.slots.last.id) : null;
    final chaosIcon = chaosIconFor(sc.chaosIcon);

    final body = <Widget>[
      NCard(
        onTap: () => setState(() => _briefOpen = !_briefOpen),
        label: 'Mission brief',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science_rounded, size: 16, color: C.flamingoDeep),
                const SizedBox(width: 6),
                const Eyebrow('Mission', color: C.flamingoDeep),
                const Spacer(),
                Text('+${sc.xp} XP', style: tUi(12, weight: FontWeight.w700, color: C.ink3)),
                const SizedBox(width: 4),
                AnimatedRotation(turns: _briefOpen ? 0.5 : 0.0, duration: const Duration(milliseconds: 250), child: const Icon(Icons.expand_more_rounded, size: 20, color: C.ink3)),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: kEase,
              alignment: Alignment.topCenter,
              child: _briefOpen
                  ? Padding(padding: const EdgeInsets.only(top: 8), child: Text(sc.brief, style: tUi(15, color: C.ink2, height: 1.6)))
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: _Breathe(
          active: running,
          child: Container(
            height: 48,
            padding: const EdgeInsets.only(left: 8, right: 16),
            decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(99)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Color(0x26FFFFFF), shape: BoxShape.circle),
                  child: const Icon(Icons.groups_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sc.source.$1, style: tUi(14, weight: FontWeight.w700, color: Colors.white, height: 1.2)),
                    Text(sc.source.$2, style: tUi(12, color: const Color(0xB3FFFFFF), height: 1.2)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    for (var k = 0; k < sc.slots.length; k++) {
      final slot = sc.slots[k];
      body.add(_Connector(active: running && (_phase == 'chaos' || _lit >= k), bad: failedSlot == slot.id));
      body.add(Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Shake(
            trigger: _shakes[slot.id] ?? 0,
            child: KeyedSubtree(key: _keys[slot.id], child: _slotView(slot, k, failedSlot == slot.id)),
          ),
        ),
      ));
    }

    if ((_phase == 'result' || _phase == 'chaos' || _phase == 'final') && res != null) {
      body.add(const SizedBox(height: 20));
      body.add(Rise(child: _Scorecard(res: res)));
    }
    if ((_phase == 'chaos' || _phase == 'final') && res != null) {
      body.add(const SizedBox(height: 12));
      body.add(PopIn(
        from: 0.96,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _phase == 'chaos' ? C.ink : (res.survived ? C.mintDark : C.dangerDeep),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(chaosIcon, size: 16, color: const Color(0xCCFFFFFF)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(sc.chaos.toUpperCase(), style: tUi(13, weight: FontWeight.w700, color: const Color(0xCCFFFFFF), spacing: 1.5))),
                ],
              ),
              const SizedBox(height: 4),
              Text(_phase == 'chaos' ? 'Unleashing…' : res.chaosText, style: tDisplay(20, color: Colors.white, height: 1.3)),
            ],
          ),
        ),
      ));
    }
    final fin = _fin;
    if (_phase == 'final' && fin != null) {
      body.add(const SizedBox(height: 12));
      body.add(Rise(
        index: 2,
        child: NCard(
          child: Row(
            children: [
              Ring(
                pct: fin.$1 / 100,
                size: 84,
                stroke: 10,
                color: fin.$2 ? C.mint : C.butter,
                child: Num(fin.$1, style: tDisplay(26, weight: FontWeight.w700)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fin.$2 ? 'Architect approved.' : 'Almost. Tweak and retry.', style: tDisplay(22, height: 1.15)),
                    const SizedBox(height: 2),
                    Text(
                      fin.$2 ? 'Passed with ${fin.$1}. +${fin.$3} XP' : 'Pass needs 70 and surviving chaos. +${fin.$3} XP for trying.',
                      style: tUi(14, color: C.ink2, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));
    }

    return NScreen(
      color: const Color(0xFFEEF2FF),
      child: Column(
        children: [
          TopBar(title: sc.title, sub: sc.tag),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: body),
            ),
          ),
          _bottomPanel(chaosIcon),
        ],
      ),
    );
  }

  Widget _slotView(SlotDef slot, int k, bool failed) {
    final card = _pick[slot.id];
    final isSel = _sel == slot.id && _phase == 'build';
    final isLit = _lit >= k && _phase != 'build';
    LabOption? opt;
    for (final o in sc.options) {
      if (o.slot == slot.id) opt = o;
    }
    final Widget main;
    if (card != null) {
      final s = kSvc[card]!;
      final t = s.t;
      final partial = (slot.accept[card] ?? 0) < 100;
      main = AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: failed ? C.danger : (isLit ? t.color : C.ink), width: failed || isLit ? 3 : 2),
          boxShadow: failed
              ? null
              : isLit
                  ? [BoxShadow(color: t.color.withValues(alpha: 0.4), blurRadius: 24)]
                  : const [BoxShadow(color: C.ink, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: t.soft, borderRadius: BorderRadius.circular(16)),
              child: Critter(card, size: 50, shadow: false, mood: failed ? 'sad' : (isLit ? 'cheer' : 'happy')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(slot.label),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${s.nick} ', style: tDisplay(18, height: 1.2)),
                      TextSpan(text: s.name, style: tUi(13, weight: FontWeight.w700, color: C.ink3)),
                    ]),
                  ),
                  if (partial) Text('Works, with trade-offs', style: tUi(12, weight: FontWeight.w700, color: const Color(0xFF8A5A00))),
                ],
              ),
            ),
            if (_phase == 'build')
              Press(
                label: 'Remove ${s.nick}',
                onTap: () => _remove(slot.id),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: C.sky, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 17, color: C.ink),
                ),
              ),
            if (failed) const Icon(Icons.warning_amber_rounded, size: 24, color: C.danger),
          ],
        ),
      );
    } else {
      main = Press(
        label: '${slot.label}: something that ${slot.need}',
        onTap: () => setState(() {
          _sel = slot.id;
          _hint = null;
        }),
        child: CustomPaint(
          painter: DashedBorderPainter(color: isSel ? C.flamingo : const Color(0xFFB7C2E6), radius: 24, dash: 8, gap: 6, width: 2.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isSel ? C.flamingoSoft : const Color(0x80FFFFFF), borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: isSel ? C.flamingo : Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.add_rounded, size: 26, color: isSel ? Colors.white : C.ink3),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow(slot.label),
                      Text('Something that ${slot.need}', style: tUi(14, weight: FontWeight.w600, color: C.ink2, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final o = opt;
    if (o == null || card != o.only) return main;
    final on = _opts[o.id] ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        main,
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 16),
          child: Semantics(
            toggled: on,
            child: Press(
              enabled: _phase == 'build',
              label: o.label,
              onTap: () => setState(() => _opts[o.id] = !on),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                    decoration: BoxDecoration(color: on ? C.mint : C.line, borderRadius: BorderRadius.circular(99)),
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(o.label, style: tUi(14, weight: FontWeight.w700, color: C.ink2))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomPanel(IconData chaosIcon) {
    final children = <Widget>[];
    if (_phase == 'build') {
      final h = _hint;
      final left = sc.slots.where((s) => !_pick.containsKey(s.id)).length;
      String selLabel = '';
      for (final s in sc.slots) {
        if (s.id == _sel) selLabel = s.label;
      }
      final used = _pick.values.toSet();
      children.add(AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: h == null
            ? const SizedBox(width: double.infinity, key: ValueKey('nohint'))
            : Padding(
                key: ValueKey(h.$2),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Puff(size: 40, mood: h.$1 == 'bad' ? 'think' : (h.$1 == 'warn' ? 'soft' : 'cheer'), blink: false),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: h.$1 == 'bad' ? C.dangerSoft : (h.$1 == 'warn' ? C.butterSoft : C.mintSoft),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            h.$2,
                            style: tUi(14,
                                weight: FontWeight.w600,
                                height: 1.35,
                                color: h.$1 == 'bad' ? const Color(0xFF7A161B) : (h.$1 == 'warn' ? const Color(0xFF6B4700) : const Color(0xFF06543D))),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ));
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: Eyebrow(_sel != null ? 'Pick for: $selLabel' : 'All slots filled')),
            const SizedBox(width: 8),
            Flexible(child: Text('Lab lends you every Cloudling', maxLines: 1, overflow: TextOverflow.ellipsis, style: tUi(12, weight: FontWeight.w700, color: C.ink3))),
          ],
        ),
      ));
      children.add(SizedBox(
        height: 126,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: sc.tray.length,
          separatorBuilder: (c, i) => const SizedBox(width: 8),
          itemBuilder: (c, i) {
            final cid = sc.tray[i];
            final s = kSvc[cid]!;
            final isUsed = used.contains(cid);
            return Press(
              enabled: !isUsed && _sel != null,
              sound: null,
              label: 'Place ${s.nick}, ${s.name}',
              onTap: () => _place(cid),
              child: Opacity(
                opacity: isUsed ? 0.35 : 1.0,
                child: Container(
                  width: 78,
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  decoration: BoxDecoration(
                    color: s.t.soft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xD91D2352), width: 2),
                    boxShadow: const [BoxShadow(color: Color(0xD91D2352), offset: Offset(0, 3))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Critter(cid, size: 52, shadow: false),
                      const SizedBox(height: 2),
                      Text(s.nick, style: tUi(12, weight: FontWeight.w700, height: 1.0)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(s.short, maxLines: 1, overflow: TextOverflow.ellipsis, style: tUi(12, weight: FontWeight.w600, color: C.ink3, height: 1.2)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ));
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: NBtn(
          label: _filled ? 'Send traffic' : 'Fill $left more slot${left > 1 ? 's' : ''}',
          icon: Icons.send_rounded,
          expand: true,
          enabled: _filled,
          sound: null,
          onTap: _run,
        ),
      ));
    } else if (_phase == 'running') {
      children.add(const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: NBtn(label: 'Traffic flowing…', kind: Btn.ink, expand: true)));
    } else if (_phase == 'result') {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: NBtn(label: 'Unleash: ${sc.chaos}', icon: chaosIcon, kind: Btn.danger, expand: true, sound: null, onTap: _chaos),
      ));
    } else if (_phase == 'chaos') {
      children.add(const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: NBtn(label: 'Holding on…', kind: Btn.ink, expand: true)));
    } else {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: NBtn(label: 'Rebuild', icon: Icons.restart_alt_rounded, kind: Btn.soft, expand: true, onTap: _reset)),
            const SizedBox(width: 8),
            Expanded(child: NBtn(label: 'Done', icon: Icons.check_rounded, expand: true, onTap: Nav.pop)),
          ],
        ),
      ));
    }
    return Container(
      padding: EdgeInsets.only(top: 12, bottom: Insets.bottomOf(context) + 10),
      decoration: const BoxDecoration(
        color: C.cotton,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x731D2352), offset: Offset(0, -14), blurRadius: 30, spreadRadius: -20)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _Scorecard extends StatelessWidget {
  const _Scorecard({required this.res});
  final LabResult res;

  Color _tone(int v, {int good = 85, int ok = 60}) => v >= good ? C.mint : (v >= ok ? C.butter : C.danger);

  @override
  Widget build(BuildContext context) {
    final usd = res.usd < 10 ? res.usd.toStringAsFixed(2) : '${res.usd.round()}';
    final pillars = res.pillars.entries.toList();
    Widget pillar(MapEntry<String, int> e) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(e.key, style: tUi(13, weight: FontWeight.w700))),
                Text('${e.value}', style: tUi(13, weight: FontWeight.w700).copyWith(fontFeatures: kTabular)),
              ],
            ),
            const SizedBox(height: 4),
            PBar(pct: e.value / 100, h: 7, color: _tone(e.value)),
          ],
        );
    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Scorecard · normal day'),
          const SizedBox(height: 8),
          for (final l in res.latency)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(width: 130, child: Text(l.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: tUi(14, weight: FontWeight.w600))),
                  Expanded(child: PBar(pct: math.min(1.0, l.$2 / 400), h: 8, color: l.$2 < 60 ? C.mint : (l.$2 < 200 ? C.butter : C.danger))),
                  SizedBox(
                    width: 70,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Num(l.$2, style: tUi(14, weight: FontWeight.w700)),
                        Text(' ms', style: tUi(14, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: C.sky, borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MONTHLY BILL (APPROX.)', style: tUi(12, weight: FontWeight.w700, color: C.ink3, spacing: 1.2)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('₹', style: tDisplay(28, weight: FontWeight.w700, height: 1.0)),
                          Num(res.inr.round(), style: tDisplay(28, weight: FontWeight.w700, height: 1.0)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text('\$$usd', style: tUi(14, weight: FontWeight.w700, color: C.ink3).copyWith(fontFeatures: kTabular)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < pillars.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: pillar(pillars[i])),
                  const SizedBox(width: 16),
                  Expanded(child: i + 1 < pillars.length ? pillar(pillars[i + 1]) : const SizedBox.shrink()),
                ],
              ),
            ),
          const SizedBox(height: 8),
          for (final n in res.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(margin: const EdgeInsets.only(top: 7), width: 6, height: 6, decoration: const BoxDecoration(color: C.flamingo, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(n, style: tUi(14, color: C.ink2, height: 1.35))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Connector extends StatefulWidget {
  const _Connector({required this.active, required this.bad});
  final bool active;
  final bool bad;
  @override
  State<_Connector> createState() => _ConnectorState();
}

class _ConnectorState extends State<_Connector> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  void _sync() {
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Connector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.bad ? C.danger : (widget.active ? C.flamingo : const Color(0xFFC3CDEE));
    return SizedBox(
      height: 32,
      child: AnimatedBuilder(
        animation: _c,
        builder: (c, _) => CustomPaint(painter: _WirePainter(color, widget.active ? _c.value : -1)),
      ),
    );
  }
}

class _WirePainter extends CustomPainter {
  _WirePainter(this.color, this.t);
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final p = Paint()
      ..color = color
      ..strokeWidth = 3;
    for (double y = 0; y < size.height; y += 10) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 5, size.height)), p);
    }
    if (t < 0) return;
    for (var k = 0; k < 2; k++) {
      final ph = (t + k * 0.5) % 1.0;
      final y = -6 + 36 * ph;
      final double a = ph < 0.15 ? ph / 0.15 : (ph > 0.85 ? (1 - ph) / 0.15 : 1.0);
      canvas.drawCircle(Offset(x, y), 7, Paint()..color = C.ink.withValues(alpha: a));
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = C.butter.withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_WirePainter o) => o.t != t || o.color != color;
}

class _Breathe extends StatefulWidget {
  const _Breathe({required this.active, required this.child});
  final bool active;
  final Widget child;
  @override
  State<_Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<_Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  void _sync() {
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Breathe oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (c, child) => Transform.scale(scale: 1 + 0.04 * math.sin(_c.value * math.pi), child: child),
        child: widget.child,
      );
}
