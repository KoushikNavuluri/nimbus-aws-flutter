import 'dart:async';

import 'package:flutter/material.dart';

import '../ai.dart';
import '../art/art.dart';
import '../data/path.dart';
import '../data/quiz.dart';
import '../data/services.dart';
import '../nav.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/kit.dart';
import 'book.dart' show OptionTile;
import 'common.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.prefill});
  final String? prefill;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _input = TextEditingController(text: widget.prefill ?? '');
  final ScrollController _scroll = ScrollController();
  final List<Timer> _timers = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = readStore(context);
      for (final m in List<ChatMsg>.of(store.state.chat)) {
        if (m.status != 'done') store.patchChat(m.id, (x) => x.status = 'done');
      }
      _toBottom();
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: kEase);
    });
  }

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    final store = readStore(context);
    if (text == 'Open the Build Lab') {
      Nav.tab(store, 'lab');
      return;
    }
    Sfx.play('pop');
    _input.clear();
    final now = DateTime.now().millisecondsSinceEpoch;
    store.pushChat(ChatMsg(id: 'u$now', role: 'user', at: now, text: text));
    final r = respond(text, store.state);
    final mem = r.memory;
    if (mem != null) store.remember(mem['kind'] ?? 'note', mem['value'] ?? '', mem['text'] ?? '');
    final act = r.action;
    if (act != null) {
      if (act['type'] == 'forgetAll') store.forgetAll();
      if (act['type'] == 'minutes') store.setProfile(minutes: (act['value'] as num?)?.toInt() ?? 5);
    }
    final pid = 'p$now';
    store.pushChat(ChatMsg(
      id: pid,
      role: 'puff',
      at: now,
      text: r.text,
      status: 'thinking',
      steps: List<String>.of(r.steps),
      blocks: [for (final b in r.blocks) Map<String, dynamic>.of(b)],
      chips: List<String>.of(r.chips),
      mood: r.mood,
      intent: r.intent,
    ));
    store.hero('ask');
    store.stamp('curious');
    setState(() => _busy = true);
    _toBottom();
    final n = r.steps.length;
    for (var k = 1; k < n; k++) {
      _timers.add(Timer(Duration(milliseconds: 650 * k), () {
        if (mounted) store.patchChat(pid, (m) => m.stepAt = k);
      }));
    }
    _timers.add(Timer(Duration(milliseconds: 650 * n + 300), () {
      if (!mounted) return;
      store.patchChat(pid, (m) => m.status = 'done');
      Sfx.play('sparkle');
      setState(() => _busy = false);
      _toBottom();
    }));
  }

  @override
  Widget build(BuildContext context) {
    final store = watch(context);
    final msgs = store.state.chat;
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final lastPuff = msgs.lastIndexWhere((m) => m.role == 'puff');
    return NScreen(
      child: Column(children: [
        TopBar(
          title: 'Ask Puff',
          sub: 'Local tutor · no internet needed',
          close: true,
          right: msgs.isEmpty
              ? null
              : Press(label: 'Clear chat', onTap: store.clearChat, child: const Icon(Icons.delete_sweep_rounded, size: 24, color: C.ink3)),
        ),
        Expanded(
          child: msgs.isEmpty
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    const Bob(child: Puff(size: 140, mood: 'happy')),
                    const SizedBox(height: 12),
                    Text('Ask me anything AWS.', style: tDisplay(26)),
                    const SizedBox(height: 6),
                    Text('Services, prices, comparisons, quizzes, or what to study next. I run right here on your phone.',
                        textAlign: TextAlign.center, style: tUi(15, color: C.ink2, height: 1.5)),
                    const SizedBox(height: 20),
                    Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [for (final s in kStarters) NChip(label: s, onTap: () => _send(s))]),
                  ]),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: msgs.length,
                  itemBuilder: (c, i) => _Bubble(msg: msgs[i], showChips: i == lastPuff && !_busy, onChip: _send, store: store),
                ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, (kb > 0 ? kb : Insets.bottomOf(context)) + 10),
          decoration: const BoxDecoration(color: C.cotton, boxShadow: [BoxShadow(color: Color(0x401D2352), offset: Offset(0, -8), blurRadius: 24, spreadRadius: -16)]),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: C.line, width: 1.5)),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _input,
                  style: tUi(16),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration.collapsed(hintText: 'Ask Puff…', hintStyle: tUi(16, color: C.ink3)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Press(
              label: 'Send',
              sound: null,
              enabled: !_busy,
              onTap: () => _send(_input.text),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: _busy ? C.line : C.flamingo, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_upward_rounded, size: 22, color: Colors.white),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.showChips, required this.onChip, required this.store});
  final ChatMsg msg;
  final bool showChips;
  final ValueChanged<String> onChip;
  final Store store;

  @override
  Widget build(BuildContext context) {
    if (msg.role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: C.flamingo,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(6)),
          ),
          child: Text(msg.text ?? '', style: tUi(15, weight: FontWeight.w600, color: Colors.white, height: 1.4)),
        ),
      );
    }
    final thinking = msg.status == 'thinking';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Puff(size: 40, mood: thinking ? 'think' : msg.mood, blink: false),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                border: Border.all(color: C.line, width: 1.5),
              ),
              child: thinking
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      for (var k = 0; k <= msg.stepAt && k < msg.steps.length; k++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(children: [
                            Icon(k < msg.stepAt ? Icons.check_circle_rounded : Icons.more_horiz_rounded, size: 16, color: k < msg.stepAt ? C.mint : C.ink3),
                            const SizedBox(width: 6),
                            Flexible(child: Text(msg.steps[k], style: tUi(14, weight: FontWeight.w600, color: C.ink2))),
                          ]),
                        ),
                    ])
                  : Text(msg.text ?? '', style: tUi(15, height: 1.45)),
            ),
            if (!thinking) for (final b in msg.blocks) Padding(padding: const EdgeInsets.only(top: 8), child: _block(context, b)),
            if (!thinking && showChips && msg.chips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(spacing: 6, runSpacing: 6, children: [for (final c in msg.chips) NChip(label: c, height: 34, fontSize: 13, onTap: () => onChip(c))]),
              ),
          ]),
        ),
      ]),
    );
  }

  List<List<String>> _rows(Object? x) => [
        if (x is List)
          for (final r in x) [if (r is List) for (final e in r) '$e'],
      ];

  Widget _block(BuildContext context, Map<String, dynamic> b) {
    final type = b['type'];
    if (type == 'card') {
      final s = kSvc['${b['svc']}'];
      if (s == null) return const SizedBox.shrink();
      return NCard(
        padding: const EdgeInsets.all(12),
        onTap: () => Nav.overlay('card', id: s.id),
        child: Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: s.t.soft, borderRadius: BorderRadius.circular(16)), child: Critter(s.id, size: 50, shadow: false)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.nick} · ${s.name}', style: tUi(15, weight: FontWeight.w700)),
              Text(s.tagline, style: tUi(13, color: C.ink2)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: C.ink3),
        ]),
      );
    }
    if (type == 'tip') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.note, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Eyebrow('Exam whisper', color: C.butterInk),
          const SizedBox(height: 2),
          Text('${b['text']}', style: tHand(17, height: 1.3)),
        ]),
      );
    }
    if (type == 'compare' || type == 'cost') {
      final rows = _rows(b['rows']);
      final isCmp = type == 'compare';
      return NCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isCmp)
            Row(children: [
              const Expanded(flex: 3, child: SizedBox()),
              Expanded(flex: 4, child: Text('${b['a']}', style: tUi(13, weight: FontWeight.w800, color: C.flamingoDeep))),
              Expanded(flex: 4, child: Text('${b['b']}', style: tUi(13, weight: FontWeight.w800, color: C.grape))),
            ])
          else
            Text('${b['title']}', style: tUi(14, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: Text(r.isNotEmpty ? r[0] : '', style: tUi(12, weight: FontWeight.w700, color: C.ink3))),
                if (isCmp) ...[
                  Expanded(flex: 4, child: Text(r.length > 1 ? r[1] : '', style: tUi(13, height: 1.3))),
                  Expanded(flex: 4, child: Text(r.length > 2 ? r[2] : '', style: tUi(13, height: 1.3))),
                ] else
                  Expanded(flex: 5, child: Text(r.length > 1 ? r[1] : '', textAlign: TextAlign.right, style: tUi(13, weight: FontWeight.w700))),
              ]),
            ),
          if (b['foot'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${b['foot']}', style: tUi(12, color: C.ink3, height: 1.35))),
        ]),
      );
    }
    if (type == 'quiz') {
      final qid = '${b['qid']}';
      Question? q;
      for (final x in kQuestions) {
        if (x.id == qid) q = x;
      }
      final qq = q;
      if (qq == null) return const SizedBox.shrink();
      final ans = msg.answers['a'];
      return NCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(qq.q, style: tUi(15, weight: FontWeight.w700, height: 1.35)),
          const SizedBox(height: 10),
          for (var k = 0; k < qq.options.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OptionTile(
                text: qq.options[k],
                state: ans == null ? 0 : (k == qq.a ? 1 : (k == ans ? 2 : 0)),
                onTap: ans != null
                    ? null
                    : () {
                        store.patchChat(msg.id, (m) => m.answers['a'] = k);
                        Sfx.play(k == qq.a ? 'correct' : 'wrong');
                        if (k == qq.a) store.addXP(5, 0.5);
                      },
              ),
            ),
          if (ans != null) Text('${ans == qq.a ? 'Yes! ' : 'Not quite. '}${qq.why}', style: tUi(14, color: C.ink2, height: 1.4)),
        ]),
      );
    }
    if (type == 'plan') {
      final items = b['items'] is List ? b['items'] as List : const [];
      return NCard(
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          for (var k = 0; k < items.length; k++)
            Builder(builder: (ctx) {
              final it = items[k] is Map ? Map<String, dynamic>.from(items[k] as Map) : <String, dynamic>{};
              final a = it['action'] is Map ? Map<String, dynamic>.from(it['action'] as Map) : <String, dynamic>{};
              return Press(
                label: '${it['label']}',
                onTap: () => _act(a),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: C.flamingoSoft, shape: BoxShape.circle),
                      child: Text('${k + 1}', style: tUi(13, weight: FontWeight.w800, color: C.flamingoDeep)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${it['label']}', style: tUi(14, weight: FontWeight.w700)),
                        Text('${it['sub'] ?? ''}', style: tUi(12, weight: FontWeight.w600, color: C.ink3)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: C.ink3),
                  ]),
                ),
              );
            }),
        ]),
      );
    }
    return const SizedBox.shrink();
  }

  void _act(Map<String, dynamic> a) {
    final t = a['type'];
    final id = a['id'] as String?;
    if (t == 'pack') {
      Nav.overlay('pack');
    } else if (t == 'lesson' && id != null && kLesson[id] != null) {
      openLesson(kLesson[id]!);
    } else if (t == 'review') {
      Nav.push('review');
    } else if (t == 'lab') {
      Nav.push('labBuild', {'id': id ?? 'results-day'});
    }
  }
}
