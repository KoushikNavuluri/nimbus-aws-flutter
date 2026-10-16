import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'art/art.dart';
import 'nav.dart';
import 'screens/album.dart';
import 'screens/lab.dart';
import 'screens/onboarding.dart';
import 'screens/path.dart';
import 'screens/today.dart';
import 'store.dart';
import 'theme.dart';
import 'ui/kit.dart';

class NimbusApp extends StatelessWidget {
  const NimbusApp({super.key, required this.store});
  final Store store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Nimbus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: C.sky,
          colorScheme: ColorScheme.fromSeed(seedColor: C.flamingo, primary: C.flamingo, surface: C.cotton),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          textSelectionTheme: const TextSelectionThemeData(cursorColor: C.flamingo, selectionColor: Color(0xFFFFC9D8), selectionHandleColor: C.flamingo),
        ),
        home: const Stage(),
      ),
    );
  }
}

bool get _touchOS => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// Desktop/web: a phone on a stage with the pitch and a live hero checklist.
/// Phones: the app, full-bleed.
class Stage extends StatelessWidget {
  const Stage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      if (_touchOS || w < 500) {
        if (w > 640) {
          return Material(
            color: C.sky,
            child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: const Phone(stage: false))),
          );
        }
        return const Phone(stage: false);
      }
      final scale = ((h - 40) / 868).clamp(0.3, 1.0).toDouble();
      final wide = w >= 1180;
      return Material(
        color: C.sky,
        child: Stack(
          children: [
            const Positioned.fill(child: _DriftBlobs()),
            const Positioned.fill(child: Opacity(opacity: 0.6, child: CustomPaint(painter: DotsPainter()))),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (wide) ...[const _Pitch(), const SizedBox(width: 56)],
                  SizedBox(width: 414 * scale, height: 868 * scale, child: const FittedBox(child: _Bezel())),
                  if (wide) ...[const SizedBox(width: 56), const HeroChecklist()],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _Bezel extends StatelessWidget {
  const _Bezel();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    const pad = EdgeInsets.only(top: 44, bottom: 14);
    return Container(
      width: 414,
      height: 868,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF14183B),
        borderRadius: BorderRadius.circular(62),
        border: Border.all(color: const Color(0xFF2A2F5E), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x991D2352), offset: Offset(0, 40), blurRadius: 80, spreadRadius: -30)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: SizedBox(
          width: 390,
          height: 844,
          child: Stack(
            children: [
              Positioned.fill(
                child: MediaQuery(
                  data: mq.copyWith(size: const Size(390, 844), padding: pad, viewPadding: pad, viewInsets: EdgeInsets.zero),
                  child: const Phone(stage: true),
                ),
              ),
              Positioned(
                top: 10,
                left: (390 - 118) / 2,
                child: IgnorePointer(
                  child: Container(width: 118, height: 32, decoration: BoxDecoration(color: const Color(0xFF14183B), borderRadius: BorderRadius.circular(99))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Phone extends StatefulWidget {
  const Phone({super.key, required this.stage});
  final bool stage;

  @override
  State<Phone> createState() => _PhoneState();
}

class _PhoneState extends State<Phone> {
  StreamSubscription<NimbusEvent>? _sub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub ??= readStore(context).events.listen(_onEvent);
  }

  void _onEvent(NimbusEvent e) {
    if (e.type == EvType.streak) {
      Toasts.show('${e.amount}-day streak!', body: 'Your sky stays lit. See you tomorrow.', icon: Icons.local_fire_department_rounded, bg: C.flamingoDeep);
    } else if (e.type == EvType.stamp) {
      final st = kStamps[e.id];
      Toasts.show('Stamp earned: ${st?.$1 ?? 'New stamp'}', body: st?.$2, icon: Icons.verified_rounded);
    } else if (e.type == EvType.levelUp) {
      final lv = e.level;
      if (lv != null) Nav.levelUp(lv);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = watch(context).state;
    final mq = MediaQuery.of(context);
    final top = widget.stage ? 44.0 : math.max(mq.padding.top, 12.0);
    final bottom = widget.stage ? 14.0 : math.max(mq.padding.bottom, 8.0);
    return Insets(
      top: top,
      bottom: bottom,
      child: Material(
        color: C.sky,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: kEase,
                layoutBuilder: (cur, prev) => Stack(fit: StackFit.expand, children: [...prev, if (cur != null) cur]),
                child: s.onboarded ? const _Shell(key: ValueKey('shell')) : const OnboardingScreen(key: ValueKey('onboarding')),
              ),
            ),
            if (widget.stage) const StatusBarFake(),
            const XpFloats(),
            const ConfettiLayer(),
            const ToastHost(),
          ],
        ),
      ),
    );
  }
}

/// The phone's own navigator: tabs live in the root route, everything else is pushed.
class _Shell extends StatelessWidget {
  const _Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final nav = Nav.key.currentState;
        if (nav != null && nav.canPop()) {
          nav.maybePop();
          return;
        }
        final store = readStore(context);
        if (store.tab.value != 'today') {
          store.tab.value = 'today';
        } else {
          SystemNavigator.pop();
        }
      },
      child: Navigator(
        key: Nav.key,
        observers: [Nav.observer],
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: const RouteSettings(name: 'root'),
          transitionDuration: Duration.zero,
          pageBuilder: (c, a, b) => const TabsShell(),
        ),
      ),
    );
  }
}

class TabsShell extends StatelessWidget {
  const TabsShell({super.key});

  static Widget _tabFor(String t) {
    if (t == 'path') return const PathScreen();
    if (t == 'lab') return const LabScreen();
    if (t == 'album') return const AlbumScreen();
    return const TodayScreen();
  }

  @override
  Widget build(BuildContext context) {
    final store = readStore(context);
    return NScreen(
      child: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<String>(
              valueListenable: store.tab,
              builder: (c, t, _) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: kEase,
                switchOutCurve: Curves.easeOut,
                layoutBuilder: (cur, prev) => Stack(fit: StackFit.expand, children: [...prev, if (cur != null) cur]),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.012), end: Offset.zero).animate(anim), child: child),
                ),
                child: KeyedSubtree(key: ValueKey(t), child: _tabFor(t)),
              ),
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: TabBarNimbus()),
        ],
      ),
    );
  }
}

const _tabs = [
  ('today', 'Today', Icons.wb_sunny_rounded),
  ('path', 'Skyway', Icons.route_rounded),
  ('puff', 'Puff', Icons.cloud_rounded),
  ('lab', 'Lab', Icons.science_rounded),
  ('album', 'Cloudex', Icons.collections_bookmark_rounded),
];

class TabBarNimbus extends StatelessWidget {
  const TabBarNimbus({super.key});

  @override
  Widget build(BuildContext context) {
    final store = readStore(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, Insets.bottomOf(context) + 6),
      child: ValueListenableBuilder<String>(
        valueListenable: store.tab,
        builder: (c, tab, _) {
          final idx = _tabs.indexWhere((x) => x.$1 == tab);
          return SizedBox(
            height: 90,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 68,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xF2FBFCFF),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0x141D2352), width: 1.5),
                      boxShadow: const [BoxShadow(color: Color(0x801D2352), offset: Offset(0, 18), blurRadius: 40, spreadRadius: -18)],
                    ),
                    child: LayoutBuilder(builder: (c, box) {
                      final slot = box.maxWidth / _tabs.length;
                      return Stack(
                        children: [
                          if (idx >= 0)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 380),
                              curve: kEase,
                              left: slot * idx + 6,
                              top: 8,
                              bottom: 8,
                              width: slot - 12,
                              child: Container(decoration: BoxDecoration(color: C.flamingoSoft, borderRadius: BorderRadius.circular(20))),
                            ),
                          Row(
                            children: [
                              for (final t in _tabs)
                                Expanded(
                                  child: t.$1 == 'puff'
                                      ? const SizedBox.shrink()
                                      : _TabItem(id: t.$1, label: t.$2, icon: t.$3, on: t.$1 == tab, onTap: () => Nav.tab(store, t.$1)),
                                ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Press(
                      label: 'Ask Puff',
                      sound: 'pop',
                      onTap: () => Nav.push('chat'),
                      child: Container(
                        width: 70,
                        height: 70,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: C.ink, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Color(0x99FF4D7E), offset: Offset(0, 10), blurRadius: 22, spreadRadius: -8),
                            BoxShadow(color: C.flamingoSoft, spreadRadius: 5),
                          ],
                        ),
                        child: const Bob(amp: 4, child: Puff(size: 54)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.id, required this.label, required this.icon, required this.on, required this.onTap});
  final String id;
  final String label;
  final IconData icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = on ? C.flamingoDeep : C.ink3;
    return Press(
      label: label,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 23, color: color),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.clip, style: tUi(12, weight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// 9:41-style status bar, only on the desktop stage.
class StatusBarFake extends StatefulWidget {
  const StatusBarFake({super.key});
  @override
  State<StatusBarFake> createState() => _StatusBarFakeState();
}

class _StatusBarFakeState extends State<StatusBarFake> {
  Timer? _t;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = watch(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 44,
      child: IgnorePointer(
        child: ValueListenableBuilder<List<String>>(
          valueListenable: Nav.stack,
          builder: (c, names, _) => ValueListenableBuilder<String>(
            valueListenable: store.tab,
            builder: (c, tab, _) {
              final top = names.isEmpty ? 'root' : names.last;
              final dark = const {'pack', 'card', 'levelup', 'cinema'}.contains(top) || (tab == 'today' && top == 'root' && store.state.onboarded && isNight());
              final fg = dark ? Colors.white : C.ink;
              final hh = _now.hour.toString().padLeft(2, '0');
              final mm = _now.minute.toString().padLeft(2, '0');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    Text('$hh:$mm', style: tUi(15, weight: FontWeight.w700, color: fg).copyWith(fontFeatures: kTabular)),
                    const Spacer(),
                    Icon(Icons.signal_cellular_alt_rounded, size: 16, color: fg),
                    const SizedBox(width: 5),
                    Icon(Icons.wifi_rounded, size: 16, color: fg),
                    const SizedBox(width: 5),
                    RotatedBox(quarterTurns: 1, child: Icon(Icons.battery_full_rounded, size: 20, color: fg)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class HeroChecklist extends StatelessWidget {
  const HeroChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    final store = watch(context);
    final s = store.state;
    final done = kHeroSteps.where((x) => s.hero.containsKey(x.$1)).length;
    void jump(String id) {
      if (!s.onboarded) {
        Toasts.show('Finish meeting Puff first', body: 'Three taps on the phone and you are in.');
        return;
      }
      if (id == 'pack') {
        Nav.popAll();
        Nav.overlay('pack');
      } else if (id == 'book') {
        Nav.push('book', {'bookId': 's3', 'lessonId': 's3'});
      } else if (id == 'quiz') {
        Nav.push('quiz', {'svc': 's3'});
      } else if (id == 'lab') {
        Nav.push('labBuild', {'id': 'results-day'});
      } else if (id == 'ask') {
        Nav.push('chat');
      } else if (id == 'album') {
        Nav.tab(store, 'album');
      }
    }

    return SizedBox(
      width: 300,
      child: NCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Hero demo'),
            const SizedBox(height: 4),
            Text(done == kHeroSteps.length ? 'You did the whole flight!' : 'Try the whole flight', style: tDisplay(22)),
            const SizedBox(height: 4),
            Text('Ticks itself as you go. Tap a step to jump there.', style: tUi(14, color: C.ink2, height: 1.35)),
            const SizedBox(height: 14),
            for (var i = 0; i < kHeroSteps.length; i++)
              Press(
                scale: 0.98,
                label: kHeroSteps[i].$2,
                onTap: () => jump(kHeroSteps[i].$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: s.hero.containsKey(kHeroSteps[i].$1) ? C.mint : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: s.hero.containsKey(kHeroSteps[i].$1) ? C.mint : C.line, width: 2),
                        ),
                        child: s.hero.containsKey(kHeroSteps[i].$1)
                            ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                            : Text('${i + 1}', style: tUi(12, weight: FontWeight.w700, color: C.ink3)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          kHeroSteps[i].$2,
                          style: tUi(15,
                              weight: FontWeight.w600,
                              color: s.hero.containsKey(kHeroSteps[i].$1) ? C.ink3 : C.ink,
                              decoration: s.hero.containsKey(kHeroSteps[i].$1) ? TextDecoration.lineThrough : null,
                              decorationColor: const Color(0x9914B886)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Press(
              label: 'Reset demo',
              onTap: () {
                Nav.popAll();
                Nav.reset();
                Toasts.clear();
                store.reset();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restart_alt_rounded, size: 17, color: C.ink3),
                  const SizedBox(width: 6),
                  Text('Reset demo', style: tUi(14, weight: FontWeight.w700, color: C.ink3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pitch extends StatelessWidget {
  const _Pitch();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Bob(child: Puff(size: 78)),
              const SizedBox(width: 12),
              Text('Nimbus', style: tDisplay(44, weight: FontWeight.w700, height: 1.0)),
            ],
          ),
          const SizedBox(height: 20),
          Text("AWS, but you'll look forward to it.", style: tDisplay(34, height: 1.05)),
          const SizedBox(height: 12),
          Text('Collect 18 Cloudlings, build real architectures and throw outages at them. Puff explains the hard bits.',
              style: tUi(16, color: C.ink2, height: 1.6)),
          const SizedBox(height: 20),
          Text('Flutter app · works fully offline · Puff is a local, rule-based tutor (no AI model)', style: tUi(13, weight: FontWeight.w600, color: C.ink3, height: 1.4)),
        ],
      ),
    );
  }
}

class _DriftBlobs extends StatefulWidget {
  const _DriftBlobs();
  @override
  State<_DriftBlobs> createState() => _DriftBlobsState();
}

class _DriftBlobsState extends State<_DriftBlobs> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 20));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(double size, Color c, double opacity) => Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c, c.withValues(alpha: 0.0)], stops: const [0.0, 0.7]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (c, _) {
          final a = math.sin(_c.value * math.pi * 2);
          final b = math.sin((_c.value + 0.4) * math.pi * 2);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -160 + 40 * a,
                top: -160 - 30 * a,
                child: Transform.scale(scale: 1 + 0.04 * (a + 1), child: _blob(620, const Color(0xFFFFD3E0), 0.7)),
              ),
              Positioned(
                right: -160 - 40 * b,
                bottom: -192 + 30 * b,
                child: Transform.scale(scale: 1 + 0.04 * (b + 1), child: _blob(700, const Color(0xFFC9DAFF), 0.8)),
              ),
            ],
          );
        },
      ),
    );
  }
}
