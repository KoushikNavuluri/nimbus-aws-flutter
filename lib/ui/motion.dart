import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';

/// Staggered arrival: fade + 12px rise, ~320ms, eased like the rest of Nimbus.
class Rise extends StatelessWidget {
  const Rise({super.key, required this.child, this.index = 0, this.step = 50, this.dy = 12, this.duration = 320});
  final Widget child;
  final int index;
  final int step;
  final double dy;
  final int duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final delay = index * step;
    final total = duration + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: total),
      builder: (c, t, ch) {
        final local = kEase.transform(((t * total - delay) / duration).clamp(0.0, 1.0).toDouble());
        return Opacity(opacity: local, child: Transform.translate(offset: Offset(0, dy * (1 - local)), child: ch));
      },
      child: child,
    );
  }
}

/// Pops in with a little overshoot.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delay = 0, this.from = 0.6});
  final Widget child;
  final int delay;
  final double from;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final total = 420 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: total),
      builder: (c, t, ch) {
        final local = ((t * total - delay) / 420).clamp(0.0, 1.0).toDouble();
        final e = Curves.easeOutBack.transform(local);
        return Opacity(opacity: local, child: Transform.scale(scale: from + (1 - from) * e, child: ch));
      },
      child: child,
    );
  }
}
