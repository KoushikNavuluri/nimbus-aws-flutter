// Puff's brain: a small, local, rule-based tutor. No network, no model.
// respond(text, state) -> AiReply { intent, text, blocks, chips, mood, steps, memory?, action? }
import 'dart:math' as math;

import 'data/lab.dart';
import 'data/path.dart';
import 'data/quiz.dart';
import 'data/services.dart';
import 'store.dart';
import 'theme.dart' show fmtIN;

class AiReply {
  AiReply({
    required this.intent,
    required this.text,
    this.blocks = const [],
    this.chips = const [],
    this.mood = 'happy',
    this.steps = const [],
    this.memory,
    this.action,
  });
  final String intent;
  final String text;
  final List<Map<String, dynamic>> blocks;
  final List<String> chips;
  final String mood;
  final List<String> steps;
  final Map<String, String>? memory;
  final Map<String, dynamic>? action;
}

const kStarters = ['What should I study next?', 'SQS vs SNS?', 'How much is 100 GB on S3?', 'Quiz me', 'Remember my exam is on Dec 12'];

final _rnd = math.Random();

String money(double usd) {
  if (usd < 0.01) return r'<$0.01';
  final v = usd < 10 ? usd.toStringAsFixed(2) : fmtIN(usd.round());
  return '\$$v';
}

String rupees(double usd) => '₹${fmtIN((usd * kInr).round())}';

String _num(double v) => v == v.roundToDouble() ? fmtIN(v) : v.toString();

List<String> findServices(String text) {
  final t = ' ${text.toLowerCase()} ';
  final hits = <(String, int)>[];
  kAliases.forEach((id, words) {
    var best = -1;
    for (final w in words) {
      final m = RegExp('(^|[^a-z0-9])${RegExp.escape(w)}(?=[^a-z0-9]|\$)').firstMatch(t);
      if (m != null && (best < 0 || m.start < best)) best = m.start;
    }
    if (best >= 0) hits.add((id, best));
  });
  hits.sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final h in hits) h.$1];
}

class _Cmp {
  const _Cmp(this.order, this.rows);
  final List<String> order;
  final List<List<String>> rows;
}

const Map<String, _Cmp> _compare = {
  'sns|sqs': _Cmp(['sqs', 'sns'], [
    ['Model', 'Queue: consumers pull', 'Pub/sub: pushes out'],
    ['Who gets it', 'One worker per message', 'Every subscriber, a copy each'],
    ['Keeps messages', 'Up to 14 days', 'No, delivers and moves on'],
    ['Reach for it when', 'Buffering spiky work', 'Broadcasting an event'],
  ]),
  'dynamodb|rds': _Cmp(['rds', 'dynamodb'], [
    ['Data model', 'Tables, SQL, joins', 'Key-value and documents'],
    ['Scaling', 'Bigger instance + read replicas', 'Automatic, near limitless'],
    ['You manage', 'Instance size, maintenance window', 'Nothing: serverless'],
    ['Reach for it when', 'Complex queries, transactions', 'Huge scale, simple lookups'],
  ]),
  'ec2|lambda': _Cmp(['ec2', 'lambda'], [
    ['Run time', 'As long as you like', '15 minutes max'],
    ['You manage', 'OS, patches, scaling', 'Just your code'],
    ['Billing', 'Per second while running', 'Per request + per ms'],
    ['Reach for it when', 'Long-running or custom OS', 'Event-driven, spiky work'],
  ]),
  'ebs|s3': _Cmp(['ebs', 's3'], [
    ['Kind', 'Block storage', 'Object storage'],
    ['Access', 'One EC2 instance, one AZ', 'HTTPS from anywhere'],
    ['Size', 'Up to 64 TiB a volume', 'Unlimited'],
    ['Reach for it when', 'OS disks, DBs on EC2', 'Files, backups, websites'],
  ]),
  'cloudtrail|cloudwatch': _Cmp(['cloudtrail', 'cloudwatch'], [
    ['Answers', '"Who did what?"', '"How is it doing?"'],
    ['Data', 'API call history', 'Metrics, logs, alarms'],
    ['Example', 'intern-ravi deleted a bucket', 'CPU at 95% for 10 min'],
  ]),
  'elb|route53': _Cmp(['elb', 'route53'], [
    ['Works at', 'Inside a Region', 'DNS, across the internet'],
    ['Job', 'Spread traffic over servers', 'Pick where users should go'],
    ['Reach for it when', 'Many servers, one endpoint', 'Names, Region failover'],
  ]),
  'apigateway|elb': _Cmp(['apigateway', 'elb'], [
    ['Best for', 'APIs, especially serverless', 'Traffic across servers'],
    ['Extras', 'Auth, throttling, API keys', 'Health checks, path routing'],
    ['Billing', 'Per request', 'Per hour + capacity units'],
  ]),
  'iam|kms': _Cmp(['iam', 'kms'], [
    ['Protects', 'Access: who can do what', 'Data: the encryption keys'],
    ['Lives as', 'Users, roles, JSON policies', 'Keys with key policies'],
    ['Cost', 'Free', r'$1 per key a month'],
  ]),
};

const _sgNacl = [
  ['Works at', 'Instance level', 'Subnet level'],
  ['Memory', 'Stateful: replies auto-allowed', 'Stateless: open both ways'],
  ['Rules', 'Allow only', 'Allow and deny, in number order'],
];

const _monthsLower = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];

DateTime? parseExamDate(String text) {
  final t = text.toLowerCase();
  int? y;
  int? mo;
  int? d;
  final iso = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(t);
  if (iso != null) {
    y = int.parse(iso.group(1)!);
    mo = int.parse(iso.group(2)!) - 1;
    d = int.parse(iso.group(3)!);
  } else {
    final dm = RegExp(r'(\d{1,2})(?:st|nd|rd|th)?\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*').firstMatch(t);
    if (dm != null) {
      d = int.parse(dm.group(1)!);
      mo = _monthsLower.indexOf(dm.group(2)!);
    } else {
      final md = RegExp(r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{1,2})').firstMatch(t);
      if (md != null) {
        d = int.parse(md.group(2)!);
        mo = _monthsLower.indexOf(md.group(1)!);
      }
    }
  }
  if (mo == null || d == null || mo < 0 || d < 1 || d > 31) return null;
  final now = DateTime.now();
  var date = DateTime(y ?? now.year, mo + 1, d);
  if (y == null && date.isBefore(DateTime(now.year, now.month, now.day))) date = DateTime(now.year + 1, mo + 1, d);
  return date;
}

String _nameOf(AppState s) {
  final n = s.memoryValue('name') ?? s.profile.name;
  return n.isEmpty ? 'friend' : n;
}

bool _isShort(AppState s) => s.memory.any((m) => m.kind == 'style' && m.value == 'short');

String _firstSentence(String text) {
  final m = RegExp(r'[.!?]\s').firstMatch(text);
  return m == null ? text : text.substring(0, m.start + 1);
}

String _cap(String v) => v.replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase());

Question pickQuestion(AppState s, [String? svc]) {
  final asked = <String>{
    for (final m in s.chat)
      for (final b in m.blocks)
        if (b['type'] == 'quiz') '${b['qid']}',
  };
  var pool = svc != null
      ? kQuestions.where((q) => q.svc == svc).toList()
      : kQuestions.where((q) => q.svc == null || s.collected.containsKey(q.svc)).toList();
  final fresh = pool.where((q) => !asked.contains(q.id)).toList();
  if (fresh.isNotEmpty) pool = fresh;
  if (svc == null) {
    final weak = pool.where((q) => q.svc != null && (s.quizBest[q.svc] ?? 0) < 3).toList();
    if (weak.isNotEmpty) pool = weak;
  }
  if (pool.isEmpty) return kQuestions.first;
  return pool[_rnd.nextInt(pool.length)];
}

List<Map<String, dynamic>> planFor(AppState s) {
  final items = <Map<String, dynamic>>[];
  if (s.pack.opened != dayKey()) {
    items.add({
      'label': "Open today's Sky Pack",
      'sub': 'One new Cloudling inside',
      'action': {'type': 'pack'},
    });
  }
  final cur = currentLesson(s);
  if (cur != null) {
    items.add({
      'label': 'Continue: ${cur.title}',
      'sub': '${cur.mins} min · +${cur.xp} XP',
      'action': {'type': 'lesson', 'id': cur.id},
    });
  }
  final due = dueCards(s).length;
  if (due > 0) {
    items.add({
      'label': 'Review $due flashcard${due > 1 ? 's' : ''}',
      'sub': 'About ${math.max(1, (due * 0.4).round())} min',
      'action': {'type': 'review'},
    });
  }
  Scenario? lab;
  for (final sc in kScenarios) {
    if ((s.lab[sc.id]?.best ?? 0) < 70) {
      lab = sc;
      break;
    }
  }
  if (lab != null) {
    items.add({
      'label': 'Build "${lab.title}" in the Lab',
      'sub': lab.tag,
      'action': {'type': 'lab', 'id': lab.id},
    });
  }
  return items.take(4).toList();
}

class _Concept {
  const _Concept(this.pattern, this.text, this.lesson);
  final String pattern;
  final String text;
  final String? lesson;
}

const _concepts = <_Concept>[
  _Concept(r'shared responsibility|who secures|security of the cloud',
      'Shared responsibility: AWS secures the cloud itself (buildings, hardware, network, hypervisor). You secure what you put in it: data, IAM, OS patches, firewall rules. More managed service = less on your plate.', 'c101-4'),
  _Concept(r'region|availability zone|\baz\b|\bazs\b',
      'A Region is a geographic area (like Hyderabad, ap-south-2) with at least three Availability Zones. Each AZ is one or more data centers with its own power and networking, linked by fast private fiber. Run in two AZs and one can fail without taking you down.', 'gi-1'),
  _Concept(r'pillar|well.?architected',
      'The Well-Architected Framework has six pillars: operational excellence, security, reliability, performance efficiency, cost optimization and sustainability. Architects trade them off on every design.', 'wa-1'),
  _Concept(r'iaas|paas|saas', 'IaaS gives you raw building blocks (EC2). PaaS runs the platform for you (Elastic Beanstalk). SaaS is the finished app (Gmail). Less to manage as you go up.', 'c101-3'),
  _Concept(r'what is (the )?cloud|cloud computing',
      'Cloud computing is renting IT (servers, storage, databases, apps) over the internet, on demand, paying only for what you use. No buying hardware, no guessing capacity.', 'c101-1'),
  _Concept(r'certif|practitioner|associate|which exam',
      'Start with AWS Certified Cloud Practitioner: broad and friendly. Then Solutions Architect Associate goes deeper on design. Your Skyway follows the Practitioner outline first.', null),
  _Concept(r'edge location|\bcdn\b',
      'Edge locations are 600+ small AWS sites near users. CloudFront caches content there and Route 53 answers DNS from them, which is why things feel fast.', 'gi-2'),
];

AiReply respond(String raw, AppState s) {
  final text = raw.trim();
  final t = text.toLowerCase();
  final name = _nameOf(s);
  final svcs = findServices(t);
  final baseSteps = ['Reading your question', 'Checking your Cloudex (${s.collected.length} cards)', 'Drawing it simply'];
  bool has(String pattern) => RegExp(pattern).hasMatch(t);

  AiReply out(
    String intent,
    String body, {
    List<Map<String, dynamic>> blocks = const [],
    List<String> chips = const [],
    String mood = 'happy',
    List<String>? steps,
    Map<String, String>? memory,
    Map<String, dynamic>? action,
  }) {
    final txt = _isShort(s) && intent != 'safety' ? _firstSentence(body) : body;
    return AiReply(intent: intent, text: txt, blocks: blocks, chips: chips, mood: mood, steps: steps ?? baseSteps, memory: memory, action: action);
  }

  // 1. Safety first
  if (has(r'(kill myself|suicid|self[- ]?harm|want to die|end (my|it all)|hurt myself|no reason to live)')) {
    return out('safety',
        "I'm really glad you told me, $name. I'm only a study cloud, but you deserve a real person right now. In India you can call Tele-MANAS on 14416 (free, any time), or talk to someone you trust. If you're in danger, please call 112.",
        mood: 'soft', steps: ['Listening']);
  }
  // 2. Stress and burnout
  if (has(r"(stress|anxious|anxiety|overwhelm|burn(t|ed) out|give up|i'?ll fail|going to fail|too hard|can'?t do this|so tired|exhausted|scared)")) {
    return out('support',
        "That's a lot, and it's normal. Nobody learns AWS in one sitting. Let's shrink today: one 5-minute win, then rest. Your ${s.streak}-day streak says you're more consistent than you feel.",
        mood: 'soft', steps: ['Listening'], chips: ['Set a 5-min goal', 'Give me one easy win', 'What should I study next?']);
  }
  // 3. Memory
  if (has(r'^(forget (everything|all|it all)|clear (your )?memory)')) {
    return out('forget', 'Done. I wiped what you asked me to remember.', action: {'type': 'forgetAll'}, steps: ['Tidying my notes']);
  }
  final callMe = RegExp(r"call me ([a-z][a-z' -]{0,20})").firstMatch(t);
  if (callMe != null) {
    final v = _cap(callMe.group(1)!.trim());
    return out('memory', "Got it, $v. I'll use that from now on.", memory: {'kind': 'name', 'value': v, 'text': 'Call you $v'}, steps: ['Saving that']);
  }
  if (has(r'(short answers|keep (it|answers|things) short|be brief|tl;?dr|less text)')) {
    return out('memory', 'Short answers from now on. Promise.', memory: {'kind': 'style', 'value': 'short', 'text': 'Keep answers short'}, steps: ['Saving that']);
  }
  if (has(r'(exam|test|certification).{0,20}\b(on|is|date)\b') || has(r'^remember.*exam')) {
    final d = parseExamDate(t);
    if (d != null) {
      final k = dayKey(d);
      final days = diffDays(dayKey(), k);
      final left = kLessons.where((l) => !s.done.containsKey(l.id)).length;
      final pace = math.max(1, (left / math.max(1, days - 7)).ceil());
      final short = '${d.day} ${kMonths[d.month - 1]}';
      return out('memory', 'Saved: exam on $short, $days days away. You have $left lessons left, so about $pace a day leaves a full week for mock exams.',
          mood: 'cheer',
          memory: {'kind': 'exam', 'value': k, 'text': 'Exam on $short ${d.year}'},
          chips: ['What should I study next?', 'Quiz me'],
          steps: ['Counting the days', 'Pacing your Skyway']);
    }
  }
  final remember = RegExp(r'^(please )?(remember|note) (that )?(.+)').firstMatch(t);
  if (remember != null) {
    final v = remember.group(4)!;
    return out('memory', 'Noted: "$v". You can see or delete it in Me, under Puff\'s memory.', memory: {'kind': 'note', 'value': v, 'text': v}, steps: ['Saving that']);
  }

  // 4. Cost
  if (has(r'(how much|cost|price|pricing|bill|expensive|cheap|₹|rupee|\$)')) {
    final sv = svcs.isNotEmpty ? svcs.first : null;
    if (sv == 's3') {
      final m = RegExp(r'(\d+(?:\.\d+)?)\s*(gb|tb|gigs?)').firstMatch(t);
      final double gb = m != null ? double.parse(m.group(1)!) * (m.group(2) == 'tb' ? 1024 : 1) : 100.0;
      const prices = [('S3 Standard', 0.023), ('Standard-IA', 0.0125), ('Glacier Instant', 0.004), ('Deep Archive', 0.00099)];
      final rows = [
        for (final p in prices) [p.$1, '${money(gb * p.$2)} · ${rupees(gb * p.$2)}'],
      ];
      return out('cost', 'For ${_num(gb)} GB a month, storage alone is roughly:',
          blocks: [
            {
              'type': 'cost',
              'title': '${_num(gb)} GB in S3, per month',
              'rows': rows,
              'foot': 'Storage only. Requests, retrievals and data transfer out are extra (first 100 GB out each month is free). Approx. list prices.',
            }
          ],
          chips: ['S3 vs EBS?', 'Which storage class should I use?'],
          steps: ['Grabbing S3 prices', 'Multiplying it out']);
    }
    if (sv == 'lambda') {
      final m = RegExp(r'(\d+(?:\.\d+)?)\s*(million|m\b|k\b|thousand|lakh)?').firstMatch(t);
      double req = m != null ? double.parse(m.group(1)!) : 2.0;
      final unit = m?.group(2) ?? 'million';
      if (unit.startsWith('k') || unit == 'thousand') {
        req = req * 1e3;
      } else if (unit == 'lakh') {
        req = req * 1e5;
      } else {
        req = req * 1e6;
      }
      final gbs = req * 0.2 * 0.125;
      final reqUsd = math.max(0.0, req - 1e6) * 0.2 / 1e6;
      final cmpUsd = math.max(0.0, gbs - 400000) * 0.0000166667;
      final usd = reqUsd + cmpUsd;
      return out('cost', usd == 0 ? 'Good news: that fits inside the always-free tier.' : 'Here is the rough monthly math:',
          blocks: [
            {
              'type': 'cost',
              'title': '${fmtIN(req)} requests a month',
              'rows': [
                ['Requests', money(reqUsd)],
                ['Compute (128 MB, 200 ms)', money(cmpUsd)],
                ['Total', '${money(usd)} · ${rupees(usd)}'],
              ],
              'foot': 'Assumes 128 MB and 200 ms per call, after the free 1M requests and 400,000 GB-seconds.',
            }
          ],
          chips: ['EC2 vs Lambda?', 'Quiz me on Lambda'],
          steps: ['Grabbing Lambda prices', 'Subtracting the free tier']);
    }
    if (sv == 'ec2') {
      const base = 0.0104 * 730;
      return out('cost', 'A small server running all month:',
          blocks: [
            {
              'type': 'cost',
              'title': 't3.micro, 24/7',
              'rows': [
                ['On-Demand', '${money(base)} · ${rupees(base)}'],
                ['Savings Plan (3 yr)', '≈ ${money(base * 0.5)}'],
                ['Spot (varies)', '≈ ${money(base * 0.3)}'],
              ],
              'foot': 'Plus EBS storage and data transfer. Spot can be interrupted.',
            }
          ],
          chips: ['EC2 vs Lambda?', 'When should I use Spot?'],
          steps: ['Grabbing EC2 prices']);
    }
    if (sv != null) {
      final x = kSvc[sv]!;
      return out('cost', "${x.nick}'s price tag: ${x.price} For a full estimate, the AWS Pricing Calculator is your friend.",
          blocks: [
            {'type': 'card', 'svc': sv}
          ],
          chips: ['Explain ${x.short}', 'Quiz me']);
    }
    return out('cost',
        'AWS pricing boils down to three things: compute time, storage, and data going out to the internet. Data coming in is free. Try asking "how much is 50 GB on S3?" or "Lambda cost for 3 million requests".',
        chips: ['How much is 50 GB on S3?', 'Lambda cost for 3 million requests']);
  }

  // 5. Pairs, then compare
  if (has(r'work together') && svcs.length >= 2) {
    final a = kSvc[svcs[0]]!;
    final b = kSvc[svcs[1]]!;
    final pair = a.pairs.contains(b.id) || b.pairs.contains(a.id);
    final friends = [for (final p in a.pairs) kSvc[p]!.nick].join(', ');
    return out(
        'pair',
        pair
            ? "They're best friends. ${a.nick} (${a.tagline.toLowerCase()}) hands off to ${b.nick} (${b.tagline.toLowerCase()}). You'll build exactly this in the Lab."
            : "They don't often team up directly, but both can live in the same architecture. ${a.nick} pairs best with $friends.",
        chips: ['Open the Build Lab', 'Quiz me']);
  }
  if (has(r'security group') && has(r'nacl|network acl')) {
    return out('compare', 'The firewall twins. One remembers, one forgets.',
        blocks: [
          {'type': 'compare', 'a': 'Security group', 'b': 'Network ACL', 'rows': _sgNacl, 'foot': 'Exam trick: if reply traffic is blocked, suspect a stateless NACL.'}
        ],
        chips: ['Explain VPC', 'Quiz me on VPC'],
        steps: ['Pulling up Fen', 'Lining them up']);
  }
  if (svcs.length >= 2 && has(r'( vs\.? |versus|difference|differ|compare|or | and )')) {
    final a = svcs[0];
    final b = svcs[1];
    final key = ([a, b]..sort()).join('|');
    final entry = _compare[key];
    final flip = entry != null && entry.order.first != a;
    final sa = kSvc[a]!;
    final sb = kSvc[b]!;
    final List<List<String>> rows = entry != null
        ? [for (final r in entry.rows) flip ? [r[0], r[2], r[1]] : r]
        : [
            ['Type', sa.t.label, sb.t.label],
            ['In a line', sa.tagline, sb.tagline],
            ['Known for', sa.stats[0], sb.stats[0]],
          ];
    return out('compare', "${sa.nick} vs ${sb.nick}. Here's the side-by-side:",
        blocks: [
          {
            'type': 'compare',
            'a': sa.name,
            'b': sb.name,
            'rows': rows,
            'ids': [a, b]
          }
        ],
        chips: ['Quiz me on ${sa.short}', 'How do ${sa.nick} and ${sb.nick} work together?'],
        steps: ['Pulling up both cards', 'Lining them up']);
  }

  // 6. Quiz
  if (has(r'(quiz|test me|ask me|practice|question for me)')) {
    final sv = svcs.isNotEmpty ? svcs.first : null;
    final q = pickQuestion(s, sv);
    return out('quiz', sv != null ? 'A ${kSvc[sv]!.nick} question, coming up.' : 'Here is one from your weakest corner:',
        mood: 'cheer',
        blocks: [
          {'type': 'quiz', 'qid': q.id}
        ],
        chips: ['Another one', 'What should I study next?'],
        steps: ['Finding your weak spots', 'Picking a question']);
  }
  if (has(r'^another( one)?|one more')) {
    final q = pickQuestion(s);
    return out('quiz', 'Another one:',
        mood: 'cheer',
        blocks: [
          {'type': 'quiz', 'qid': q.id}
        ],
        chips: ['Another one', "I'm done for today"]);
  }

  // 7. Plan
  if (has(r"(what (should|do) i (study|learn|do)|study next|what next|what's next|plan|where (do|should) i start|recommend|easy win|today)")) {
    final items = planFor(s);
    final exam = s.memoryValue('exam');
    final days = exam != null ? diffDays(dayKey(), exam) : null;
    final lead = days != null ? '$days days to your exam. ' : '';
    return out('plan', lead + (items.isNotEmpty ? "Here's your flight plan, in order:" : "You've cleared everything for today. Go stretch!"),
        mood: 'cheer',
        blocks: items.isNotEmpty
            ? [
                {'type': 'plan', 'items': items}
              ]
            : const [],
        chips: ['Quiz me', 'SQS vs SNS?'],
        steps: ['Checking your Skyway', 'Counting due flashcards', 'Ordering by impact']);
  }
  if (has(r'set a 5.?min')) {
    return out('action', 'Daily goal set to 5 minutes. Small and steady beats big and rare.', action: {'type': 'minutes', 'value': 5}, chips: ['Give me one easy win']);
  }
  if (has(r"i'?m done|bye|good ?night|see you")) {
    return out('bye', 'Nice work today, $name. Your Cloudlings will keep your seat warm.', mood: 'sleepy');
  }

  // 8. Concepts
  _Concept? concept;
  for (final c in _concepts) {
    if (has(c.pattern)) {
      concept = c;
      break;
    }
  }
  if (concept != null && !(svcs.length == 1 && !has(r'region|pillar|shared'))) {
    final lesson = concept.lesson != null ? kLesson[concept.lesson] : null;
    return out('concept', concept.text,
        blocks: lesson != null
            ? [
                {
                  'type': 'plan',
                  'items': [
                    {
                      'label': 'Open lesson: ${lesson.title}',
                      'sub': '${lesson.mins} min',
                      'action': {'type': 'lesson', 'id': lesson.id},
                    }
                  ],
                }
              ]
            : const [],
        chips: ['Quiz me', 'What should I study next?'],
        steps: ['Flipping through my notes', 'Drawing it simply']);
  }

  // 9. Explain one service
  if (svcs.isNotEmpty) {
    final x = kSvc[svcs.first]!;
    final owned = s.collected.containsKey(x.id);
    final pairShort = kSvc[x.pairs.first]!.short;
    return out('explain', '${x.nick} is ${x.name}: ${x.tagline.toLowerCase()} ${x.analogy}',
        blocks: [
          {'type': 'card', 'svc': x.id},
          {'type': 'tip', 'text': x.examTip},
        ],
        chips: ['${x.short} vs $pairShort?', 'How much does ${x.short} cost?', 'Quiz me on ${x.short}'],
        mood: owned ? 'happy' : 'wow',
        steps: ['Finding ${x.nick}', 'Writing the short version']);
  }

  // 10. Small talk
  if (has(r'^(hi|hey|hello|yo|namaste|hola|sup)\b')) {
    return out('hello', 'Hey $name! Ask me about any AWS service, prices, comparisons, or say "quiz me".', chips: ['What should I study next?', 'SQS vs SNS?', 'Quiz me']);
  }
  if (has(r'(thank|thx|ty\b|awesome|love you|nice)')) {
    return out('thanks', 'Anytime! That made my cloud fluffier.', mood: 'cheer', chips: ['Quiz me', 'What should I study next?']);
  }
  if (has(r'(who are you|what are you|are you (an )?ai|chatgpt|real ai)')) {
    return out('about',
        "I'm Puff, a pocket tutor that runs entirely on your device. No internet, no big AI model: just carefully written notes on 18 AWS services, cloud basics, prices and your progress.",
        chips: ['What can you do?']);
  }
  if (has(r'(what can you do|help)')) {
    return out('help', 'I can explain services, compare two of them, estimate costs, quiz you, plan your next step, and remember things like your exam date.',
        chips: ['Explain DynamoDB', 'RDS vs DynamoDB?', 'Remember my exam is on Dec 12', 'How much is 50 GB on S3?']);
  }

  // 11. Honest fallback
  return out('fallback', "Hmm, that's outside my little cloud. I know 18 AWS services, cloud basics, pricing and your progress. Try one of these:",
      mood: 'think', chips: ['What is a Region?', 'Explain Lambda', 'SQS vs SNS?', 'Quiz me'], steps: ['Searching my notes']);
}
