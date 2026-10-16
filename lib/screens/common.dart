import 'package:flutter/material.dart';

import '../art/art.dart';
import '../data/path.dart';
import '../nav.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/kit.dart';

class AvatarButton extends StatelessWidget {
  const AvatarButton({super.key, this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final s = watch(context).state;
    final lv = levelFor(s.xp).cur;
    final name = s.profile.name.trim().isEmpty ? 'K' : s.profile.name.trim();
    return Press(
      label: 'Open your profile',
      onTap: () => Nav.push('me'),
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: C.flamingo,
                  shape: BoxShape.circle,
                  border: Border.all(color: dark ? const Color(0xE6FFFFFF) : C.ink, width: dark ? 3 : 2.5),
                ),
                child: Text(name.substring(0, 1).toUpperCase(), style: tDisplay(20, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                height: 22,
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: C.butter, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.ink, width: 2)),
                child: Text('${lv.n}', style: tUi(12, weight: FontWeight.w700, height: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TabTitle extends StatelessWidget {
  const TabTitle({super.key, required this.title, this.sub, this.child});
  final String title;
  final String? sub;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, Insets.topOf(context) + 10, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tDisplay(32, height: 1.02)),
                    if (sub != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(sub!, style: tUi(15, color: C.ink2, height: 1.35))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const AvatarButton(),
            ],
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class LessonArt extends StatelessWidget {
  const LessonArt({super.key, required this.lesson, this.size = 52, this.locked = false, this.color = C.ink});
  final Lesson lesson;
  final double size;
  final bool locked;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final svc = lesson.svc;
    if (svc != null) return Critter(svc, size: size, shadow: false, silhouette: locked);
    if (lesson.kind == 'cinema') return Icon(Icons.movie_rounded, size: size * 0.5, color: color);
    if (lesson.kind == 'quiz') return Icon(Icons.emoji_events_rounded, size: size * 0.5, color: color);
    return Puff(size: size, mood: locked ? 'sleepy' : 'happy', blink: false);
  }
}

void openLesson(Lesson l) {
  if (l.kind == 'book') {
    Nav.push('book', {'bookId': l.ref, 'lessonId': l.id});
  } else if (l.kind == 'cinema') {
    Nav.push('cinema', {'id': l.ref, 'lessonId': l.id});
  } else if (l.kind == 'quiz') {
    Nav.push('quiz', {'mode': 'mock', 'lessonId': l.id});
  }
}
