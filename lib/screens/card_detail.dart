import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/path.dart';
import '../data/services.dart';
import '../nav.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/holo_card.dart';
import '../ui/kit.dart';

class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({super.key, required this.id});
  final String id;
  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  bool _flip = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = readStore(context);
      if (widget.id == 's3' && store.state.collected.containsKey('s3')) store.hero('album');
    });
  }

  Widget _glass(IconData icon, String label, VoidCallback onTap, {bool solid = false, Color iconColor = Colors.white, String sound = 'tap'}) => Press(
        label: label,
        sound: sound,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: solid ? Colors.white : const Color(0x29FFFFFF), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, size: 22, color: iconColor),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final store = watch(context);
    final id = widget.id;
    final s = kSvc[id] ?? kServices.first;
    final t = s.t;
    final c = store.state.collected[id];
    final fav = store.state.favorites.contains(id);
    Island? mod;
    for (final m in kIslands) {
      if (m.lessons.any((l) => l.svc == id)) {
        mod = m;
        break;
      }
    }
    void close() => Nav.pop();
    void openBook() {
      Navigator.of(context).pop();
      Nav.push('book', {'bookId': id, 'lessonId': id});
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: close,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 1.0,
                        colors: [t.color.withValues(alpha: 0.4), const Color(0xD11D2352)],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, Insets.topOf(context) + 6, 16, 0),
                child: Row(
                  children: [
                    _glass(Icons.close_rounded, 'Close', close),
                    Expanded(
                      child: Center(
                        child: c != null
                            ? Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: const Color(0x29FFFFFF), borderRadius: BorderRadius.circular(99)),
                                child: Text('${svcLevelLabel(c.level)} · found ${shortDate(c.at)}'.toUpperCase(),
                                    style: tUi(13, weight: FontWeight.w700, color: Colors.white, spacing: 1.2)),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    if (c != null)
                      _glass(
                        fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        fav ? 'Remove from favorites' : 'Add to favorites',
                        () => store.toggleFav(id),
                        solid: fav,
                        iconColor: fav ? C.flamingo : Colors.white,
                        sound: 'pop',
                      )
                    else
                      const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 650),
                    curve: const Cubic(0.34, 1.4, 0.64, 1),
                    builder: (ctx, v, child) => Transform.translate(
                      offset: Offset(0, 40 * (1 - v)),
                      child: Transform.rotate(angle: -6 * (1 - v) * math.pi / 180, child: Transform.scale(scale: 0.7 + 0.3 * v, child: child)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: HoloCard(
                        id: id,
                        size: 'lg',
                        silhouette: c == null,
                        flipped: _flip,
                        onTap: c != null
                            ? () {
                                Sfx.play('flip');
                                setState(() => _flip = !_flip);
                              }
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, Insets.bottomOf(context) + 18),
                child: c != null
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.threesixty_rounded, size: 15, color: Color(0xD9FFFFFF)),
                              const SizedBox(width: 6),
                              Text('Tap the card to flip · drag to tilt', style: tUi(14, weight: FontWeight.w600, color: const Color(0xD9FFFFFF))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: NBtn(label: 'Pocket Book', icon: Icons.menu_book_rounded, expand: true, onTap: openBook)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: NBtn(
                                  label: 'Ask Puff',
                                  icon: Icons.chat_bubble_rounded,
                                  kind: Btn.glass,
                                  expand: true,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Nav.push('chat', {'prefill': 'Explain ${s.short}'});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Text('Not found yet.', style: tDisplay(22, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(
                            'Pop it from a Sky Pack, or meet it on the ${mod?.title ?? 'Skyway'} island.',
                            textAlign: TextAlign.center,
                            style: tUi(15, color: const Color(0xCCFFFFFF), height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          NBtn(label: 'Peek at its lesson', icon: Icons.route_rounded, expand: true, onTap: openBook),
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
