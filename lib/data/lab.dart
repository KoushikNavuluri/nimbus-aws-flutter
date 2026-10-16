// Build Lab scenarios. Costs are rough monthly estimates from public list prices
// (us-east-1 / ap-south-2), for learning. USD to INR at an assumed 88.
const double kInr = 88;
const double _hrs = 730;

class SlotDef {
  const SlotDef(this.id, this.label, this.need, this.accept, {this.wrong = const {}, this.notes = const {}, this.option});
  final String id;
  final String label;
  final String need;
  final Map<String, int> accept;
  final Map<String, String> wrong;
  final Map<String, String> notes;
  final String? option;
}

class LabOption {
  const LabOption(this.id, this.slot, this.label, this.only);
  final String id;
  final String slot;
  final String label;
  final String only;
}

class LabResult {
  LabResult({
    required this.latency,
    required this.usd,
    required this.pillars,
    required this.survived,
    this.failed,
    required this.chaosText,
    required this.notes,
  });
  final List<(String, int)> latency;
  final double usd;
  final Map<String, int> pillars;
  final bool survived;
  final String? failed;
  final String chaosText;
  final List<String> notes;
  double get inr => usd * kInr;
}

typedef LabEval = LabResult Function(Map<String, String> pick, Map<String, bool> opts);

class Scenario {
  const Scenario({
    required this.id,
    required this.title,
    required this.tag,
    required this.level,
    required this.xp,
    required this.brief,
    required this.source,
    required this.slots,
    required this.tray,
    required this.options,
    required this.chaos,
    required this.chaosIcon,
    required this.evaluate,
  });
  final String id;
  final String title;
  final String tag;
  final int level;
  final int xp;
  final String brief;
  final (String, String) source;
  final List<SlotDef> slots;
  final List<String> tray;
  final List<LabOption> options;
  final String chaos;
  final String chaosIcon; // siren | zap | power
  final LabEval evaluate;

  String get briefLead => '${brief.split('. ').first}.';
}

LabResult _evalResults(Map<String, String> p, Map<String, bool> o) {
  final cdn = p['edge'] == 'cloudfront';
  final s3 = p['origin'] == 's3';
  final double usd = 0.5 + (s3 ? 0.06 : 0.0208 * _hrs) + (cdn ? 0.0 : 2.2);
  return LabResult(
    latency: cdn ? const [('Hyderabad', 14), ('Hamburg', 19), ('Houston', 22)] : const [('Hyderabad', 26), ('Hamburg', 162), ('Houston', 231)],
    usd: usd,
    pillars: {
      'Reliability': s3 ? 96 : (cdn ? 74 : 38),
      'Performance': cdn ? 96 : 58,
      'Cost': s3 ? 97 : 52,
      'Security': cdn && s3 ? 95 : 80,
    },
    survived: cdn || s3,
    chaosText: cdn || s3 ? 'Edges served 94% of requests from cache. Nobody saw a spinner.' : 'One server, 80,000 refreshes. It fell over at 10:00:07.',
    notes: [
      cdn ? 'CloudFront serves 9 in 10 requests from the edge, so the origin barely notices.' : 'Without a CDN, every refresh crosses the planet.',
      s3 ? 'S3 + CloudFront with Origin Access Control: bucket stays private, costs stay tiny.' : 'Swap EC2 for S3: static files need no server.',
    ],
  );
}

LabResult _evalChai(Map<String, String> p, Map<String, bool> o) {
  final sls = p['logic'] == 'lambda';
  final double usd = (p['door'] == 'apigateway' ? 0.18 : 0.0225 * _hrs) + (sls ? 0.0 : 0.0208 * _hrs) + (p['store'] == 'dynamodb' ? 0.14 : 0.016 * _hrs) + 0.02;
  final rows = <(String, int)>[
    ('App → order saved', sls ? 41 : 33),
    ('Cold start (rare)', sls ? 380 : 0),
    ('Owner pinged', p['notify'] == 'sns' ? 120 : 2400),
  ];
  return LabResult(
    latency: [for (final r in rows) if (r.$2 > 0) r],
    usd: usd,
    pillars: {
      'Reliability': sls ? 95 : 62,
      'Performance': sls ? 88 : 80,
      'Cost': usd < 2 ? 98 : (usd < 20 ? 70 : 48),
      'Security': 90,
    },
    survived: sls,
    chaosText: sls ? 'Lambda scaled to 42 copies in seconds. 600 chais, zero drama.' : 'One EC2 instance hit 100% CPU. Orders timed out at 11:04 PM.',
    notes: [
      sls ? 'Fully serverless: you pay per order, and idle afternoons cost nothing.' : 'Swap Servo for Zip so capacity follows the rush.',
      p['notify'] == 'sns' ? 'SNS pushes to the owner instantly (and can fan out to SMS + email).' : 'With SQS someone must poll; SNS pushes on its own.',
    ],
  );
}

LabResult _evalAz(Map<String, String> p, Map<String, bool> o) {
  final multiApp = o['multiAzApp'] ?? false;
  final multiDb = o['multiAzDb'] ?? false;
  final appOk = p['app'] == 'lambda' || multiApp;
  final dbOk = p['db'] == 'dynamodb' || multiDb;
  final survived = p['lb'] == 'elb' && appOk && dbOk;
  final double usd = 0.0225 * _hrs +
      (p['app'] == 'ec2' ? 0.0208 * _hrs * (multiApp ? 2 : 1) : 4.0) +
      (p['db'] == 'rds' ? 0.016 * _hrs * (multiDb ? 2 : 1) : 6.0) +
      3.0;
  return LabResult(
    latency: const [('Hyderabad', 38), ('Vijayawada', 44), ('Bengaluru', 47)],
    usd: usd,
    pillars: {
      'Reliability': survived ? 97 : ((appOk || dbOk) ? 55 : 30),
      'Performance': 86,
      'Cost': usd < 45 ? 82 : 70,
      'Security': 88,
    },
    survived: survived,
    failed: survived ? null : (!appOk ? 'app' : 'db'),
    chaosText: survived
        ? 'AZ-a went dark. Traffic shifted to AZ-b in seconds. Seats kept selling.'
        : (!appOk ? 'Your only app server lived in AZ-a. Bookings stopped.' : 'The database lived only in AZ-a. Seats froze mid-sale.'),
    notes: [
      appOk ? 'App capacity lives in two AZs, so one can vanish.' : 'Turn on the Auto Scaling group across 2 AZs.',
      dbOk ? 'The database has a standby in another AZ with automatic failover.' : 'Turn on RDS Multi-AZ: a standby takes over in about a minute.',
      p['watch'] == 'cloudwatch' ? 'Hoot pages you through SNS the moment errors climb.' : 'Add CloudWatch alarms so you hear about it first.',
    ],
  );
}

const kScenarios = <Scenario>[
  Scenario(
    id: 'results-day',
    title: 'Results day',
    tag: 'Static site · global spike',
    level: 1,
    xp: 60,
    brief: 'Exam results drop at 10:00 AM and 80,000 students refresh at once, from Hyderabad to Hamburg. The page is plain HTML plus PDFs. Make it fast everywhere, and nearly free the other 364 days.',
    source: ('80,000 students', 'Hyderabad · Hamburg · Houston'),
    slots: [
      SlotDef('dns', 'Name → address', 'turns results.nimbus.in into an address', {'route53': 100}, wrong: {
        'elb': 'Juggles spreads traffic, but someone has to translate the name first.',
        'cloudfront': 'Close! Jet sits right after the name lookup. Who does the lookup?',
      }),
      SlotDef('edge', 'Close to students', 'keeps copies close to every student', {'cloudfront': 100}, wrong: {
        'elb': 'A load balancer lives in one Region. Students in Hamburg still wait.',
        'route53': 'Signy already found the address. Who keeps copies near students?',
      }),
      SlotDef('origin', 'Holds the files', 'stores the HTML and result PDFs', {'s3': 100, 'ec2': 60}, notes: {
        'ec2': 'Works, but you pay for an always-on server 365 days a year for a 2-hour spike.',
      }, wrong: {
        'rds': 'Rory stores rows and tables, not PDFs.',
        'dynamodb': 'Dyna caps items at 400 KB. PDFs belong in object storage.',
        'ebs': 'Disky only plugs into one EC2 instance.',
      }),
    ],
    tray: ['route53', 'cloudfront', 's3', 'ec2', 'elb', 'rds', 'dynamodb', 'ebs'],
    options: [],
    chaos: '10:00 AM · 80k refreshes',
    chaosIcon: 'siren',
    evaluate: _evalResults,
  ),
  Scenario(
    id: 'chai-api',
    title: 'Chai on demand',
    tag: 'Serverless API · spiky orders',
    level: 2,
    xp: 70,
    brief: 'The hostel chai stall takes orders from an app: 20 orders at 3 PM, 600 at 11 PM before exams. No servers to babysit, and the owner should get pinged for every order.',
    source: ('Hostel app', '20 to 600 orders an hour'),
    slots: [
      SlotDef('door', 'Front door', 'receives HTTPS calls from the app', {'apigateway': 100, 'elb': 60}, notes: {
        'elb': 'Works, but a load balancer needs servers behind it and bills every hour.',
      }, wrong: {
        'route53': 'Signy points to the door. Who is the door?',
        'cloudfront': 'Jet is great for caching, but orders must not be cached.',
      }),
      SlotDef('logic', 'Order logic', 'runs the code that takes an order', {'lambda': 100, 'ec2': 55}, notes: {
        'ec2': 'Servo works, but sits idle (and billed) all afternoon.',
      }, wrong: {
        'sqs': 'Quack can hold orders, but something still has to run the code.',
      }),
      SlotDef('store', 'Saves orders', 'stores every order safely', {'dynamodb': 100, 'rds': 75}, notes: {
        'rds': 'Fine, but you pay for a database that naps between rushes.',
      }, wrong: {
        's3': 'Bucky stores files, not quick little order records.',
        'elasticache': 'Blink is fast, but memory is not a safe only copy.',
      }),
      SlotDef('notify', 'Ping the owner', 'pushes a message to the stall owner', {'sns': 100, 'sqs': 70}, notes: {
        'sqs': 'Quack holds messages until someone polls. Pip pushes instantly.',
      }, wrong: {
        'cloudwatch': 'Hoot watches metrics. Close, but this is a business message.',
      }),
    ],
    tray: ['apigateway', 'elb', 'lambda', 'ec2', 'dynamodb', 'rds', 'sns', 'sqs', 's3'],
    options: [],
    chaos: 'Exam night · orders ×30',
    chaosIcon: 'zap',
    evaluate: _evalChai,
  ),
  Scenario(
    id: 'survive-az',
    title: 'Survive a bad day',
    tag: 'Two-tier app · high availability',
    level: 3,
    xp: 80,
    brief: 'A bus-ticket app for the Sankranti rush. If a whole Availability Zone goes dark, bookings must keep flowing, and you want to hear about trouble before customers tweet.',
    source: ('Sankranti travellers', '3,000 bookings an hour'),
    slots: [
      SlotDef('lb', 'Spread traffic', 'spreads users across healthy servers', {'elb': 100}, wrong: {
        'route53': 'Signy can steer between Regions, but inside one, Juggles does the spreading.',
        'cloudfront': 'Bookings are dynamic, so an edge cache will not help much here.',
      }),
      SlotDef('app', 'App servers', 'runs the booking app', {'ec2': 100, 'lambda': 80}, option: 'multiAzApp', notes: {
        'lambda': 'Works if you rewrite the app into functions. Lambda is multi-AZ already.',
      }),
      SlotDef('db', 'Bookings DB', 'keeps bookings consistent (seats!)', {'rds': 100, 'dynamodb': 80}, option: 'multiAzDb', notes: {
        'dynamodb': 'Dyna replicates across AZs automatically, but seat locking needs careful design.',
      }, wrong: {
        's3': 'Bucky is for files. Seats need transactions.',
        'elasticache': 'Blink is a cache. A power cut would erase bookings.',
      }),
      SlotDef('watch', 'Early warning', 'alerts you when latency or errors spike', {'cloudwatch': 100, 'cloudtrail': 50}, notes: {
        'cloudtrail': 'Tracks logs who did what, but will not page you when errors spike.',
      }),
    ],
    tray: ['elb', 'route53', 'ec2', 'lambda', 'rds', 'dynamodb', 'cloudwatch', 'cloudtrail', 's3'],
    options: [
      LabOption('multiAzApp', 'app', 'Auto Scaling group across 2 AZs', 'ec2'),
      LabOption('multiAzDb', 'db', 'Multi-AZ standby', 'rds'),
    ],
    chaos: 'Unplug AZ-a',
    chaosIcon: 'power',
    evaluate: _evalAz,
  ),
];

Scenario scenarioById(String id) => kScenarios.firstWhere((s) => s.id == id, orElse: () => kScenarios.first);
