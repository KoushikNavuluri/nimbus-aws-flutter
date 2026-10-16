import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/art.dart';
import '../data/flashcards.dart';
import '../nav.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/kit.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final List<Flash> _cards;
  int _i = 0;
  bool _flip = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _cards = List<Flash>.of(dueCards(readStore(context).state));
  }

  void _grade(String g) {
    final store = readStore(context);
    store.reviewCard(_cards[_i].id, g);
    Sfx.play(g == 'again' ? 'tap' : 'correct');
    if (_i < _cards.length - 1) {
      setState(() {
        _i++;
        _flip = false;
      });
    } else {
      store.addXP(_cards.length * 4, _cards.length * 0.4);
      store.stamp('reviewer');
      Sfx.play('win');
      Confetti.fire(y: 0.35);
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty || _done) {
      return NScreen(
        child: Column(children: [
          const TopBar(title: 'Review', close: true),
          Expanded(
            child: Center(
              child: EmptyState(
                art: const Puff(size: 130, mood: 'cheer'),
                title: _done ? 'Memory palace upgraded.' : 'All caught up',
                body: _done ? '${_cards.length} cards reviewed. Spaced repetition does the rest.' : 'No cards due. Collect more Cloudlings to grow your deck.',
                action: NBtn(label: 'Back', onTap: Nav.pop),
              ),
            ),
          ),
        ]),
      );
    }
    final f = _cards[_i];
    final sid = f.svc;
    return NScreen(
      child: Column(children: [
        TopBar(title: 'Review', sub: 'Card ${_i + 1} of ${_cards.length}', close: true),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: PBar(pct: _i / _cards.length, h: 8, color: C.mint)),
        Expanded(
          child: Center(
            child: Press(
              sound: 'flip',
              label: _flip ? f.back : 'Flip: ${f.front}',
              onTap: () => setState(() => _flip = !_flip),
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_i),
                tween: Tween<double>(begin: 0.0, end: _flip ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 450),
                curve: kEase,
                builder: (c, v, _) {
                  final back = v > 0.5;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(v * math.pi + (back ? math.pi : 0)),
                    child: Container(
                      width: 300,
                      height: 380,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: back ? Colors.white : C.mintSoft,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: C.ink, width: 2.5),
                        boxShadow: const [BoxShadow(color: C.ink, offset: Offset(0, 6))],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (sid != null) Critter(sid, size: 90, mood: back ? 'cheer' : 'think') else Puff(size: 90, mood: back ? 'cheer' : 'think'),
                        const SizedBox(height: 16),
                        Text(back ? f.back : f.front, textAlign: TextAlign.center, style: back ? tUi(17, weight: FontWeight.w600, height: 1.45) : tDisplay(22, height: 1.2)),
                        const SizedBox(height: 16),
                        Text(back ? 'How well did you know it?' : 'Tap to flip', style: tUi(13, weight: FontWeight.w700, color: C.ink3)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, Insets.bottomOf(context) + 12),
          child: _flip
              ? Row(children: [
                  Expanded(child: NBtn(label: 'Again', kind: Btn.soft, expand: true, sound: null, onTap: () => _grade('again'))),
                  const SizedBox(width: 8),
                  Expanded(child: NBtn(label: 'Good', kind: Btn.ink, expand: true, sound: null, onTap: () => _grade('good'))),
                  const SizedBox(width: 8),
                  Expanded(child: NBtn(label: 'Easy', kind: Btn.mint, expand: true, sound: null, onTap: () => _grade('easy'))),
                ])
              : NBtn(label: 'Show answer', icon: Icons.flip_rounded, expand: true, sound: 'flip', onTap: () => setState(() => _flip = true)),
        ),
      ]),
    );
  }
}
