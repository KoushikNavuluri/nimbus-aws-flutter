import 'package:flutter/painting.dart';

// The Cloudex: 18 AWS services, each a collectible "Cloudling".
// Prices are approximate public list prices (mostly us-east-1) for learning only.
// Always confirm on https://aws.amazon.com/pricing before you build.

class SvcType {
  const SvcType(this.label, this.argb, this.inkArgb, this.softArgb);
  final String label;
  final int argb;
  final int inkArgb;
  final int softArgb;
  Color get color => Color(argb);
  Color get ink => Color(inkArgb);
  Color get soft => Color(softArgb);
}

const Map<String, SvcType> kTypes = {
  'compute': SvcType('Compute', 0xFFFFB547, 0xFF8A4B00, 0xFFFFF1D9),
  'storage': SvcType('Storage', 0xFF2FCCAA, 0xFF00664F, 0xFFDDF8F0),
  'database': SvcType('Database', 0xFF8C7CFF, 0xFF3B2BA8, 0xFFECE9FF),
  'network': SvcType('Networking', 0xFF4AA3FF, 0xFF0B57A8, 0xFFE1F0FF),
  'security': SvcType('Security', 0xFFFF7A5C, 0xFFA6321A, 0xFFFFE9E3),
  'integration': SvcType('Integration', 0xFF86CF4E, 0xFF3C6E12, 0xFFEBF8DF),
  'monitor': SvcType('Monitoring', 0xFFFF8FCF, 0xFFA0236B, 0xFFFFE8F5),
};

class Power {
  const Power(this.speed, this.scale, this.simplicity, this.thrift);
  final int speed;
  final int scale;
  final int simplicity;
  final int thrift;
}

class Service {
  const Service({
    required this.id,
    required this.no,
    required this.name,
    required this.nick,
    required this.type,
    required this.rarity,
    required this.tagline,
    required this.analogy,
    required this.stats,
    required this.power,
    required this.facts,
    required this.examTip,
    required this.price,
    required this.pairs,
    required this.cli,
    required this.domain,
  });
  final String id;
  final int no;
  final String name;
  final String nick;
  final String type;
  final int rarity;
  final String tagline;
  final String analogy;
  final List<String> stats;
  final Power power;
  final List<String> facts;
  final String examTip;
  final String price;
  final List<String> pairs;
  final String cli;
  final String domain;

  SvcType get t => kTypes[type]!;
  String get short => name.replaceFirst(RegExp(r'^(Amazon|AWS) '), '');
}

const List<Service> kServices = [
  Service(
    id: 'ec2', no: 1, name: 'Amazon EC2', nick: 'Servo', type: 'compute', rarity: 3,
    tagline: 'Rent a computer by the second.',
    analogy: 'Like borrowing a laptop from a giant library: pick the size, use it, hand it back, pay only for the time you had it.',
    stats: ['Per-second billing', 'Spot: up to 90% off', 'You manage the OS'],
    power: Power(4, 4, 2, 3),
    facts: [
      'Pricing models: On-Demand, Savings Plans, Reserved Instances and Spot (spare capacity, up to 90% off, can be interrupted).',
      'An AMI is the template (OS + software) every instance boots from.',
      'Families hint at the job: t = burstable, m = general, c = compute, r = memory, g = GPU.',
      'Security groups wrap each instance like a stateful firewall.',
    ],
    examTip: 'Interruptible, flexible batch job? Spot. Steady 24/7 server for years? Savings Plans or Reserved.',
    price: r't3.micro is about $0.0104 per hour On-Demand.',
    pairs: ['ebs', 'elb', 'vpc'],
    cli: 'aws ec2 run-instances --image-id ami-0abc --instance-type t3.micro',
    domain: 'tech',
  ),
  Service(
    id: 'lambda', no: 2, name: 'AWS Lambda', nick: 'Zip', type: 'compute', rarity: 3,
    tagline: 'Code that wakes up only when needed.',
    analogy: 'A motion-sensor light: dark until someone walks past, and you pay only for the seconds it glows.',
    stats: ['15 min max run', '128 MB to 10 GB memory', 'Billed per ms'],
    power: Power(4, 5, 5, 5),
    facts: [
      'Event-driven: S3 uploads, API Gateway calls, SQS messages and EventBridge schedules can all trigger it.',
      'Scales out automatically, one environment per concurrent request.',
      'Free tier: 1 million requests and 400,000 GB-seconds every month.',
      'A "cold start" is the small delay when a fresh environment spins up.',
    ],
    examTip: 'Job runs longer than 15 minutes? Not Lambda. Think Fargate, AWS Batch or EC2.',
    price: r'$0.20 per million requests, plus compute time per GB-second.',
    pairs: ['apigateway', 'dynamodb', 's3'],
    cli: 'aws lambda invoke --function-name chai-order out.json',
    domain: 'tech',
  ),
  Service(
    id: 's3', no: 3, name: 'Amazon S3', nick: 'Bucky', type: 'storage', rarity: 3,
    tagline: 'A bottomless bucket for files.',
    analogy: 'A coat check with infinite hooks: hand over anything, get a ticket (the key), collect it any time.',
    stats: ['11 nines durable', '5 TB max object', 'Unlimited objects'],
    power: Power(3, 5, 5, 5),
    facts: [
      'Bucket names are globally unique, but each bucket lives in one Region you pick.',
      'Storage classes trade price for access speed, from Standard down to Glacier Deep Archive.',
      'New buckets block public access and encrypt objects (SSE-S3) by default.',
      'Lifecycle rules can move old objects to cheaper classes automatically.',
    ],
    examTip: 'Rarely opened but needed in milliseconds? Glacier Instant Retrieval. Compliance archive where hours are fine? Deep Archive.',
    price: r'S3 Standard is about $0.023 per GB-month.',
    pairs: ['cloudfront', 'lambda', 'kms'],
    cli: 'aws s3 cp diwali.jpg s3://koushi-memories/2026/',
    domain: 'tech',
  ),
  Service(
    id: 'ebs', no: 4, name: 'Amazon EBS', nick: 'Disky', type: 'storage', rarity: 2,
    tagline: 'A hard drive that clips onto EC2.',
    analogy: 'A USB drive plugged into one laptop: quick, but it stays in that one room (one Availability Zone).',
    stats: ['Lives in one AZ', 'Snapshots to S3', 'gp3 is the default'],
    power: Power(5, 3, 4, 3),
    facts: [
      'Block storage: the OS sees it as a raw disk you format.',
      'A volume attaches to instances in the same AZ only.',
      'Snapshots are incremental and can be copied to other AZs or Regions.',
      'Volume types: gp3 (general SSD), io2 (high IOPS), st1/sc1 (cheaper HDD).',
    ],
    examTip: 'Need the disk in another AZ? Snapshot it, then restore the snapshot there.',
    price: r'gp3 is about $0.08 per GB-month.',
    pairs: ['ec2', 's3', 'kms'],
    cli: 'aws ec2 create-snapshot --volume-id vol-0abc --description "before upgrade"',
    domain: 'tech',
  ),
  Service(
    id: 'rds', no: 5, name: 'Amazon RDS', nick: 'Rory', type: 'database', rarity: 3,
    tagline: 'A SQL database someone else babysits.',
    analogy: 'A librarian who shelves, backs up and patches your SQL books while you just read them.',
    stats: ['MySQL, PostgreSQL + more', 'Multi-AZ failover', 'Read replicas'],
    power: Power(3, 3, 4, 3),
    facts: [
      'Engines: Aurora, PostgreSQL, MySQL, MariaDB, Oracle, SQL Server and Db2.',
      'Automated backups with point-in-time restore, kept up to 35 days.',
      'Multi-AZ keeps a standby in another AZ and fails over automatically.',
      'Read replicas copy data so reads can be spread out.',
    ],
    examTip: 'Multi-AZ is for availability. Read replicas are for read performance. The exam loves this swap.',
    price: r'db.t4g.micro MySQL is about $0.016 per hour.',
    pairs: ['ec2', 'elasticache', 'kms'],
    cli: 'aws rds create-db-instance --engine postgres --db-instance-class db.t4g.micro',
    domain: 'tech',
  ),
  Service(
    id: 'dynamodb', no: 6, name: 'Amazon DynamoDB', nick: 'Dyna', type: 'database', rarity: 3,
    tagline: 'Key-value lookups in milliseconds, at any size.',
    analogy: 'A giant wall of lockers: know the locker number (the key) and your stuff is there instantly.',
    stats: ['Single-digit ms', 'Fully serverless', '400 KB max item'],
    power: Power(5, 5, 4, 4),
    facts: [
      'Every item has a partition key, and optionally a sort key.',
      'On-demand capacity scales with traffic; provisioned is cheaper when load is steady.',
      'Global Tables replicate across Regions for multi-Region apps.',
      'DAX adds a microsecond in-memory cache in front.',
    ],
    examTip: 'Joins and complex SQL? RDS. Huge scale with simple key lookups? DynamoDB.',
    price: r'On-demand is roughly $0.625 per million writes and $0.125 per million reads.',
    pairs: ['lambda', 'apigateway', 'cloudwatch'],
    cli: 'aws dynamodb put-item --table-name ChaiOrders --item \'{"orderId":{"S":"A17"}}\'',
    domain: 'tech',
  ),
  Service(
    id: 'elasticache', no: 7, name: 'Amazon ElastiCache', nick: 'Blink', type: 'database', rarity: 2,
    tagline: 'Super-fast memory for hot data.',
    analogy: 'Keeping your most-used spices on the counter instead of walking to the store room every time.',
    stats: ['Microsecond reads', 'Valkey, Redis OSS, Memcached', 'In-memory'],
    power: Power(5, 4, 3, 3),
    facts: [
      'Caches database query results so the database works less.',
      'Great for sessions, leaderboards and rate limiting.',
      'Comes in node-based clusters or a serverless option.',
      'Data lives in memory, so it is fast but should not be your only copy.',
    ],
    examTip: 'Database drowning in the same repeated reads? Put ElastiCache in front of it.',
    price: 'Billed per node-hour, or per GB-hour on serverless.',
    pairs: ['rds', 'dynamodb', 'ec2'],
    cli: 'aws elasticache describe-cache-clusters',
    domain: 'tech',
  ),
  Service(
    id: 'vpc', no: 8, name: 'Amazon VPC', nick: 'Fen', type: 'network', rarity: 3,
    tagline: 'Your own private neighbourhood in AWS.',
    analogy: 'A gated colony: you draw the streets (subnets), build the gate (internet gateway) and decide who walks in.',
    stats: ['Subnet per AZ', 'Security groups: stateful', 'NACLs: stateless'],
    power: Power(4, 4, 2, 5),
    facts: [
      'You pick an IP range in CIDR notation, like 10.0.0.0/16.',
      'A public subnet has a route to an internet gateway; private subnets do not.',
      'Private instances reach the internet outbound through a NAT gateway.',
      'Security groups only allow. Network ACLs can allow and deny, checked in rule order.',
    ],
    examTip: 'Security groups remember replies (stateful). NACLs forget, so open both directions.',
    price: r'The VPC is free; a NAT gateway is about $0.045 per hour plus data.',
    pairs: ['ec2', 'elb', 'rds'],
    cli: 'aws ec2 create-vpc --cidr-block 10.0.0.0/16',
    domain: 'security',
  ),
  Service(
    id: 'cloudfront', no: 9, name: 'Amazon CloudFront', nick: 'Jet', type: 'network', rarity: 2,
    tagline: 'Copies your content close to every user.',
    analogy: 'Opening tiny chai stalls in every neighbourhood so nobody has to travel to the main shop.',
    stats: ['600+ edge PoPs', 'Free HTTPS', '1 TB/month free'],
    power: Power(5, 5, 4, 4),
    facts: [
      'Origins can be S3, a load balancer, EC2 or any web server.',
      'Origin Access Control keeps your S3 bucket private behind CloudFront.',
      'TTLs decide how long edges keep a cached copy.',
      'Includes AWS Shield Standard DDoS protection at no extra cost.',
    ],
    examTip: 'Global users, static content, lower latency: CloudFront is almost always the answer.',
    price: 'Always-free tier: 1 TB data out and 10 million requests a month.',
    pairs: ['s3', 'route53', 'elb'],
    cli: 'aws cloudfront create-invalidation --distribution-id E1NIMBUS --paths "/*"',
    domain: 'tech',
  ),
  Service(
    id: 'route53', no: 10, name: 'Amazon Route 53', nick: 'Signy', type: 'network', rarity: 2,
    tagline: 'The internet phonebook, with smart directions.',
    analogy: 'A signpost that turns names (nimbus.dev) into addresses and points you to the nearest open shop.',
    stats: ['100% availability SLA', 'Health checks', '8 routing policies'],
    power: Power(5, 5, 3, 5),
    facts: [
      'Named after port 53, where DNS lives.',
      'Routing policies include simple, weighted, latency, failover, geolocation and more.',
      'Alias records point straight at AWS resources like CloudFront or a load balancer.',
      'Health checks can steer traffic away from unhealthy endpoints.',
    ],
    examTip: 'Send users to the fastest Region? Latency routing. Active-passive disaster recovery? Failover routing.',
    price: r'$0.50 per hosted zone per month, plus queries.',
    pairs: ['cloudfront', 'elb', 's3'],
    cli: 'aws route53 list-hosted-zones',
    domain: 'tech',
  ),
  Service(
    id: 'elb', no: 11, name: 'Elastic Load Balancing', nick: 'Juggles', type: 'network', rarity: 2,
    tagline: 'Spreads traffic across many servers.',
    analogy: 'A traffic cop at a busy junction waving each car into whichever lane is free.',
    stats: ['ALB: layer 7', 'NLB: layer 4', 'Health checks'],
    power: Power(4, 5, 3, 3),
    facts: [
      'Application Load Balancer routes by URL path, host or headers.',
      'Network Load Balancer handles millions of requests with very low latency and static IPs.',
      'Spans multiple AZs and stops sending traffic to unhealthy targets.',
      'Pairs with EC2 Auto Scaling so new servers join automatically.',
    ],
    examTip: 'Route /api and /images to different servers? Application Load Balancer.',
    price: r'An ALB is about $0.0225 per hour plus capacity units.',
    pairs: ['ec2', 'route53', 'vpc'],
    cli: 'aws elbv2 describe-load-balancers',
    domain: 'tech',
  ),
  Service(
    id: 'apigateway', no: 12, name: 'Amazon API Gateway', nick: 'Gatey', type: 'network', rarity: 2,
    tagline: 'The front door for your APIs.',
    analogy: 'A receptionist who checks IDs, keeps the crowd orderly and sends each visitor to the right room.',
    stats: ['REST, HTTP, WebSocket', 'Throttling', 'Auth built in'],
    power: Power(4, 5, 4, 4),
    facts: [
      'Most often fronts Lambda functions for serverless APIs.',
      'Throttling and usage plans protect your backend from floods.',
      'Authorizers: IAM, Amazon Cognito or a custom Lambda.',
      'HTTP APIs are cheaper and simpler; REST APIs have more features.',
    ],
    examTip: 'The classic serverless trio: API Gateway + Lambda + DynamoDB.',
    price: r'HTTP APIs start around $1.00 per million requests.',
    pairs: ['lambda', 'dynamodb', 'iam'],
    cli: 'aws apigatewayv2 get-apis',
    domain: 'tech',
  ),
  Service(
    id: 'iam', no: 13, name: 'AWS IAM', nick: 'Keeper', type: 'security', rarity: 3,
    tagline: 'Decides who can do what.',
    analogy: 'The hostel warden with a key ring: each key (policy) opens only the doors it should.',
    stats: ['Global service', 'Free', 'Least privilege'],
    power: Power(5, 5, 2, 5),
    facts: [
      'Users, groups, roles and policies. Policies are JSON documents.',
      'Roles give temporary credentials, perfect for EC2 or Lambda.',
      'An explicit Deny always wins over any Allow.',
      'Protect the root user with MFA and never use it for daily work.',
    ],
    examTip: 'App on EC2 needs S3? Attach an IAM role. Never store access keys on the instance.',
    price: 'Free.',
    pairs: ['kms', 'cloudtrail', 'ec2'],
    cli: 'aws iam list-users',
    domain: 'security',
  ),
  Service(
    id: 'kms', no: 14, name: 'AWS KMS', nick: 'Locky', type: 'security', rarity: 2,
    tagline: 'Creates and guards your encryption keys.',
    analogy: 'A bank locker for keys: the master key never leaves, the bank uses it on your behalf.',
    stats: ['Envelope encryption', 'Auto key rotation', 'Every use logged'],
    power: Power(4, 4, 3, 4),
    facts: [
      'Integrates with S3, EBS, RDS and most services that store data.',
      'Customer managed keys give you control over policy and rotation.',
      'Envelope encryption: a data key encrypts data, the KMS key encrypts the data key.',
      'Every key use shows up in CloudTrail.',
    ],
    examTip: 'Need control and an audit trail of who used a key? A KMS customer managed key.',
    price: r'$1 per key per month, plus $0.03 per 10,000 requests.',
    pairs: ['s3', 'ebs', 'iam'],
    cli: 'aws kms encrypt --key-id alias/nimbus --plaintext fileb://secret.txt',
    domain: 'security',
  ),
  Service(
    id: 'sqs', no: 15, name: 'Amazon SQS', nick: 'Quack', type: 'integration', rarity: 2,
    tagline: 'A waiting line so nothing gets trampled.',
    analogy: 'Ducklings in a line: each one waits its turn, and nobody gets squashed in the rush.',
    stats: ['Standard + FIFO', 'Keeps up to 14 days', 'Consumers pull'],
    power: Power(4, 5, 4, 5),
    facts: [
      'Decouples producers from consumers so spikes do not crush the backend.',
      'Visibility timeout (30 s default) hides a message while one worker handles it.',
      'Dead-letter queues catch messages that keep failing.',
      'FIFO queues keep order and process each message exactly once.',
    ],
    examTip: 'Orders spiking and the backend falling over? Put SQS in between as a buffer.',
    price: 'First 1 million requests a month are free.',
    pairs: ['lambda', 'sns', 'ec2'],
    cli: 'aws sqs send-message --queue-url https://sqs.ap-south-2.amazonaws.com/1234/orders --message-body "1 masala chai"',
    domain: 'tech',
  ),
  Service(
    id: 'sns', no: 16, name: 'Amazon SNS', nick: 'Pip', type: 'integration', rarity: 2,
    tagline: 'Shouts one message to many listeners.',
    analogy: 'A college broadcast group: one post, and every subscriber gets it at once.',
    stats: ['Pub/sub', 'Pushes to subscribers', 'Fan-out'],
    power: Power(5, 5, 5, 5),
    facts: [
      'Publishers send to a topic; subscribers can be SQS, Lambda, HTTP, email, SMS or mobile push.',
      'SNS to many SQS queues is the classic fan-out pattern.',
      'Message filtering lets each subscriber get only what it cares about.',
      'FIFO topics keep strict order when paired with FIFO queues.',
    ],
    examTip: 'SNS pushes to many (fan-out). SQS holds messages for consumers to pull.',
    price: 'First 1 million publishes a month are free.',
    pairs: ['sqs', 'lambda', 'cloudwatch'],
    cli: 'aws sns publish --topic-arn arn:aws:sns:ap-south-2:1234:results --message "Results are live!"',
    domain: 'tech',
  ),
  Service(
    id: 'cloudwatch', no: 17, name: 'Amazon CloudWatch', nick: 'Hoot', type: 'monitor', rarity: 2,
    tagline: 'Watches metrics, logs and alarms.',
    analogy: 'A night-watch owl staring at every dashboard and hooting the moment something looks off.',
    stats: ['Metrics + logs', 'Alarms', 'Dashboards'],
    power: Power(4, 5, 4, 4),
    facts: [
      'EC2 sends basic metrics every 5 minutes; detailed monitoring makes it 1 minute.',
      'Memory and disk usage need the CloudWatch agent.',
      'Alarms can notify SNS or trigger Auto Scaling.',
      'Logs Insights lets you query logs with a simple language.',
    ],
    examTip: 'Performance and health? CloudWatch. Who-did-what API history? CloudTrail.',
    price: 'Free tier includes 10 custom metrics and 10 alarms.',
    pairs: ['sns', 'ec2', 'lambda'],
    cli: 'aws cloudwatch put-metric-alarm --alarm-name HighCPU --metric-name CPUUtilization --threshold 80',
    domain: 'tech',
  ),
  Service(
    id: 'cloudtrail', no: 18, name: 'AWS CloudTrail', nick: 'Tracks', type: 'monitor', rarity: 2,
    tagline: 'Records who did what, and when.',
    analogy: 'Footprints in fresh snow: every API call leaves a trail you can follow back to who made it.',
    stats: ['90-day history free', 'API audit log', 'Multi-Region trails'],
    power: Power(3, 5, 4, 5),
    facts: [
      'Event history shows 90 days of management events at no cost.',
      'Trails deliver logs to S3 for long-term keeping.',
      'Data events (like S3 object reads) are opt-in and billed.',
      'Essential for security investigations and compliance.',
    ],
    examTip: '"Who deleted my bucket?" is a CloudTrail question, every time.',
    price: 'Event history is free; trails and data events are billed.',
    pairs: ['iam', 's3', 'cloudwatch'],
    cli: 'aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=DeleteBucket',
    domain: 'security',
  ),
];

final Map<String, Service> kSvc = {for (final s in kServices) s.id: s};

/// Words that point at each Cloudling (search + Puff).
const Map<String, List<String>> kAliases = {
  'ec2': ['ec2', 'elastic compute', 'instance', 'instances', 'virtual machine', 'vm', 'server', 'servo'],
  'lambda': ['lambda', 'serverless function', 'function', 'zip'],
  's3': ['s3', 'simple storage', 'bucket', 'buckets', 'object storage', 'glacier', 'bucky'],
  'ebs': ['ebs', 'elastic block', 'volume', 'disk', 'disky'],
  'rds': ['rds', 'relational', 'mysql', 'postgres', 'postgresql', 'aurora', 'sql database', 'rory'],
  'dynamodb': ['dynamodb', 'dynamo', 'nosql', 'key-value', 'dyna'],
  'elasticache': ['elasticache', 'cache', 'redis', 'memcached', 'valkey', 'blink'],
  'vpc': ['vpc', 'virtual private cloud', 'subnet', 'subnets', 'nat', 'cidr', 'fen'],
  'cloudfront': ['cloudfront', 'cdn', 'edge', 'jet'],
  'route53': ['route 53', 'route53', 'dns', 'domain', 'signy'],
  'elb': ['elb', 'load balancer', 'load balancing', 'alb', 'nlb', 'juggles'],
  'apigateway': ['api gateway', 'apigateway', 'api', 'gatey'],
  'iam': ['iam', 'identity', 'role', 'roles', 'policy', 'policies', 'permission', 'permissions', 'keeper'],
  'kms': ['kms', 'encryption', 'encrypt', 'key management', 'locky'],
  'sqs': ['sqs', 'queue', 'queues', 'quack'],
  'sns': ['sns', 'notification', 'pub/sub', 'pubsub', 'topic', 'fan-out', 'pip'],
  'cloudwatch': ['cloudwatch', 'metrics', 'alarm', 'alarms', 'monitoring', 'hoot', 'logs'],
  'cloudtrail': ['cloudtrail', 'audit', 'trail', 'who did', 'tracks'],
};
