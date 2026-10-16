/// The Skyway: islands float from dawn to midnight as you climb.
class Lesson {
  const Lesson(this.id, this.title, this.kind, this.ref, this.mins, this.xp, this.module, {this.svc});
  final String id;
  final String title;
  final String kind; // book | cinema | quiz
  final String ref;
  final int mins;
  final int xp;
  final String module;
  final String? svc;
}

class Island {
  const Island(this.id, this.title, this.sub, this.sky, this.lessons, {this.dark = false});
  final String id;
  final String title;
  final String sub;
  final List<int> sky;
  final List<Lesson> lessons;
  final bool dark;
}

const kIslands = <Island>[
  Island('c101', 'Cloud 101', 'What the cloud really is', [0xFFFFE6DA, 0xFFFFD9E4], [
    Lesson('c101-1', 'What even is the cloud?', 'book', 'c101-1', 4, 30, 'c101'),
    Lesson('c101-2', 'Six cloud superpowers', 'book', 'c101-2', 4, 30, 'c101'),
    Lesson('c101-3', 'IaaS, PaaS, SaaS', 'book', 'c101-3', 3, 30, 'c101'),
    Lesson('c101-4', 'Who secures what?', 'book', 'c101-4', 4, 40, 'c101'),
  ]),
  Island('global', 'Planet AWS', 'Regions, AZs and edges', [0xFFFFD9E4, 0xFFFFEFC9], [
    Lesson('gi-1', 'Where the cloud lives', 'cinema', 'regions', 2, 25, 'global'),
    Lesson('gi-2', 'Edges near you', 'book', 'gi-2', 3, 30, 'global'),
  ]),
  Island('identity', 'Keys & Locks', 'Who can do what', [0xFFFFEFC9, 0xFFE3F4FF], [
    Lesson('iam', 'IAM with Keeper', 'book', 'iam', 4, 40, 'identity', svc: 'iam'),
    Lesson('kms', 'KMS with Locky', 'book', 'kms', 3, 30, 'identity', svc: 'kms'),
  ]),
  Island('compute', 'Engines', 'Servers and serverless', [0xFFE3F4FF, 0xFFDCEBFF], [
    Lesson('ec2', 'EC2 with Servo', 'book', 'ec2', 4, 40, 'compute', svc: 'ec2'),
    Lesson('lambda', 'Lambda with Zip', 'book', 'lambda', 4, 40, 'compute', svc: 'lambda'),
  ]),
  Island('storage', 'The Vault', 'Where your files sleep', [0xFFDCEBFF, 0xFFD9E2FF], [
    Lesson('s3', 'S3 with Bucky', 'book', 's3', 5, 40, 'storage', svc: 's3'),
    Lesson('ebs', 'EBS with Disky', 'book', 'ebs', 3, 30, 'storage', svc: 'ebs'),
  ]),
  Island('network', 'Roads & Signposts', 'How traffic finds you', [0xFFD9E2FF, 0xFFE1DAFF], [
    Lesson('vpc', 'VPC with Fen', 'book', 'vpc', 5, 40, 'network', svc: 'vpc'),
    Lesson('gi-3', 'Life of a request', 'cinema', 'request', 2, 25, 'network'),
    Lesson('elb', 'ELB with Juggles', 'book', 'elb', 3, 30, 'network', svc: 'elb'),
    Lesson('route53', 'Route 53 with Signy', 'book', 'route53', 3, 30, 'network', svc: 'route53'),
    Lesson('cloudfront', 'CloudFront with Jet', 'book', 'cloudfront', 3, 30, 'network', svc: 'cloudfront'),
    Lesson('apigateway', 'API Gateway with Gatey', 'book', 'apigateway', 3, 30, 'network', svc: 'apigateway'),
  ]),
  Island('data', 'Data Den', 'SQL, NoSQL and cache', [0xFFE1DAFF, 0xFFF1D9F2], [
    Lesson('rds', 'RDS with Rory', 'book', 'rds', 4, 40, 'data', svc: 'rds'),
    Lesson('dynamodb', 'DynamoDB with Dyna', 'book', 'dynamodb', 4, 40, 'data', svc: 'dynamodb'),
    Lesson('elasticache', 'ElastiCache with Blink', 'book', 'elasticache', 3, 30, 'data', svc: 'elasticache'),
  ]),
  Island('integrate', 'Messengers', 'Queues and broadcasts', [0xFFF1D9F2, 0xFFC9C3F0], [
    Lesson('sqs', 'SQS with Quack', 'book', 'sqs', 3, 30, 'integrate', svc: 'sqs'),
    Lesson('sns', 'SNS with Pip', 'book', 'sns', 3, 30, 'integrate', svc: 'sns'),
  ]),
  Island('observe', 'Night Watch', 'Metrics and footprints', [0xFF545AA6, 0xFF343A82], [
    Lesson('cloudwatch', 'CloudWatch with Hoot', 'book', 'cloudwatch', 3, 30, 'observe', svc: 'cloudwatch'),
    Lesson('cloudtrail', 'CloudTrail with Tracks', 'book', 'cloudtrail', 3, 30, 'observe', svc: 'cloudtrail'),
  ], dark: true),
  Island('summit', 'The Summit', 'Think like an architect', [0xFF343A82, 0xFF1E2260], [
    Lesson('wa-1', 'Six pillars of good builds', 'book', 'wa-1', 4, 40, 'summit'),
    Lesson('mock', 'Mock exam: 12 questions', 'quiz', 'mock', 10, 120, 'summit'),
  ], dark: true),
];

final List<Lesson> kLessons = [for (final m in kIslands) ...m.lessons];
final Map<String, Lesson> kLesson = {for (final l in kLessons) l.id: l};

int lessonIndex(String id) => kLessons.indexWhere((l) => l.id == id);

Island islandOf(Lesson l) => kIslands.firstWhere((m) => m.id == l.module, orElse: () => kIslands.first);
