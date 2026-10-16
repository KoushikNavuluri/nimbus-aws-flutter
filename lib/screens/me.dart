import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/art.dart';
import '../data/quiz.dart';
import '../data/services.dart';
import '../nav.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/kit.dart';
import 'onboarding.dart' show kGoals, kMinutes;

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});
  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  late final TextEditingController _name = TextEditingController(text: readStore(context).state.profile.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _copy(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    Toasts.show('$what copied', body: 'Paste it anywhere you like.', icon: Icons.content_copy_rounded, bg: C.mintDark);
  }

  String _sheet(AppState s) {
    final b = StringBuffer('# My Nimbus study sheet\n\n');
    for (final x in kServices) {
      if (!s.collected.containsKey(x.id)) continue;
      b.writeln('## ${x.nick} · ${x.name}');
      b.writeln('- ${x.tagline}');
      b.writeln('- ${x.analogy}');
      b.writeln('- Exam whisper: ${x.examTip}');
      b.writeln('- Price: ${x.price}\n');
    }
    return b.toString();
  }

  Widget _section(String title, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: NCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Eyebrow(title), const SizedBox(height: 10), child])),
      );

  @override
  Widget build(BuildContext context) {
    final store = watch(context);
    final s = store.state;
    final lv = levelFor(s.xp);
    final acc = s.stats.answered > 0 ? (s.stats.correct * 100 / s.stats.answered).round() : 0;
    final ready = readiness(s);
    final today = dayKey();
    return NScreen(
      child: Column(children: [
        const TopBar(title: 'You'),
        Expanded(
          child: ListView(padding: EdgeInsets.fromLTRB(16, 0, 16, Insets.bottomOf(context) + 24), children: [
            NCard(
              child: Row(children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.flamingo, shape: BoxShape.circle, border: Border.all(color: C.ink, width: 2.5)),
                  child: Text(s.displayName.isEmpty ? 'K' : s.displayName.substring(0, 1).toUpperCase(), style: tDisplay(28, weight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.displayName, style: tDisplay(24)),
                    Text('Level ${lv.cur.n} · ${lv.cur.name}', style: tUi(14, weight: FontWeight.w700, color: C.ink3)),
                    const SizedBox(height: 6),
                    PBar(pct: lv.pct, h: 8, color: C.butter),
                    const SizedBox(height: 4),
                    Text(lv.next != null ? '${fmtIN(s.xp)} / ${fmtIN(lv.next!.at)} XP to ${lv.next!.name}' : '${fmtIN(s.xp)} XP · max level', style: tUi(12, weight: FontWeight.w600, color: C.ink3)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              for (final st in [('${s.streak}', 'day streak'), ('${s.collected.length}/${kServices.length}', 'Cloudlings'), ('$acc%', 'accuracy')]) ...[
                Expanded(
                  child: NCard(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    child: Column(children: [Text(st.$1, style: tDisplay(22, weight: FontWeight.w700)), Text(st.$2, style: tUi(12, weight: FontWeight.w700, color: C.ink3))]),
                  ),
                ),
                if (st.$2 != 'accuracy') const SizedBox(width: 8),
              ],
            ]),
            const SizedBox(height: 12),
            _section(
              'Last 10 weeks',
              Wrap(spacing: 4, runSpacing: 4, children: [
                for (var i = 69; i >= 0; i--)
                  Builder(builder: (c) {
                    final v = s.activity[addDays(today, -i)] ?? 0;
                    final a = v == 0 ? 0.0 : (0.25 + (v / 90).clamp(0.0, 0.75)).toDouble();
                    return Container(width: 18, height: 18, decoration: BoxDecoration(color: v == 0 ? C.track : C.flamingo.withValues(alpha: a), borderRadius: BorderRadius.circular(5)));
                  }),
              ]),
            ),
            _section(
              'Exam readiness (estimate)',
              Column(children: [
                for (final e in kDomains.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text(e.value.$1, style: tUi(14, weight: FontWeight.w600))), Text('${ready[e.key] ?? 0}%', style: tUi(14, weight: FontWeight.w700))]),
                      const SizedBox(height: 4),
                      PBar(pct: (ready[e.key] ?? 0) / 100, h: 8, color: C.mint),
                    ]),
                  ),
              ]),
            ),
            _section(
              'Profile',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: _name,
                  maxLength: 24,
                  style: tUi(16, weight: FontWeight.w600),
                  onSubmitted: (v) => store.setProfile(name: v.trim().isEmpty ? 'Friend' : v.trim()),
                  onTapOutside: (_) {
                    FocusScope.of(context).unfocus();
                    final v = _name.text.trim();
                    if (v.isNotEmpty && v != s.profile.name) store.setProfile(name: v);
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'Name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Goal', style: tUi(13, weight: FontWeight.w700, color: C.ink3)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final g in kGoals) NChip(label: g.$2, on: s.profile.goal == g.$1, height: 34, fontSize: 13, onTap: () => store.setProfile(goal: g.$1))]),
                const SizedBox(height: 12),
                Text('Daily goal', style: tUi(13, weight: FontWeight.w700, color: C.ink3)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final m in kMinutes) NChip(label: '${m.$1} min · ${m.$2}', on: s.profile.minutes == m.$1, height: 34, fontSize: 13, onTap: () => store.setProfile(minutes: m.$1))]),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: Text('Sounds and haptics', style: tUi(15, weight: FontWeight.w600))), NSwitch(value: s.profile.sound, label: 'Sounds', onChanged: (v) => store.setProfile(sound: v))]),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: Text('Reduce motion', style: tUi(15, weight: FontWeight.w600))), NSwitch(value: s.profile.reducedMotion, label: 'Reduce motion', onChanged: (v) => store.setProfile(reducedMotion: v))]),
              ]),
            ),
            _section(
              'Stamps',
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final e in kStamps.entries)
                  Container(
                    width: 96,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: s.stamps.containsKey(e.key) ? C.butterSoft : C.track,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: s.stamps.containsKey(e.key) ? C.butter : C.line, width: 2),
                    ),
                    child: Column(children: [
                      Icon(s.stamps.containsKey(e.key) ? Icons.verified_rounded : Icons.lock_outline_rounded, size: 22, color: s.stamps.containsKey(e.key) ? C.butterInk : C.ink3),
                      const SizedBox(height: 4),
                      Text(e.value.$1, textAlign: TextAlign.center, style: tUi(12, weight: FontWeight.w700, height: 1.2)),
                      Text(e.value.$2, textAlign: TextAlign.center, maxLines: 2, style: tUi(12, color: C.ink3, height: 1.2)),
                    ]),
                  ),
              ]),
            ),
            _section(
              "Puff's memory",
              s.memory.isEmpty
                  ? Text('Nothing yet. Tell Puff "call me..." or "remember my exam is on Dec 12".', style: tUi(14, color: C.ink2, height: 1.4))
                  : Column(children: [
                      for (final m in s.memory)
                        Row(children: [
                          Expanded(child: Text(m.text, style: tUi(14, weight: FontWeight.w600))),
                          Press(label: 'Forget ${m.text}', onTap: () => store.forget(m.id), child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.close_rounded, size: 18, color: C.ink3))),
                        ]),
                      const SizedBox(height: 6),
                      NBtn(label: 'Forget everything', kind: Btn.soft, height: 40, fontSize: 14, onTap: store.forgetAll),
                    ]),
            ),
            _section(
              'Export',
              Column(children: [
                NBtn(label: 'Copy study sheet (Markdown)', icon: Icons.description_rounded, kind: Btn.soft, expand: true, onTap: () => _copy(_sheet(s), 'Study sheet')),
                const SizedBox(height: 8),
                NBtn(label: 'Copy progress (JSON)', icon: Icons.data_object_rounded, kind: Btn.soft, expand: true, onTap: () => _copy(const JsonEncoder.withIndent('  ').convert(s.toJson()), 'Progress')),
              ]),
            ),
            _section(
              'About',
              Text(
                'Nimbus runs fully offline. Puff is a local, rule-based tutor (no AI model, no internet). Prices are approximate public list prices for learning (₹88 per US dollar). Not affiliated with Amazon Web Services.',
                style: tUi(14, color: C.ink2, height: 1.5),
              ),
            ),
            NBtn(
              label: 'Reset demo',
              icon: Icons.restart_alt_rounded,
              kind: Btn.danger,
              expand: true,
              onTap: () => showNimbusSheet<void>(
                context,
                builder: (c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Start fresh?', style: tDisplay(24)),
                  const SizedBox(height: 6),
                  Text('This wipes your progress on this device and brings back the demo state.', style: tUi(15, color: C.ink2, height: 1.4)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: NBtn(label: 'Keep it', kind: Btn.soft, expand: true, onTap: () => Navigator.of(c).pop())),
                    const SizedBox(width: 8),
                    Expanded(
                      child: NBtn(
                        label: 'Reset',
                        kind: Btn.danger,
                        expand: true,
                        onTap: () {
                          Navigator.of(c).pop();
                          Nav.popAll();
                          Nav.reset();
                          Toasts.clear();
                          store.reset();
                        },
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Puff(size: 70, mood: 'sleepy')),
          ]),
        ),
      ]),
    );
  }
}
