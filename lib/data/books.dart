import 'services.dart';

// Pocket Books. Page types: cover, text, reveal, deal, compare, sort, pick,
// cli, power, note, widget, recap.

class RevealItem {
  const RevealItem(this.front, this.back);
  final String front;
  final String back;
}

class CompareCol {
  const CompareCol(this.title, this.tone, this.points);
  final String title;
  final int tone;
  final List<String> points;
}

class SortItem {
  const SortItem(this.label, this.bin);
  final String label;
  final String bin;
}

class CliLine {
  const CliLine(this.cmd, this.out);
  final String cmd;
  final List<String> out;
}

class BookPage {
  const BookPage(
    this.t, {
    this.svc,
    this.title,
    this.sub,
    this.h,
    this.body,
    this.aside,
    this.critter,
    this.reveal = const [],
    this.items = const [],
    this.cols = const [],
    this.prompt,
    this.bins = const [],
    this.sortItems = const [],
    this.q,
    this.options = const [],
    this.a = 0,
    this.why,
    this.points = const [],
    this.lines = const [],
    this.w,
  });
  final String t;
  final String? svc;
  final String? title;
  final String? sub;
  final String? h;
  final String? body;
  final String? aside;
  final String? critter;
  final List<RevealItem> reveal;
  final List<String> items;
  final List<CompareCol> cols;
  final String? prompt;
  final List<String> bins;
  final List<SortItem> sortItems;
  final String? q;
  final List<String> options;
  final int a;
  final String? why;
  final List<String> points;
  final List<CliLine> lines;
  final String? w;
}

class Book {
  const Book(this.title, this.pages, {this.color, this.svc});
  final String title;
  final List<BookPage> pages;
  final int? color;
  final String? svc;
}

const Map<String, Book> _concept = {
  'c101-1': Book('What even is the cloud?', color: 0xFFFF8FB0, [
    BookPage('cover', title: 'What even is the cloud?', sub: "Spoiler: it's someone else's computers, run brilliantly."),
    BookPage('text',
        h: "Someone else's computers",
        body: 'The cloud is computing power, storage and apps you rent over the internet. You ask for what you need, get it in minutes, and pay as you go. AWS owns the buildings, servers and cables.',
        aside: "Like electricity: you don't build a power plant to charge your phone."),
    BookPage('reveal', h: 'Old way vs cloud way', reveal: [
      RevealItem('Buying servers', 'Wait weeks, pay upfront, guess how many you need.'),
      RevealItem('Renting in the cloud', 'Click, get it in minutes, pay per second or hour.'),
      RevealItem('Busy launch day?', 'Scale up for the rush, back down after.'),
      RevealItem('Quiet night?', 'Turn it off. Stop paying.'),
    ]),
    BookPage('pick',
        h: 'Quick check',
        q: 'Which best describes cloud computing?',
        options: ['Files on a USB drive', 'On-demand IT resources over the internet, pay as you go', 'A data center you buy and run', 'Free servers from Amazon'],
        a: 1,
        why: 'On-demand delivery of IT resources over the internet with pay-as-you-go pricing. That is the official AWS definition, almost word for word.'),
    BookPage('recap', points: ['The cloud = renting IT over the internet.', 'Pay only for what you use.', 'Scale up and down in minutes.']),
  ]),
  'c101-2': Book('Six cloud superpowers', color: 0xFFFFB547, [
    BookPage('cover', title: 'Six cloud superpowers', sub: 'The six advantages AWS loves to quiz you on.'),
    BookPage('reveal', h: 'Tap each power', reveal: [
      RevealItem('Pay as you go', 'Trade big upfront spend (capex) for variable spend (opex).'),
      RevealItem('Economies of scale', 'Millions of customers share costs, so prices keep dropping.'),
      RevealItem('Stop guessing capacity', 'Scale to real demand instead of predicting it.'),
      RevealItem('Speed and agility', 'New servers in minutes, not weeks.'),
      RevealItem('No data center chores', 'Spend time on your app, not racking servers.'),
      RevealItem('Go global in minutes', 'Deploy to Regions worldwide in a few clicks.'),
    ]),
    BookPage('pick',
        h: 'Quick check',
        q: "A startup can't predict launch-day traffic. Which advantage helps most?",
        options: ['Stop guessing capacity', 'Economies of scale', 'Go global in minutes', 'No data center chores'],
        a: 0,
        why: 'Elastic scaling means you match real demand, so you never have to bet on a number.'),
    BookPage('recap', points: ['Capex becomes opex.', 'Scale beats guessing.', 'Global in minutes.']),
  ]),
  'c101-3': Book('IaaS, PaaS, SaaS', color: 0xFF8C7CFF, [
    BookPage('cover', title: 'IaaS, PaaS, SaaS', sub: 'Explained with pizza. Obviously.'),
    BookPage('compare', h: 'Pizza as a service', cols: [
      CompareCol('IaaS', 0xFFFFB547, ['You get the kitchen.', 'You cook everything.', 'e.g. Amazon EC2, VPC']),
      CompareCol('PaaS', 0xFF8C7CFF, ['Bring toppings.', 'They bake and serve.', 'e.g. Elastic Beanstalk']),
      CompareCol('SaaS', 0xFFFF4D7E, ['Pizza arrives.', 'Just eat.', 'e.g. Gmail, ClickUp']),
    ]),
    BookPage('sort', h: 'Sort the menu', prompt: 'Tap a tile, then tap where it belongs.', bins: [
      'IaaS',
      'PaaS',
      'SaaS'
    ], sortItems: [
      SortItem('Amazon EC2', 'IaaS'),
      SortItem('Elastic Beanstalk', 'PaaS'),
      SortItem('Gmail', 'SaaS'),
      SortItem('EBS volume', 'IaaS'),
      SortItem('Google Docs', 'SaaS'),
      SortItem('AWS App Runner', 'PaaS'),
    ]),
    BookPage('text',
        h: 'Where it runs',
        body: 'Cloud: everything in AWS. On-premises: your own data center. Hybrid: a mix, connected together. Most big companies live in hybrid for years.',
        aside: 'Exam phrase: "connect on-premises to the cloud" means hybrid.'),
    BookPage('recap', points: ['IaaS: you manage the most.', 'SaaS: you manage the least.', 'Hybrid = cloud + on-premises.']),
  ]),
  'c101-4': Book('Who secures what?', color: 0xFFFF7A5C, [
    BookPage('cover', title: 'Who secures what?', sub: 'The shared responsibility model, as a game.'),
    BookPage('text',
        h: 'Of the cloud vs in the cloud',
        body: 'AWS secures the cloud itself: buildings, hardware, network and the virtualization layer. You secure what you put in it: your data, users, permissions, OS patches and firewall rules.',
        aside: 'AWS locks the building. You lock your own room.'),
    BookPage('sort', h: 'AWS or you?', prompt: 'Tap a job, then tap who owns it.', bins: [
      'AWS',
      'You'
    ], sortItems: [
      SortItem('Data center guards', 'AWS'),
      SortItem('Patching the EC2 guest OS', 'You'),
      SortItem('Global network hardware', 'AWS'),
      SortItem('IAM users and permissions', 'You'),
      SortItem('Encrypting your S3 data', 'You'),
      SortItem('The hypervisor', 'AWS'),
      SortItem('Security group rules', 'You'),
      SortItem('Patching the RDS engine', 'AWS'),
    ]),
    BookPage('pick',
        h: 'Quick check',
        q: 'Who patches the operating system on your EC2 instance?',
        options: ['AWS', 'You, the customer', 'Nobody, it updates itself', 'Your internet provider'],
        a: 1,
        why: 'EC2 is IaaS: the guest OS is yours. With managed services like RDS, AWS patches the engine for you.'),
    BookPage('recap', points: ['AWS: security OF the cloud.', 'You: security IN the cloud.', 'More managed = less on your plate.']),
  ]),
  'gi-2': Book('Edges near you', color: 0xFF4AA3FF, [
    BookPage('cover', title: 'Edges near you', sub: 'The tiny outposts that make the internet feel fast.'),
    BookPage('text',
        h: 'Edge locations',
        body: 'Besides Regions, AWS runs 600+ smaller sites called edge locations in cities around the world. They cache content for CloudFront and answer DNS for Route 53, right next to users.',
        aside: 'Streaming a trailer in Vizag? It probably comes from an edge nearby, not Virginia.'),
    BookPage('reveal', h: 'Four building blocks', reveal: [
      RevealItem('Region', 'A geographic area with 3+ AZs. Like Hyderabad, ap-south-2.'),
      RevealItem('Availability Zone', 'One or more data centers with separate power and networking.'),
      RevealItem('Edge location', 'A small site caching content close to users.'),
      RevealItem('Local Zone', 'AWS compute placed near a big city for ultra-low latency.'),
    ]),
    BookPage('pick',
        h: 'Quick check',
        q: 'What does CloudFront use to cache content close to users?',
        options: ['Availability Zones', 'Edge locations', 'Only Regions', 'VPC subnets'],
        a: 1,
        why: 'Edge locations are the CDN layer. Regions hold your origin; edges hold copies.'),
    BookPage('recap', points: ['Regions hold your stuff.', 'AZs keep it available.', 'Edges bring it close.']),
  ]),
  'wa-1': Book('Six pillars', color: 0xFF8C7CFF, [
    BookPage('cover', title: 'The six pillars', sub: 'How AWS architects judge a design.'),
    BookPage('reveal', h: 'The Well-Architected Framework', reveal: [
      RevealItem('Operational excellence', 'Run and improve: automate, ship small changes, learn from failures.'),
      RevealItem('Security', 'Least privilege, encryption everywhere, trace every action.'),
      RevealItem('Reliability', 'Recover from failure: multi-AZ, backups, test recovery.'),
      RevealItem('Performance efficiency', 'Right resource for the job: serverless, global, experiment.'),
      RevealItem('Cost optimization', 'Pay only for what you need: right-size, Spot, Savings Plans.'),
      RevealItem('Sustainability', 'Use less: high utilization, managed services, efficient regions.'),
    ]),
    BookPage('pick',
        h: 'Quick check',
        q: 'Running your app across two Availability Zones mainly improves which pillar?',
        options: ['Cost optimization', 'Reliability', 'Sustainability', 'Operational excellence'],
        a: 1,
        why: 'Multi-AZ is the textbook reliability move: one AZ fails, the other keeps serving.'),
    BookPage('recap', points: ['Six pillars, one balance.', 'Reliability = survive failure.', 'Cost = pay for what you use.']),
  ]),
};

const Book _s3Book = Book("Bucky's Pocket Book", color: 0xFF2FCCAA, svc: 's3', [
  BookPage('cover', svc: 's3', title: 'Amazon S3', sub: 'A bottomless bucket for files. Meet Bucky.'),
  BookPage('widget',
      w: 'bucketDrop',
      h: 'A bucket holds objects',
      body: 'Tap a file to drop it in. S3 stores each one as an object: the data, a key (its full name) and metadata.'),
  BookPage('widget',
      w: 'nines', h: 'Eleven nines, explained', body: 'S3 is designed for 99.999999999% durability. Slide to see what that means for your stuff.'),
  BookPage('widget',
      w: 'storageClass', h: 'Pick the right shelf', body: 'Same files, very different bills. Tell Bucky how often you open them.'),
  BookPage('widget',
      w: 'publicAccess',
      h: 'Private until you say so',
      body: 'New buckets block public access and encrypt every object by default. Try flipping the switch.'),
  BookPage('cli', h: 'Try it like a pro', body: 'Run these in the pocket terminal. Or type your own.', lines: [
    CliLine('aws s3 mb s3://koushi-memories --region ap-south-2', ['make_bucket: koushi-memories']),
    CliLine('aws s3 cp diwali.jpg s3://koushi-memories/2026/', ['upload: ./diwali.jpg to s3://koushi-memories/2026/diwali.jpg']),
    CliLine('aws s3 ls s3://koushi-memories --recursive', ['2026-10-15 22:10:04    2481152 2026/diwali.jpg']),
  ]),
  BookPage('pick',
      h: 'Quick check',
      q: 'Can a single S3 object be 6 TB?',
      options: ['Yes, S3 is unlimited', 'No, one object tops out at 5 TB', 'Only in Glacier', 'Only with versioning'],
      a: 1,
      why: 'Total storage is unlimited, but one object maxes out at 5 TB. Use multipart upload for anything big.'),
  BookPage('recap', svc: 's3', points: [
    'Buckets hold objects; keys are their names.',
    'Pick storage classes by how often you read.',
    'Private and encrypted by default.'
  ]),
]);

const Map<String, List<String>> kCliOut = {
  'ec2': ['{', '  "Instances": [{', '    "InstanceId": "i-0n1mbus42",', '    "InstanceType": "t3.micro",', '    "State": { "Name": "pending" }', '  }]', '}'],
  'lambda': [r'{ "StatusCode": 200, "ExecutedVersion": "$LATEST" }', 'out.json → {"order":"A17","status":"brewing"}'],
  'ebs': ['{ "SnapshotId": "snap-0c0ffee42", "State": "pending", "Progress": "" }'],
  'rds': ['{ "DBInstance": {', '  "DBInstanceIdentifier": "nimbus-db",', '  "Engine": "postgres",', '  "DBInstanceStatus": "creating" } }'],
  'dynamodb': ['(no output: put-item stays quiet when it works ✓)'],
  'elasticache': ['{ "CacheClusters": [{ "CacheClusterId": "nimbus-cache",', '  "Engine": "valkey", "CacheClusterStatus": "available" }] }'],
  'vpc': ['{ "Vpc": { "VpcId": "vpc-0fen", "CidrBlock": "10.0.0.0/16", "State": "pending" } }'],
  'cloudfront': ['{ "Invalidation": { "Id": "I2NIMBUS", "Status": "InProgress" } }'],
  'route53': ['{ "HostedZones": [{ "Name": "nimbus.dev.", "ResourceRecordSetCount": 4 }] }'],
  'elb': ['{ "LoadBalancers": [{ "LoadBalancerName": "nimbus-alb",', '  "Type": "application", "State": { "Code": "active" } }] }'],
  'apigateway': ['{ "Items": [{ "Name": "chai-api", "ProtocolType": "HTTP",', '  "ApiEndpoint": "https://a1b2c3.execute-api.ap-south-2.amazonaws.com" }] }'],
  'iam': ['{ "Users": [{ "UserName": "koushi",', '  "Arn": "arn:aws:iam::123456789012:user/koushi" }] }'],
  'kms': ['{ "CiphertextBlob": "AQICAHhN1mbu5...", "KeyId": "arn:aws:kms:ap-south-2:123456789012:key/1a2b" }'],
  'sqs': ['{ "MessageId": "5fea7756-0ea4-451a-a703-a558b933e274" }'],
  'sns': ['{ "MessageId": "95df01b4-ee98-5cb9-9903-4c221d41eb5e" }'],
  'cloudwatch': ['(no output: alarm HighCPU saved ✓)'],
  'cloudtrail': ['{ "Events": [{ "EventName": "DeleteBucket",', '  "Username": "intern-ravi", "EventTime": "2026-10-14T23:12:09Z" }] }'],
};

Book serviceBook(String id) {
  final s = kSvc[id]!;
  final tip = s.examTip;
  final third = '${tip.split('?').first}${tip.contains('?') ? '?' : ''}';
  return Book("${s.nick}'s Pocket Book", svc: id, [
    BookPage('cover', svc: id, title: s.name, sub: '${s.tagline} Meet ${s.nick}.'),
    BookPage('text', h: 'In one picture', body: s.analogy, aside: s.tagline, critter: id),
    BookPage('deal', h: 'Four things to know', items: s.facts),
    BookPage('power', svc: id, h: "${s.nick}'s stat sheet"),
    BookPage('note', h: 'Exam whisper', body: s.examTip),
    BookPage('cli', h: 'Try it like a pro', body: 'Tap run, or type the command yourself.', lines: [
      CliLine(s.cli, kCliOut[id] ?? const ['✓ done']),
    ]),
    BookPage('recap', svc: id, points: [s.stats[0], s.stats[1], third]),
  ]);
}

Book? getBook(String ref) {
  if (ref == 's3') return _s3Book;
  final c = _concept[ref];
  if (c != null) return c;
  if (kSvc.containsKey(ref)) return serviceBook(ref);
  return null;
}

/// S3 storage classes (approx. us-east-1 list prices, per GB-month).
class S3Class {
  const S3Class(this.id, this.name, this.price, this.access, this.note);
  final String id;
  final String name;
  final double price;
  final String access;
  final String note;
}

const kS3Classes = <S3Class>[
  S3Class('std', 'S3 Standard', 0.023, 'Instant', 'Opened often'),
  S3Class('it', 'Intelligent-Tiering', 0.0125, 'Instant', 'Unknown pattern; moves for you'),
  S3Class('ia', 'Standard-IA', 0.0125, 'Instant', 'Monthly-ish, retrieval fee'),
  S3Class('gir', 'Glacier Instant', 0.004, 'Milliseconds', 'Quarterly, still instant'),
  S3Class('gfr', 'Glacier Flexible', 0.0036, 'Minutes to hours', 'Yearly restores'),
  S3Class('gda', 'Glacier Deep Archive', 0.00099, 'Within 12 hours', 'Almost never'),
];
