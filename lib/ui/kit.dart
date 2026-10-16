import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/services.dart';
import '../nav.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';

// ───────── insets (fake status bar on the desktop stage, real safe areas on phones) ─────────
class Insets extends InheritedWidget {
  const Insets({super.key, required this.top, required this.bottom, required super.child});
  final double top;
  final double bottom;

  static Insets? maybeOf(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Insets>();
  static double topOf(BuildContext c) => maybeOf(c)?.top ?? math.max(MediaQuery.paddingOf(c).top, 12.0);
  static double bottomOf(BuildContext c) => maybeOf(c)?.bottom ?? math.max(MediaQuery.paddingOf(c).bottom, 8.0);

  @override
  bool updateShouldNotify(Insets oldWidget) => oldWidget.top != top || oldWidget.bottom != bottom;
}

const kRimShadow = [BoxShadow(color: Color(0x1A1D2352), offset: Offset(0, 3), blurRadius: 8, spreadRadius: -2)];

/// Screen ground: gives every route a Material so text and inputs render properly.
class NScreen extends StatelessWidget {
  const NScreen({super.key, required this.child, this.color = C.sky});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Material(color: color, child: child);
}

// ───────── press ─────────
class Press extends StatefulWidget {
  const Press({super.key, required this.child, this.onTap, this.sound = 'tap', this.enabled = true, this.label, this.scale = 0.97});
  final Widget child;
  final VoidCallback? onTap;
  final String? sound;
  final bool enabled;
  final String? label;
  final double scale;

  @override
  State<Press> createState() => _PressState();
}

class _PressState extends State<Press> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onTap != null;
    return Semantics(
      button: true,
      enabled: active,
      label: widget.label,
      child: MouseRegion(
        cursor: active ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: active ? (_) => _set(true) : null,
          onTapUp: active ? (_) => _set(false) : null,
          onTapCancel: active ? () => _set(false) : null,
          onTap: active
              ? () {
                  final s = widget.sound;
                  if (s != null) Sfx.play(s);
                  widget.onTap!();
                }
              : null,
          child: AnimatedScale(
            scale: _down && active ? widget.scale : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ───────── buttons ─────────
enum Btn { primary, ink, soft, mint, danger, glass, white }

class NBtn extends StatefulWidget {
  const NBtn({
    super.key,
    this.label,
    this.icon,
    this.trailingIcon,
    this.onTap,
    this.kind = Btn.primary,
    this.height = 48,
    this.expand = false,
    this.enabled = true,
    this.sound = 'tap',
    this.fontSize = 16,
    this.padH = 20,
    this.child,
    this.semantic,
  });
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final Btn kind;
  final double height;
  final bool expand;
  final bool enabled;
  final String? sound;
  final double fontSize;
  final double padH;
  final Widget? child;
  final String? semantic;

  @override
  State<NBtn> createState() => _NBtnState();
}

class _NBtnState extends State<NBtn> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kind;
    final (Color bg, Color fg, Color? lip, Color? border) = switch (k) {
      Btn.primary => (C.flamingo, Colors.white, C.flamingoDeep, null),
      Btn.ink => (C.ink, Colors.white, const Color(0xFF0E1236), null),
      Btn.soft => (Colors.white, C.ink, C.line, C.line),
      Btn.mint => (C.mint, Colors.white, C.mintDeep, null),
      Btn.danger => (C.danger, Colors.white, C.dangerDeep, null),
      Btn.glass => (const Color(0x1FFFFFFF), Colors.white, null, const Color(0x40FFFFFF)),
      Btn.white => (Colors.white, C.ink, const Color(0x331D2352), null),
    };
    final active = widget.enabled && widget.onTap != null;
    final down = _down && active;
    final double lipH = lip == null ? 0.0 : (down ? 2.0 : (k == Btn.soft ? 4.0 : 5.0));
    final content = widget.child ??
        Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) Icon(widget.icon, size: widget.fontSize + 3, color: fg),
            if (widget.icon != null && widget.label != null) const SizedBox(width: 8),
            if (widget.label != null)
              Flexible(
                child: Text(widget.label!, maxLines: 1, overflow: TextOverflow.ellipsis, style: tUi(widget.fontSize, color: fg, weight: FontWeight.w700)),
              ),
            if (widget.trailingIcon != null) ...[
              const SizedBox(width: 6),
              Icon(widget.trailingIcon, size: widget.fontSize + 3, color: fg),
            ],
          ],
        );
    return Semantics(
      button: true,
      enabled: active,
      label: widget.semantic ?? widget.label,
      child: MouseRegion(
        cursor: active ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: active ? (_) => _set(true) : null,
          onTapUp: active ? (_) => _set(false) : null,
          onTapCancel: active ? () => _set(false) : null,
          onTap: active
              ? () {
                  final s = widget.sound;
                  if (s != null) Sfx.play(s);
                  widget.onTap!();
                }
              : null,
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.5,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              height: widget.height,
              width: widget.expand ? double.infinity : null,
              padding: EdgeInsets.symmetric(horizontal: widget.padH),
              transform: Matrix4.translationValues(0, down ? 3.0 : 0.0, 0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: border != null ? Border.all(color: border, width: 1.5) : null,
                boxShadow: lip == null ? null : [BoxShadow(color: lip, offset: Offset(0, lipH))],
              ),
              child: IconTheme(data: IconThemeData(color: fg), child: content),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────── surfaces ─────────
class NCard extends StatelessWidget {
  const NCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = C.cotton,
    this.gradient,
    this.radius = 24,
    this.onTap,
    this.sound = 'tap',
    this.clip = false,
    this.border,
    this.shadow = kCardShadow,
    this.label,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Gradient? gradient;
  final double radius;
  final VoidCallback? onTap;
  final String? sound;
  final bool clip;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final String? label;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
        border: border ?? Border.all(color: const Color(0x0F1D2352)),
      ),
      child: child,
    );
    if (onTap != null) card = Press(onTap: onTap, sound: sound, label: label, scale: 0.98, child: card);
    return card;
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = C.ink3});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: tEyebrow(color: color));
}

class IconBox extends StatelessWidget {
  const IconBox(this.icon, {super.key, this.color = C.ink, this.bg = Colors.white, this.size = 40, this.iconSize = 20, this.radius = 14});
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  final double iconSize;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
        child: Icon(icon, size: iconSize, color: color),
      );
}

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.sub, this.onBack, this.close = false, this.dark = false, this.right});
  final String title;
  final String? sub;
  final VoidCallback? onBack;
  final bool close;
  final bool dark;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : C.ink;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, Insets.topOf(context) + 6, 16, 8),
      child: Row(
        children: [
          Press(
            label: close ? 'Close' : 'Back',
            onTap: onBack ?? Nav.pop,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dark ? const Color(0x1AFFFFFF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: dark ? null : kRimShadow,
              ),
              child: Icon(close ? Icons.close_rounded : Icons.chevron_left_rounded, size: close ? 22 : 28, color: fg),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: tDisplay(17, color: fg)),
                if (sub != null)
                  Text(sub!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: tUi(12, weight: FontWeight.w600, color: dark ? Colors.white70 : C.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 44, height: 44, child: Center(child: right)),
        ],
      ),
    );
  }
}

// ───────── sheets ─────────
Future<T?> showNimbusSheet<T>(BuildContext context, {required WidgetBuilder builder, bool tall = false}) {
  Sfx.play('pop');
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x661D2352),
    elevation: 0,
    builder: (c) => SheetFrame(tall: tall, child: builder(c)),
  );
}

class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.child, this.tall = false});
  final Widget child;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mq.size.height * (tall ? 0.88 : 0.8)),
        decoration: const BoxDecoration(
          color: C.cotton,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: kPopShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, Insets.bottomOf(context) + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(width: 48, height: 6, decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(99))),
                ),
                const SizedBox(height: 12),
                Flexible(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────── numbers & progress ─────────
class Num extends StatelessWidget {
  const Num(this.value, {super.key, this.style, this.format, this.duration = const Duration(milliseconds: 700)});
  final num value;
  final TextStyle? style;
  final String Function(double v)? format;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final rm = reduceMotion(context);
    final f = format ?? ((double v) => fmtIN(v.round()));
    final v = value.toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: v, end: v),
      duration: rm ? Duration.zero : duration,
      curve: Curves.easeOutCubic,
      builder: (c, x, _) => Text(f(x), style: (style ?? tUi(16)).copyWith(fontFeatures: kTabular)),
    );
  }
}

class Ring extends StatelessWidget {
  const Ring({super.key, required this.pct, this.size = 64, this.stroke = 8, this.color = C.flamingo, this.track = C.track, this.child});
  final double pct;
  final double size;
  final double stroke;
  final Color color;
  final Color track;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = pct.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: p),
        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 900),
        curve: kEase,
        builder: (c, v, ch) => CustomPaint(painter: _RingPainter(v, stroke, color, track), child: Center(child: ch)),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.stroke, this.color, this.track);
  final double v;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, r, Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);
    if (v <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * v,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color || o.track != track || o.stroke != stroke;
}

class PBar extends StatelessWidget {
  const PBar({super.key, required this.pct, this.color = C.flamingo, this.gradient, this.h = 10, this.track = C.track});
  final double pct;
  final Color color;
  final Gradient? gradient;
  final double h;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final p = pct.clamp(0.0, 1.0).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: p),
      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 800),
      curve: kEase,
      builder: (c, v, _) => Container(
        height: h,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(h / 2)),
        child: FractionallySizedBox(
          widthFactor: v,
          heightFactor: 1,
          child: Container(
            decoration: BoxDecoration(color: gradient == null ? color : null, gradient: gradient, borderRadius: BorderRadius.circular(h / 2)),
          ),
        ),
      ),
    );
  }
}

class Stars extends StatelessWidget {
  const Stars({super.key, required this.n, this.of = 3, this.size = 14, this.color = C.butter});
  final int n;
  final int of;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$n of $of stars',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < of; i++)
              Padding(
                padding: EdgeInsets.only(right: i < of - 1 ? 2 : 0),
                child: CustomPaint(size: Size.square(size), painter: StarPainter(i < n ? color : C.line)),
              ),
          ],
        ),
      );
}

class StarPainter extends CustomPainter {
  StarPainter(this.color, {this.outline = true});
  final Color color;
  final bool outline;

  static const _pts = [
    Offset(12, 2.5), Offset(14.9, 8.6), Offset(21.5, 9.4), Offset(16.6, 14.0), Offset(17.9, 20.6), //
    Offset(12, 17.3), Offset(6.1, 20.6), Offset(7.4, 14.0), Offset(2.5, 9.4), Offset(9.1, 8.6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Path()..moveTo(_pts[0].dx * k, _pts[0].dy * k);
    for (final o in _pts.skip(1)) {
      p.lineTo(o.dx * k, o.dy * k);
    }
    p.close();
    canvas.drawPath(p, Paint()..color = color);
    if (outline) {
      canvas.drawPath(
          p,
          Paint()
            ..color = C.ink
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = 1.6 * k);
    }
  }

  @override
  bool shouldRepaint(StarPainter o) => o.color != color;
}

class TypePill extends StatelessWidget {
  const TypePill(this.type, {super.key, this.small = false});
  final String type;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final t = kTypes[type];
    return Container(
      height: small ? 24 : 28,
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t?.soft ?? Colors.white, borderRadius: BorderRadius.circular(99)),
      child: Text((t?.label ?? '').toUpperCase(), style: tUi(12, weight: FontWeight.w700, color: t?.ink ?? C.ink, spacing: 1.0)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.art, required this.title, this.body, this.action});
  final Widget? art;
  final String title;
  final String? body;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (art != null) art!,
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: tDisplay(20)),
            if (body != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(body!, textAlign: TextAlign.center, style: tUi(15, color: C.ink2, height: 1.4)),
                ),
              ),
            if (action != null) Padding(padding: const EdgeInsets.only(top: 16), child: action),
          ],
        ),
      );
}

class NChip extends StatelessWidget {
  const NChip({super.key, required this.label, this.on = false, this.onTap, this.leading, this.height = 36, this.fontSize = 14, this.expand = false, this.sound = 'tap'});
  final String label;
  final bool on;
  final VoidCallback? onTap;
  final Widget? leading;
  final double height;
  final double fontSize;
  final bool expand;
  final String? sound;

  @override
  Widget build(BuildContext context) {
    final fg = on ? Colors.white : C.ink;
    return Press(
      onTap: onTap,
      sound: sound,
      label: label,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: on ? C.ink : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: on ? C.ink : C.line, width: 1.5),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              IconTheme(data: IconThemeData(size: fontSize + 2, color: fg), child: leading!),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: tUi(fontSize, weight: FontWeight.w600, color: fg))),
          ],
        ),
      ),
    );
  }
}

class NSwitch extends StatelessWidget {
  const NSwitch({super.key, required this.value, required this.onChanged, this.label, this.onColor = C.mint});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final Color onColor;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: value,
        label: label,
        child: Press(
          onTap: () => onChanged(!value),
          scale: 0.95,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: kEase,
            width: 52,
            height: 32,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(color: value ? onColor : C.line, borderRadius: BorderRadius.circular(99)),
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x331D2352), offset: Offset(0, 2), blurRadius: 4)],
              ),
            ),
          ),
        ),
      );
}

class NSlider extends StatelessWidget {
  const NSlider({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 1, this.divisions, this.color = C.flamingo, this.label});
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (c, box) {
      final w = box.maxWidth;
      final span = math.max(1.0, w - 28);
      final range = max - min;
      final double t = range == 0 ? 0.0 : ((value - min) / range).clamp(0.0, 1.0).toDouble();
      void at(double dx) {
        final double f = ((dx - 14).clamp(0.0, span)).toDouble() / span;
        var v = min + f * range;
        final d = divisions;
        if (d != null && d > 0) {
          final step = range / d;
          v = min + ((v - min) / step).round() * step;
        }
        onChanged(v.clamp(min, max).toDouble());
      }

      return Semantics(
        slider: true,
        value: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => at(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => at(d.localPosition.dx),
          child: SizedBox(
            height: 40,
            width: w,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: 14,
                  right: 14,
                  child: Container(height: 10, decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(99))),
                ),
                Positioned(
                  left: 14,
                  child: Container(width: span * t, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
                ),
                Positioned(
                  left: span * t,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: C.ink, width: 3),
                      boxShadow: const [BoxShadow(color: Color(0x331D2352), offset: Offset(0, 3))],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ───────── ambient motion ─────────
abstract class _Loop<T extends StatefulWidget> extends State<T> with SingleTickerProviderStateMixin {
  late final AnimationController ctrl = AnimationController(vsync: this, duration: period);
  bool _rm = false;
  Duration get period;
  bool get enabled => true;

  void _sync() {
    final on = enabled && !_rm;
    if (on && !ctrl.isAnimating) {
      ctrl.repeat();
    } else if (!on && ctrl.isAnimating) {
      ctrl.stop();
      ctrl.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rm = reduceMotion(context);
    _sync();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }
}

class Bob extends StatefulWidget {
  const Bob({super.key, required this.child, this.amp = 6, this.period = const Duration(milliseconds: 3600), this.enabled = true});
  final Widget child;
  final double amp;
  final Duration period;
  final bool enabled;
  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends _Loop<Bob> {
  @override
  Duration get period => widget.period;
  @override
  bool get enabled => widget.enabled;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: ctrl,
        builder: (c, child) => Transform.translate(offset: Offset(0, -widget.amp * (0.5 - 0.5 * math.cos(ctrl.value * 2 * math.pi))), child: child),
        child: widget.child,
      );
}

class Wobble extends StatefulWidget {
  const Wobble({super.key, required this.child, this.deg = 2.5, this.period = const Duration(milliseconds: 2800), this.enabled = true});
  final Widget child;
  final double deg;
  final Duration period;
  final bool enabled;
  @override
  State<Wobble> createState() => _WobbleState();
}

class _WobbleState extends _Loop<Wobble> {
  @override
  Duration get period => widget.period;
  @override
  bool get enabled => widget.enabled;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: ctrl,
        builder: (c, child) => Transform.rotate(
          angle: -math.cos(ctrl.value * 2 * math.pi) * widget.deg * math.pi / 180,
          alignment: const Alignment(0, 0.8),
          child: child,
        ),
        child: widget.child,
      );
}

class PulseRing extends StatefulWidget {
  const PulseRing({super.key, this.size = 48, this.color = C.flamingo, this.radius});
  final double size;
  final Color color;
  final double? radius;
  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends _Loop<PulseRing> {
  @override
  Duration get period => const Duration(milliseconds: 1600);
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: ctrl,
          builder: (c, _) {
            final t = ctrl.value;
            return Opacity(
              opacity: _rm ? 0.0 : (0.7 * (1 - t)).clamp(0.0, 1.0).toDouble(),
              child: Transform.scale(
                scale: 0.9 + 0.9 * t,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: widget.radius == null ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: widget.radius == null ? null : BorderRadius.circular(widget.radius!),
                    border: Border.all(color: widget.color, width: 3),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});
  final int trigger;
  final Widget child;
  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (c, child) {
          final t = _c.value;
          return Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0), child: child);
        },
        child: widget.child,
      );
}

class StarField extends StatefulWidget {
  const StarField({super.key, this.count = 40, this.seed = 7, this.color = Colors.white, this.maxR = 1.6});
  final int count;
  final int seed;
  final Color color;
  final double maxR;
  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends _Loop<StarField> {
  late final List<List<double>> _stars = () {
    final r = math.Random(widget.seed);
    return [for (var i = 0; i < widget.count; i++) [r.nextDouble(), r.nextDouble(), 0.6 + r.nextDouble() * widget.maxR, r.nextDouble()]];
  }();
  @override
  Duration get period => const Duration(milliseconds: 2600);
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(painter: _StarsPainter(_stars, ctrl, widget.color, _rm), size: Size.infinite),
        ),
      );
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.stars, this.anim, this.color, this.still) : super(repaint: anim);
  final List<List<double>> stars;
  final Animation<double> anim;
  final Color color;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    for (final s in stars) {
      final double a = still ? 0.7 : 0.25 + 0.75 * (0.5 + 0.5 * math.sin((t + s[3]) * 2 * math.pi));
      canvas.drawCircle(Offset(s[0] * size.width, s[1] * size.height), s[2], Paint()..color = color.withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_StarsPainter o) => o.color != color || o.still != still;
}

class Moon extends StatelessWidget {
  const Moon({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _MoonPainter());
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, r * 1.25, Paint()..color = const Color(0x22FFE7A8));
    final disc = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final bite = Path()..addOval(Rect.fromCircle(center: c + Offset(r * 0.55, -r * 0.35), radius: r * 0.82));
    final moon = Path.combine(PathOperation.difference, disc, bite);
    canvas.drawPath(moon, Paint()..color = const Color(0xFFFFE7A8));
  }

  @override
  bool shouldRepaint(_MoonPainter o) => false;
}

class DotsPainter extends CustomPainter {
  const DotsPainter({this.color = const Color(0x121D2352), this.gap = 18, this.r = 1.2});
  final Color color;
  final double gap;
  final double r;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (double y = gap / 2; y < size.height; y += gap) {
      for (double x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), r, p);
      }
    }
  }

  @override
  bool shouldRepaint(DotsPainter o) => o.color != color || o.gap != gap;
}

class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({this.color = C.line, this.radius = 20, this.dash = 7, this.gap = 6, this.width = 2});
  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius((Offset.zero & size).deflate(width / 2), Radius.circular(radius));
    final path = Path()..addRRect(rect);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + dash, m.length)), p);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter o) => o.color != color || o.radius != radius;
}

// ───────── toasts ─────────
class ToastData {
  ToastData(this.id, this.title, this.body, this.icon, this.bg);
  final int id;
  final String title;
  final String? body;
  final IconData? icon;
  final Color bg;
}

class Toasts {
  Toasts._();
  static final ValueNotifier<List<ToastData>> items = ValueNotifier<List<ToastData>>(const []);
  static int _id = 0;

  static void show(String title, {String? body, IconData? icon, Color bg = C.ink}) {
    final t = ToastData(++_id, title, body, icon, bg);
    final l = [...items.value, t];
    items.value = l.length > 3 ? l.sublist(l.length - 3) : l;
    Timer(const Duration(milliseconds: 2600), () {
      items.value = [for (final x in items.value) if (x.id != t.id) x];
    });
  }

  static void clear() => items.value = const [];
}

class ToastHost extends StatelessWidget {
  const ToastHost({super.key});
  @override
  Widget build(BuildContext context) => Positioned(
        top: Insets.topOf(context) + 8,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: ValueListenableBuilder<List<ToastData>>(
            valueListenable: Toasts.items,
            builder: (c, list, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [for (final t in list) _ToastView(key: ValueKey(t.id), t: t)],
            ),
          ),
        ),
      );
}

class _ToastView extends StatelessWidget {
  const _ToastView({super.key, required this.t});
  final ToastData t;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 380),
        curve: kEase,
        builder: (c, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, -18 * (1 - v)), child: child)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(16), boxShadow: kPopShadow),
                child: Row(
                  children: [
                    if (t.icon != null) ...[
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(12)),
                        child: Icon(t.icon, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.title, style: tDisplay(15, color: Colors.white, height: 1.15)),
                          if (t.body != null) Text(t.body!, style: tUi(14, color: const Color(0xD9FFFFFF), height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// ───────── confetti ─────────
class ConfettiShot {
  const ConfettiShot(this.x, this.y, this.count, this.spread);
  final double x;
  final double y;
  final int count;
  final double spread;
}

class Confetti {
  Confetti._();
  static final StreamController<ConfettiShot> _c = StreamController<ConfettiShot>.broadcast();
  static Stream<ConfettiShot> get stream => _c.stream;
  static void fire({double x = 0.5, double y = 0.35, int count = 120, double spread = 1}) => _c.add(ConfettiShot(x, y, count, spread));
}

const _confettiColors = [Color(0xFFFF4D7E), Color(0xFFFFC23D), Color(0xFF2FCCAA), Color(0xFF4AA3FF), Color(0xFF8C7CFF), Color(0xFF86CF4E), Color(0xFFFF8FCF)];

class _Bit {
  _Bit(this.x, this.y, this.vx, this.vy, this.rot, this.vr, this.s, this.c, this.shape, this.life);
  double x;
  double y;
  double vx;
  double vy;
  double rot;
  final double vr;
  final double s;
  final Color c;
  final int shape;
  double life;
}

class ConfettiLayer extends StatefulWidget {
  const ConfettiLayer({super.key});
  @override
  State<ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<ConfettiLayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final List<_Bit> _bits = [];
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  final _r = math.Random();
  StreamSubscription<ConfettiShot>? _sub;
  Size _size = Size.zero;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sub = Confetti.stream.listen(_fire);
  }

  void _fire(ConfettiShot s) {
    if (!mounted) return;
    if (readStore(context).state.profile.reducedMotion) return;
    final w = _size.width;
    final h = _size.height;
    if (w == 0 || h == 0) return;
    for (var i = 0; i < s.count; i++) {
      final a = _r.nextDouble() * math.pi * 2;
      final v = (3 + _r.nextDouble() * 6) * s.spread;
      _bits.add(_Bit(s.x * w, s.y * h, math.cos(a) * v, math.sin(a) * v - 4.5, _r.nextDouble() * 6, (_r.nextDouble() - 0.5) * 0.3, 2.5 + _r.nextDouble() * 3.5,
          _confettiColors[i % _confettiColors.length], i % 3, 90 + _r.nextDouble() * 50));
    }
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final double dt = _last == Duration.zero ? 1.0 : ((elapsed - _last).inMicroseconds / 16667).clamp(0.5, 3.0).toDouble();
    _last = elapsed;
    for (final p in _bits) {
      p.vy += 0.16 * dt;
      p.vx *= math.pow(0.99, dt).toDouble();
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rot += p.vr * dt;
      p.life -= dt;
    }
    _bits.removeWhere((p) => p.life <= 0);
    _frame.value++;
    if (_bits.isEmpty) _ticker.stop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: LayoutBuilder(builder: (c, box) {
            _size = box.biggest;
            return CustomPaint(size: box.biggest, painter: _ConfettiPainter(_bits, _frame));
          }),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, Listenable repaint) : super(repaint: repaint);
  final List<_Bit> bits;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in bits) {
      final paint = Paint()..color = p.c.withValues(alpha: math.min(1.0, p.life / 30));
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      if (p.shape == 0) {
        canvas.drawRect(Rect.fromLTWH(-p.s, -p.s / 2, p.s * 2, p.s), paint);
      } else if (p.shape == 1) {
        canvas.drawCircle(Offset.zero, p.s * 0.8, paint);
      } else {
        final path = Path();
        for (var i = 0; i < 4; i++) {
          final a = (i / 4) * math.pi * 2;
          final o1 = Offset(math.cos(a) * p.s * 1.4, math.sin(a) * p.s * 1.4);
          final o2 = Offset(math.cos(a + math.pi / 4) * p.s * 0.5, math.sin(a + math.pi / 4) * p.s * 0.5);
          if (i == 0) {
            path.moveTo(o1.dx, o1.dy);
          } else {
            path.lineTo(o1.dx, o1.dy);
          }
          path.lineTo(o2.dx, o2.dy);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => true;
}

// ───────── XP floats ─────────
class XpFloats extends StatefulWidget {
  const XpFloats({super.key});
  @override
  State<XpFloats> createState() => _XpFloatsState();
}

class _XpFloatsState extends State<XpFloats> {
  StreamSubscription<NimbusEvent>? _sub;
  final List<(int, int)> _items = [];
  int _n = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub ??= readStore(context).events.listen((e) {
      if (e.type != EvType.xp || !mounted) return;
      final id = ++_n;
      setState(() => _items.add((id, e.amount)));
      Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _items.removeWhere((x) => x.$1 == id));
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
        top: Insets.topOf(context) + 56,
        right: 16,
        child: IgnorePointer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [for (final x in _items) _XpPill(key: ValueKey(x.$1), amount: x.$2)],
          ),
        ),
      );
}

class _XpPill extends StatelessWidget {
  const _XpPill({super.key, required this.amount});
  final int amount;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1600),
        builder: (c, t, child) {
          final double inT = (t / 0.25).clamp(0.0, 1.0).toDouble();
          final double outT = t > 0.75 ? (t - 0.75) / 0.25 : 0.0;
          final double e = kEase.transform(inT);
          return Opacity(
            opacity: (e * (1 - outT)).clamp(0.0, 1.0).toDouble(),
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - e) - 24 * outT),
              child: Transform.scale(scale: 0.8 + 0.2 * e, child: child),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.butter,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: C.ink, width: 2),
            boxShadow: kPopShadow,
          ),
          child: Text('+$amount XP', style: tDisplay(15, weight: FontWeight.w700)),
        ),
      );
}
