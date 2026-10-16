import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/book.dart';
import 'screens/card_detail.dart';
import 'screens/chat.dart';
import 'screens/cinema.dart';
import 'screens/lab.dart';
import 'screens/level_up.dart';
import 'screens/me.dart';
import 'screens/pack_open.dart';
import 'screens/quiz.dart';
import 'screens/review.dart';
import 'store.dart';
import 'theme.dart';

/// Navigation model: tabs (in the store) + a stack of pushed screens + overlays,
/// all living inside the phone frame's own Navigator.
class Nav {
  Nav._();
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
  static final ValueNotifier<List<String>> stack = ValueNotifier<List<String>>(const ['root']);
  static final NavObserver observer = NavObserver();
  static NavigatorState? get _nav => key.currentState;

  static const _fromBottom = {'chat', 'quiz', 'cinema', 'review'};

  static void push(String screen, [Map<String, dynamic> p = const {}]) {
    _nav?.push(_route(screen, p));
  }

  static void replace(String screen, [Map<String, dynamic> p = const {}]) {
    _nav?.pushReplacement(_route(screen, p));
  }

  static void pop() {
    _nav?.maybePop();
  }

  static void popAll() {
    _nav?.popUntil((r) => r.isFirst);
  }

  static void overlay(String type, {String? id}) {
    _nav?.push(_overlay(type, id: id));
  }

  static void levelUp(Level level) {
    _nav?.push(_overlay('levelup', level: level));
  }

  static void tab(Store store, String t) {
    popAll();
    store.tab.value = t;
  }

  static void reset() {
    observer.reset();
  }

  static Route<void> _route(String screen, Map<String, dynamic> p) {
    final up = _fromBottom.contains(screen);
    final Widget page;
    switch (screen) {
      case 'book':
        page = BookScreen(bookId: p['bookId'] as String? ?? 's3', lessonId: p['lessonId'] as String?);
      case 'quiz':
        page = QuizScreen(svc: p['svc'] as String?, mode: p['mode'] as String?, lessonId: p['lessonId'] as String?);
      case 'labBuild':
        page = LabBuildScreen(id: p['id'] as String? ?? 'results-day');
      case 'review':
        page = const ReviewScreen();
      case 'cinema':
        page = CinemaScreen(id: p['id'] as String? ?? 'regions', lessonId: p['lessonId'] as String?);
      case 'chat':
        page = ChatScreen(prefill: p['prefill'] as String?);
      case 'me':
        page = const MeScreen();
      default:
        page = const SizedBox.shrink();
    }
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: screen),
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, a, b) => page,
      transitionsBuilder: (context, a, b, child) {
        final curved = CurvedAnimation(parent: a, curve: kEase, reverseCurve: Curves.easeInCubic);
        final begin = up ? const Offset(0, 1) : const Offset(1, 0);
        return SlideTransition(position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved), child: child);
      },
    );
  }

  static Route<void> _overlay(String type, {String? id, Level? level}) {
    final Widget page;
    if (type == 'pack') {
      page = const PackOpenScreen();
    } else if (type == 'levelup') {
      page = LevelUpScreen(level: level ?? kLevels.first);
    } else {
      page = CardDetailScreen(id: id ?? 's3');
    }
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: type),
      opaque: false,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, a, b) => page,
      transitionsBuilder: (context, a, b, child) => FadeTransition(opacity: a, child: child),
    );
  }
}

/// Tracks route names so the fake status bar and the checklist know what's on top.
class NavObserver extends NavigatorObserver {
  final List<String> _names = [];

  void _sync() {
    final snapshot = List<String>.unmodifiable(_names);
    scheduleMicrotask(() => Nav.stack.value = snapshot);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name ?? 'route';
    if (name == 'root') _names.clear();
    _names.add(name);
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_names.isNotEmpty) _names.removeLast();
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final i = _names.lastIndexOf(route.settings.name ?? 'route');
    if (i >= 0) _names.removeAt(i);
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = _names.lastIndexOf(oldRoute?.settings.name ?? 'route');
    if (i >= 0) _names[i] = newRoute?.settings.name ?? 'route';
    _sync();
  }

  void reset() {
    _names.clear();
    _sync();
  }
}
