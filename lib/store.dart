import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/flashcards.dart';
import 'data/path.dart';
import 'data/services.dart';
import 'sound.dart';

const kStoreKey = 'nimbus.v1';
const kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

// ───────── dates ─────────
String _p2(int v) => v.toString().padLeft(2, '0');

String dayKey([DateTime? d]) {
  final x = d ?? DateTime.now();
  return '${x.year}-${_p2(x.month)}-${_p2(x.day)}';
}

DateTime parseDay(String k) {
  final p = k.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String addDays(String key, int n) {
  final d = parseDay(key);
  return dayKey(DateTime(d.year, d.month, d.day + n));
}

int diffDays(String a, String b) => (parseDay(b).difference(parseDay(a)).inHours / 24).round();

String shortDate(String key) {
  final d = parseDay(key);
  return '${d.day} ${kMonths[d.month - 1]}';
}

bool isNight([DateTime? at]) {
  final h = (at ?? DateTime.now()).hour;
  return h >= 20 || h < 5;
}

// ───────── levels, stamps, hero flow ─────────
class Level {
  const Level(this.n, this.name, this.at);
  final int n;
  final String name;
  final int at;
}

const kLevels = [
  Level(1, 'Mist', 0),
  Level(2, 'Wisp', 150),
  Level(3, 'Stratus', 400),
  Level(4, 'Cumulus', 800),
  Level(5, 'Nimbus', 1300),
  Level(6, 'Cirrus', 2000),
  Level(7, 'Jet Stream', 3000),
  Level(8, 'Stratosphere', 4500),
];

class LevelInfo {
  const LevelInfo(this.cur, this.next, this.pct);
  final Level cur;
  final Level? next;
  final double pct;
}

LevelInfo levelFor(int xp) {
  var cur = kLevels.first;
  for (final l in kLevels) {
    if (xp >= l.at) cur = l;
  }
  Level? next;
  for (final l in kLevels) {
    if (l.at > xp) {
      next = l;
      break;
    }
  }
  final double pct = next == null ? 1.0 : (xp - cur.at) / (next.at - cur.at);
  return LevelInfo(cur, next, pct);
}

const Map<String, (String, String)> kStamps = {
  'first-flight': ('First flight', 'Finished a lesson'),
  'first-pack': ('Pack popper', 'Opened a Sky Pack'),
  'week-streak': ('7-day sky', 'A week in a row'),
  'holo-1': ('Holo hunter', 'First holo card'),
  'perfect': ('Flawless', 'Perfect quiz'),
  'architect': ('Architect', 'Passed a Lab'),
  'chaos': ('Chaos tamer', 'Survived an outage'),
  'night-owl': ('Night owl', 'Studied after 10 PM'),
  'curious': ('Curious cloud', 'Asked Puff'),
  'reviewer': ('Memory palace', 'Cleared reviews'),
  'cinephile': ('Cinephile', 'Watched Cloud Cinema'),
  'collector': ('Collector', '10 Cloudlings'),
};

const List<(String, String)> kHeroSteps = [
  ('onboard', 'Meet Puff and set a goal'),
  ('pack', "Open today's Sky Pack"),
  ('book', "Read Bucky's S3 Pocket Book"),
  ('quiz', 'Take the S3 quiz'),
  ('lab', 'Build "Results day" in the Lab'),
  ('ask', 'Ask Puff a question'),
  ('album', 'Find Bucky in the Cloudex'),
];

String svcLevelLabel(int lvl) => lvl == 2 ? 'Holo' : lvl == 1 ? 'Learned' : 'New';

// ───────── json helpers ─────────
Map<String, dynamic> _m(Object? x) => x is Map ? Map<String, dynamic>.from(x) : <String, dynamic>{};
List<Object?> _l(Object? x) => x is List ? x : const <Object?>[];
int _i(Object? x, [int d = 0]) => x is num ? x.toInt() : d;
double _d(Object? x, [double d = 0.0]) => x is num ? x.toDouble() : d;
String? _s(Object? x) => x is String ? x : null;
bool _b(Object? x, [bool d = false]) => x is bool ? x : d;
Map<String, int> _mi(Object? x) => _m(x).map((k, v) => MapEntry(k, _i(v)));
Map<String, String> _ms(Object? x) => _m(x).map((k, v) => MapEntry(k, '$v'));

// ───────── models ─────────
class Profile {
  Profile({this.name = 'Koushi', this.goal = 'clf', this.minutes = 10, this.sound = true, this.reducedMotion = false});
  String name;
  String goal;
  int minutes;
  bool sound;
  bool reducedMotion;

  Map<String, dynamic> toJson() => {'name': name, 'goal': goal, 'minutes': minutes, 'sound': sound, 'reducedMotion': reducedMotion};

  static Profile fromJson(Object? o) {
    final j = _m(o);
    return Profile(
      name: _s(j['name']) ?? 'Koushi',
      goal: _s(j['goal']) ?? 'clf',
      minutes: _i(j['minutes'], 10),
      sound: _b(j['sound'], true),
      reducedMotion: _b(j['reducedMotion']),
    );
  }
}

class Collected {
  Collected(this.level, this.at);
  int level;
  String at;
  Map<String, dynamic> toJson() => {'level': level, 'at': at};
  static Collected fromJson(Object? o) {
    final j = _m(o);
    return Collected(_i(j['level']), _s(j['at']) ?? dayKey());
  }
}

class Srs {
  Srs(this.box, this.due, [this.again = 0]);
  int box;
  String due;
  int again;
  Map<String, dynamic> toJson() => {'box': box, 'due': due, 'again': again};
  static Srs fromJson(Object? o) {
    final j = _m(o);
    return Srs(_i(j['box']), _s(j['due']) ?? dayKey(), _i(j['again']));
  }
}

class LabRec {
  LabRec(this.best, this.runs, this.survived);
  int best;
  int runs;
  bool survived;
  Map<String, dynamic> toJson() => {'best': best, 'runs': runs, 'survived': survived};
  static LabRec fromJson(Object? o) {
    final j = _m(o);
    return LabRec(_i(j['best']), _i(j['runs']), _b(j['survived']));
  }
}

class PackState {
  PackState({this.opened, this.bonus = 0, this.last});
  String? opened;
  int bonus;
  String? last;
  Map<String, dynamic> toJson() => {'opened': opened, 'bonus': bonus, 'last': last};
  static PackState fromJson(Object? o) {
    final j = _m(o);
    return PackState(opened: _s(j['opened']), bonus: _i(j['bonus']), last: _s(j['last']));
  }
}

class TodayStat {
  TodayStat(this.date, this.xp, this.minutes);
  String date;
  int xp;
  double minutes;
  Map<String, dynamic> toJson() => {'date': date, 'xp': xp, 'minutes': minutes};
  static TodayStat fromJson(Object? o) {
    final j = _m(o);
    return TodayStat(_s(j['date']) ?? dayKey(), _i(j['xp']), _d(j['minutes']));
  }
}

class Stats {
  Stats(this.answered, this.correct, this.reviews);
  int answered;
  int correct;
  int reviews;
  Map<String, dynamic> toJson() => {'answered': answered, 'correct': correct, 'reviews': reviews};
  static Stats fromJson(Object? o) {
    final j = _m(o);
    return Stats(_i(j['answered']), _i(j['correct']), _i(j['reviews']));
  }
}

class MemItem {
  MemItem(this.id, this.kind, this.value, this.text);
  final String id;
  final String kind;
  final String value;
  final String text;
  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'value': value, 'text': text};
  static MemItem fromJson(Object? o) {
    final j = _m(o);
    return MemItem(_s(j['id']) ?? 'mem', _s(j['kind']) ?? 'note', _s(j['value']) ?? '', _s(j['text']) ?? '');
  }
}

class ChatMsg {
  ChatMsg({
    required this.id,
    required this.role,
    required this.at,
    this.text,
    this.status = 'done',
    List<String>? steps,
    this.stepAt = 0,
    List<Map<String, dynamic>>? blocks,
    List<String>? chips,
    this.mood = 'happy',
    this.intent,
    Map<String, int>? answers,
  })  : steps = steps ?? <String>[],
        blocks = blocks ?? <Map<String, dynamic>>[],
        chips = chips ?? <String>[],
        answers = answers ?? <String, int>{};

  final String id;
  final String role;
  final int at;
  String? text;
  String status;
  List<String> steps;
  int stepAt;
  List<Map<String, dynamic>> blocks;
  List<String> chips;
  String mood;
  String? intent;
  Map<String, int> answers;

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'at': at,
        'text': text,
        'status': status,
        'steps': steps,
        'stepAt': stepAt,
        'blocks': blocks,
        'chips': chips,
        'mood': mood,
        'intent': intent,
        'answers': answers,
      };

  static ChatMsg fromJson(Object? o) {
    final j = _m(o);
    return ChatMsg(
      id: _s(j['id']) ?? 'm${DateTime.now().microsecondsSinceEpoch}',
      role: _s(j['role']) ?? 'puff',
      at: _i(j['at']),
      text: _s(j['text']),
      status: _s(j['status']) ?? 'done',
      steps: [for (final s in _l(j['steps'])) '$s'],
      stepAt: _i(j['stepAt']),
      blocks: [for (final b in _l(j['blocks'])) _m(b)],
      chips: [for (final c in _l(j['chips'])) '$c'],
      mood: _s(j['mood']) ?? 'happy',
      intent: _s(j['intent']),
      answers: _mi(j['answers']),
    );
  }
}

class AppState {
  AppState({
    required this.onboarded,
    required this.profile,
    required this.xp,
    required this.streak,
    required this.lastActive,
    required this.activity,
    required this.today,
    required this.collected,
    required this.favorites,
    required this.done,
    required this.bookPos,
    required this.quizBest,
    required this.pack,
    required this.srs,
    required this.lab,
    required this.cinema,
    required this.chat,
    required this.memory,
    required this.stamps,
    required this.stats,
    required this.hero,
  });

  bool onboarded;
  Profile profile;
  int xp;
  int streak;
  String? lastActive;
  Map<String, int> activity;
  TodayStat today;
  Map<String, Collected> collected;
  List<String> favorites;
  Map<String, String> done;
  Map<String, int> bookPos;
  Map<String, int> quizBest;
  PackState pack;
  Map<String, Srs> srs;
  Map<String, LabRec> lab;
  Map<String, bool> cinema;
  List<ChatMsg> chat;
  List<MemItem> memory;
  Map<String, String> stamps;
  Stats stats;
  Map<String, int> hero;

  String get displayName => memoryValue('name') ?? profile.name;

  String? memoryValue(String kind) {
    for (final m in memory) {
      if (m.kind == kind) return m.value;
    }
    return null;
  }

  bool get packAvailable => pack.opened != dayKey() || pack.bonus > 0;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'onboarded': onboarded,
        'profile': profile.toJson(),
        'xp': xp,
        'streak': streak,
        'lastActive': lastActive,
        'activity': activity,
        'today': today.toJson(),
        'collected': collected.map((k, v) => MapEntry(k, v.toJson())),
        'favorites': favorites,
        'done': done,
        'bookPos': bookPos,
        'quizBest': quizBest,
        'pack': pack.toJson(),
        'srs': srs.map((k, v) => MapEntry(k, v.toJson())),
        'lab': lab.map((k, v) => MapEntry(k, v.toJson())),
        'cinema': cinema,
        'chat': [for (final c in chat) c.toJson()],
        'memory': [for (final m in memory) m.toJson()],
        'stamps': stamps,
        'stats': stats.toJson(),
        'hero': hero,
      };

  static AppState fromJson(Map<String, dynamic> j) => AppState(
        onboarded: _b(j['onboarded']),
        profile: Profile.fromJson(j['profile']),
        xp: _i(j['xp']),
        streak: _i(j['streak']),
        lastActive: _s(j['lastActive']),
        activity: _mi(j['activity']),
        today: TodayStat.fromJson(j['today']),
        collected: _m(j['collected']).map((k, v) => MapEntry(k, Collected.fromJson(v))),
        favorites: [for (final f in _l(j['favorites'])) '$f'],
        done: _ms(j['done']),
        bookPos: _mi(j['bookPos']),
        quizBest: _mi(j['quizBest']),
        pack: PackState.fromJson(j['pack']),
        srs: _m(j['srs']).map((k, v) => MapEntry(k, Srs.fromJson(v))),
        lab: _m(j['lab']).map((k, v) => MapEntry(k, LabRec.fromJson(v))),
        cinema: _m(j['cinema']).map((k, v) => MapEntry(k, v == true)),
        chat: [for (final c in _l(j['chat'])) ChatMsg.fromJson(c)],
        memory: [for (final m in _l(j['memory'])) MemItem.fromJson(m)],
        stamps: _ms(j['stamps']),
        stats: Stats.fromJson(j['stats']),
        hero: _mi(j['hero']),
      );

  /// Day-one demo state: 11-day streak, 6 Cloudlings, 10 lessons done, 6 cards due.
  static AppState seed() {
    final today = dayKey();
    final activity = <String, int>{};
    for (var i = 1; i <= 70; i++) {
      final k = addDays(today, -i);
      final v = ((math.sin(i * 12.9898) * 43758.5453) % 1).abs();
      if (i <= 11) {
        activity[k] = 20 + (v * 70).round();
      } else if (i == 12) {
        activity[k] = 0;
      } else if (v > 0.38) {
        activity[k] = 10 + (v * 60).round();
      }
    }
    const levels = {'iam': 2, 'kms': 1, 'ec2': 2, 'lambda': 1, 'route53': 0, 'cloudwatch': 0};
    final collected = <String, Collected>{};
    var n = 0;
    levels.forEach((id, level) {
      collected[id] = Collected(level, addDays(today, -10 + n * 2));
      n++;
    });
    final srs = <String, Srs>{};
    var dueCount = 0;
    for (var i = 0; i < kFlash.length; i++) {
      final f = kFlash[i];
      if (f.svc != null && !collected.containsKey(f.svc)) continue;
      final isDue = dueCount < 6 && i % 2 == 0;
      if (isDue) dueCount++;
      srs[f.id] = Srs(isDue ? 1 : 2, isDue ? today : addDays(today, 1 + (i % 4)));
    }
    final done = <String, String>{};
    for (final id in ['c101-1', 'c101-2', 'c101-3', 'c101-4', 'gi-1', 'gi-2', 'iam', 'kms', 'ec2', 'lambda']) {
      done[id] = addDays(today, -10);
    }
    return AppState(
      onboarded: false,
      profile: Profile(),
      xp: 1240,
      streak: 11,
      lastActive: addDays(today, -1),
      activity: activity,
      today: TodayStat(today, 0, 0),
      collected: collected,
      favorites: ['lambda'],
      done: done,
      bookPos: <String, int>{},
      quizBest: {'iam': 3, 'ec2': 3, 'lambda': 2, 'kms': 2},
      pack: PackState(),
      srs: srs,
      lab: <String, LabRec>{},
      cinema: {'regions': true},
      chat: <ChatMsg>[],
      memory: <MemItem>[],
      stamps: {
        'first-flight': addDays(today, -11),
        'first-pack': addDays(today, -10),
        'week-streak': addDays(today, -4),
        'holo-1': addDays(today, -6),
      },
      stats: Stats(46, 37, 58),
      hero: <String, int>{},
    );
  }
}

// ───────── events ─────────
enum EvType { xp, streak, levelUp, stamp }

class NimbusEvent {
  const NimbusEvent(this.type, {this.amount = 0, this.level, this.id});
  final EvType type;
  final int amount;
  final Level? level;
  final String? id;
}

// ───────── store ─────────
class Store extends ChangeNotifier {
  Store(this._prefs) : state = _load(_prefs) {
    Sfx.enabled = state.profile.sound;
  }

  final SharedPreferences? _prefs;
  AppState state;
  final ValueNotifier<String> tab = ValueNotifier<String>('today');
  final StreamController<NimbusEvent> _events = StreamController<NimbusEvent>.broadcast();
  Stream<NimbusEvent> get events => _events.stream;
  Timer? _saveTimer;

  static AppState _load(SharedPreferences? prefs) {
    try {
      final raw = prefs?.getString(kStoreKey);
      if (raw == null) return AppState.seed();
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['v'] != 1) return AppState.seed();
      final s = AppState.fromJson(Map<String, dynamic>.from(decoded));
      final today = dayKey();
      if (s.today.date != today) {
        s.today = TodayStat(today, 0, 0);
        final last = s.lastActive;
        if (last != null && diffDays(last, today) > 1) s.streak = 0;
      }
      return s;
    } catch (_) {
      return AppState.seed();
    }
  }

  void _commit() {
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), _save);
  }

  void _save() {
    try {
      _prefs?.setString(kStoreKey, jsonEncode(state.toJson()));
    } catch (_) {
      // storage full or blocked: keep going in memory
    }
  }

  void _emit(NimbusEvent e) {
    scheduleMicrotask(() {
      if (!_events.isClosed) _events.add(e);
    });
  }

  String get _now => '${DateTime.now().microsecondsSinceEpoch}';

  void addXP(int amount, [double minutes = 0]) {
    final s = state;
    final today = dayKey();
    if (s.lastActive != today) {
      final last = s.lastActive;
      s.streak = (last != null && diffDays(last, today) == 1) ? s.streak + 1 : 1;
      s.lastActive = today;
      _emit(NimbusEvent(EvType.streak, amount: s.streak));
    }
    final before = levelFor(s.xp).cur.n;
    s.xp += amount;
    final after = levelFor(s.xp).cur;
    if (after.n > before) _emit(NimbusEvent(EvType.levelUp, level: after));
    if (DateTime.now().hour >= 22 && !s.stamps.containsKey('night-owl')) {
      s.stamps['night-owl'] = today;
      _emit(const NimbusEvent(EvType.stamp, id: 'night-owl'));
    }
    if (s.streak >= 7 && !s.stamps.containsKey('week-streak')) s.stamps['week-streak'] = today;
    if (s.today.date != today) s.today = TodayStat(today, 0, 0);
    s.today.xp += amount;
    s.today.minutes = ((s.today.minutes + minutes) * 10).round() / 10;
    s.activity[today] = (s.activity[today] ?? 0) + amount;
    if (amount > 0) _emit(NimbusEvent(EvType.xp, amount: amount));
    _commit();
  }

  void hero(String id) {
    if (state.hero.containsKey(id)) return;
    state.hero[id] = DateTime.now().millisecondsSinceEpoch;
    _commit();
  }

  void stamp(String id) {
    if (state.stamps.containsKey(id)) return;
    state.stamps[id] = dayKey();
    _emit(NimbusEvent(EvType.stamp, id: id));
    _commit();
  }

  void completeOnboarding({required String goal, required int minutes, required String name}) {
    state.onboarded = true;
    state.profile
      ..goal = goal
      ..minutes = minutes
      ..name = name;
    state.hero['onboard'] = DateTime.now().millisecondsSinceEpoch;
    _commit();
  }

  void setProfile({String? name, String? goal, int? minutes, bool? sound, bool? reducedMotion}) {
    final p = state.profile;
    if (name != null) p.name = name;
    if (goal != null) p.goal = goal;
    if (minutes != null) p.minutes = minutes;
    if (sound != null) p.sound = sound;
    if (reducedMotion != null) p.reducedMotion = reducedMotion;
    Sfx.enabled = p.sound;
    _commit();
  }

  void collect(String id, [int level = 0]) {
    final s = state;
    final today = dayKey();
    final cur = s.collected[id];
    s.collected[id] = Collected(math.max(level, cur?.level ?? 0), cur?.at ?? today);
    for (final f in kFlash) {
      if (f.svc == id && !s.srs.containsKey(f.id)) s.srs[f.id] = Srs(0, addDays(today, 1));
    }
    if (s.collected.length >= 10 && !s.stamps.containsKey('collector')) s.stamps['collector'] = today;
    if (level >= 2 && !s.stamps.containsKey('holo-1')) s.stamps['holo-1'] = today;
    _commit();
  }

  /// Opens today's pack (or a bonus pack). Returns the Cloudling id, or null if none left.
  String? openPack() {
    final s = state;
    final today = dayKey();
    final fromDaily = s.pack.opened != today;
    if (!fromDaily && s.pack.bonus <= 0) return null;
    final missing = [for (final x in kServices) if (!s.collected.containsKey(x.id)) x.id];
    final rnd = math.Random();
    final String got;
    if (fromDaily && !s.collected.containsKey('s3')) {
      got = 's3';
    } else if (missing.isNotEmpty) {
      got = missing[rnd.nextInt(missing.length)];
    } else {
      got = kServices[rnd.nextInt(kServices.length)].id;
    }
    if (fromDaily) {
      s.pack.opened = today;
    } else {
      s.pack.bonus = math.max(0, s.pack.bonus - 1);
    }
    s.pack.last = got;
    _commit();
    return got;
  }

  void grantBonusPack() {
    state.pack.bonus += 1;
    _commit();
  }

  void markLesson(String id) {
    if (state.done.containsKey(id)) return;
    state.done[id] = dayKey();
    state.stamps.putIfAbsent('first-flight', () => dayKey());
    _commit();
  }

  void setBookPos(String ref, int i) {
    state.bookPos[ref] = i;
    _commit();
  }

  void recordQuiz(String key, int correct, int total) {
    final s = state;
    s.quizBest[key] = math.max(correct, s.quizBest[key] ?? 0);
    s.stats.answered += total;
    s.stats.correct += correct;
    _commit();
  }

  void reviewCard(String id, String grade) {
    final s = state;
    final cur = s.srs[id] ?? Srs(0, dayKey());
    final last = kBoxDays.length - 1;
    final box = grade == 'again'
        ? 0
        : grade == 'easy'
            ? math.min(cur.box + 2, last)
            : math.min(cur.box + 1, last);
    final due = addDays(dayKey(), grade == 'again' ? 0 : math.max(1, kBoxDays[box]));
    s.srs[id] = Srs(box, due, grade == 'again' ? cur.again + 1 : 0);
    s.stats.reviews += 1;
    _commit();
  }

  void saveLab(String id, int score, bool survived) {
    final prev = state.lab[id];
    state.lab[id] = LabRec(math.max(score, prev?.best ?? 0), (prev?.runs ?? 0) + 1, survived || (prev?.survived ?? false));
    _commit();
  }

  void markCinema(String id) {
    state.cinema[id] = true;
    _commit();
  }

  void pushChat(ChatMsg m) {
    state.chat.add(m);
    if (state.chat.length > 80) state.chat.removeRange(0, state.chat.length - 80);
    _commit();
  }

  void patchChat(String id, void Function(ChatMsg m) change) {
    for (final m in state.chat) {
      if (m.id == id) {
        change(m);
        _commit();
        return;
      }
    }
  }

  void clearChat() {
    state.chat.clear();
    _commit();
  }

  void remember(String kind, String value, String text) {
    if (kind != 'note') state.memory.removeWhere((m) => m.kind == kind);
    state.memory.add(MemItem('mem$_now', kind, value, text));
    _commit();
  }

  void forget(String id) {
    state.memory.removeWhere((m) => m.id == id);
    _commit();
  }

  void forgetAll() {
    state.memory.clear();
    _commit();
  }

  void toggleFav(String id) {
    final f = state.favorites;
    if (f.contains(id)) {
      f.remove(id);
    } else {
      f.add(id);
    }
    _commit();
  }

  void reset() {
    try {
      _prefs?.remove(kStoreKey);
    } catch (_) {}
    state = AppState.seed();
    Sfx.enabled = state.profile.sound;
    tab.value = 'today';
    _commit();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _events.close();
    tab.dispose();
    super.dispose();
  }
}

// ───────── provider ─────────
class StoreScope extends InheritedNotifier<Store> {
  const StoreScope({super.key, required Store store, required super.child}) : super(notifier: store);

  static Store watchOf(BuildContext c) => c.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
  static Store readOf(BuildContext c) => c.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

/// Rebuilds when the store changes.
Store watch(BuildContext c) => StoreScope.watchOf(c);

/// Reads without listening (callbacks, initState).
Store readStore(BuildContext c) => StoreScope.readOf(c);

bool reduceMotion(BuildContext c) => watch(c).state.profile.reducedMotion || MediaQuery.of(c).disableAnimations;

// ───────── derived ─────────
List<Flash> dueCards(AppState s) {
  final today = dayKey();
  return [
    for (final f in kFlash)
      if (s.srs[f.id] != null && s.srs[f.id]!.due.compareTo(today) <= 0) f,
  ];
}

Lesson? currentLesson(AppState s) {
  for (final l in kLessons) {
    if (!s.done.containsKey(l.id)) return l;
  }
  return null;
}

/// Blend of collected Cloudlings, finished concept lessons and quiz accuracy per exam domain.
Map<String, int> readiness(AppState s) {
  final doms = <String, List<double>>{'cloud': [], 'security': [], 'tech': [], 'billing': []};
  for (final svc in kServices) {
    final c = s.collected[svc.id];
    final double v = c == null ? 0.0 : c.level == 2 ? 1.0 : c.level == 1 ? 0.7 : 0.3;
    doms[svc.domain]!.add(v);
    if (svc.id == 'ec2' || svc.id == 'lambda' || svc.id == 'dynamodb') doms['billing']!.add(v * 0.8);
  }
  final conceptDone = ['c101-1', 'c101-2', 'c101-3', 'gi-1', 'gi-2', 'wa-1'].where((id) => s.done.containsKey(id)).length / 6;
  doms['cloud']!.addAll([conceptDone, conceptDone, conceptDone]);
  doms['security']!.add(s.done.containsKey('c101-4') ? 1.0 : 0.0);
  final double acc = s.stats.answered > 0 ? s.stats.correct / s.stats.answered : 0.0;
  final out = <String, int>{};
  doms.forEach((k, arr) {
    final double avg = arr.isEmpty ? 0.0 : arr.reduce((a, b) => a + b) / arr.length;
    final double blended = avg * 0.8 + (avg > 0 ? acc * 0.2 : 0.0);
    out[k] = (math.min(1.0, blended) * 100).round();
  });
  return out;
}
