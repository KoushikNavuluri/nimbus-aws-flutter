import 'package:flutter/material.dart';

import '../art/art.dart';
import '../nav.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/kit.dart';
import '../ui/motion.dart';

class LevelUpScreen extends StatefulWidget {
  const LevelUpScreen({super.key, required this.level});
  final Level level;
  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Sfx.play('win');
      Confetti.fire(y: 0.35, count: 180, spread: 1.2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final next = levelFor(widget.level.at).next;
    return Material(
      color: const Color(0xEB14173F),
      child: Stack(children: [
        const Positioned.fill(child: StarField(count: 34, seed: 5)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const PopIn(child: Bob(child: Puff(size: 170, mood: 'cheer', cap: true))),
              const SizedBox(height: 16),
              Rise(index: 2, child: Eyebrow('Level up · level ${widget.level.n}', color: C.butter)),
              const SizedBox(height: 6),
              Rise(index: 3, child: Text(widget.level.name, textAlign: TextAlign.center, style: tDisplay(44, weight: FontWeight.w700, color: Colors.white))),
              const SizedBox(height: 8),
              Rise(
                index: 4,
                child: Text(next != null ? 'Next stop: ${next.name} at ${fmtIN(next.at)} XP.' : 'Top of the sky. Legend.',
                    textAlign: TextAlign.center, style: tUi(16, color: const Color(0xCCFFFFFF))),
              ),
              const SizedBox(height: 28),
              NBtn(label: 'Keep flying', icon: Icons.flight_takeoff_rounded, onTap: Nav.pop),
            ]),
          ),
        ),
      ]),
    );
  }
}
