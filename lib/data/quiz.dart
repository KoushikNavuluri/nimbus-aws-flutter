// Question bank. svc = linked Cloudling (null for concepts). d = exam domain.
// Domains follow the Cloud Practitioner outline: cloud, security, tech, billing.
class Question {
  const Question(this.id, this.svc, this.d, this.q, this.options, this.a, this.why);
  final String id;
  final String? svc;
  final String d;
  final String q;
  final List<String> options;
  final int a;
  final String why;
}

const kQuestions = <Question>[
  Question('s3-1', 's3', 'tech', 'What durability is S3 designed for?', ['99.9%', '99.99%', '99.999999999% (11 nines)', '100%'], 2, 'S3 stores data redundantly across multiple AZs and is designed for 11 nines of durability.'),
  Question('s3-2', 's3', 'tech', 'Old invoices are rarely opened, but must load in milliseconds when they are. Cheapest fit?', ['S3 Standard', 'S3 Glacier Instant Retrieval', 'S3 Glacier Deep Archive', 'EBS gp3'], 1, 'Glacier Instant Retrieval is for rarely accessed data that still needs millisecond access. Deep Archive takes hours.'),
  Question('s3-3', 's3', 'tech', 'True or false: S3 bucket names only need to be unique inside your own account.', ['True', 'False'], 1, 'Bucket names are globally unique across every AWS account.'),
  Question('s3-4', 's3', 'tech', 'Which feature moves objects to cheaper storage classes as they age?', ['Versioning', 'Lifecycle rules', 'Bucket policy', 'Transfer Acceleration'], 1, 'Lifecycle rules transition (or expire) objects automatically after a number of days.'),
  Question('ec2-1', 'ec2', 'billing', 'A rendering job can be stopped and restarted any time. Cheapest EC2 pricing?', ['On-Demand', 'Reserved Instances', 'Spot Instances', 'Dedicated Hosts'], 2, 'Spot uses spare capacity at up to 90% off. It can be interrupted, which this job tolerates.'),
  Question('ec2-2', 'ec2', 'tech', 'What does an AMI provide?', ['A firewall', 'The template (OS + software) an instance boots from', 'A load balancer', 'An IAM role'], 1, 'Amazon Machine Images are launch templates: OS, settings and installed software.'),
  Question('ec2-3', 'ec2', 'tech', 'Which instance family is built for memory-heavy work?', ['c', 't', 'r', 'g'], 2, 'r = RAM. c is compute, t is burstable, g is GPU.'),
  Question('lambda-1', 'lambda', 'tech', 'Maximum run time for one Lambda invocation?', ['5 minutes', '15 minutes', '1 hour', 'Unlimited'], 1, 'Lambda caps each invocation at 15 minutes.'),
  Question('lambda-2', 'lambda', 'tech', 'Run code whenever a photo lands in S3. Simplest approach?', ['Poll S3 from an EC2 cron job', 'Trigger Lambda from the S3 event', 'Use CloudTrail', 'Use a network ACL'], 1, 'S3 event notifications can invoke Lambda directly. No servers, no polling.'),
  Question('lambda-3', 'lambda', 'billing', 'How is Lambda billed?', ['Per server per month', 'By requests and compute duration', 'A flat yearly fee', 'Only by storage'], 1, 'You pay per request and per GB-second of compute, billed by the millisecond.'),
  Question('ebs-1', 'ebs', 'tech', 'An EBS volume can attach to EC2 instances in…', ['Any Region', 'Any AZ in the Region', 'The same AZ', 'Any account'], 2, 'EBS volumes are AZ-scoped.'),
  Question('ebs-2', 'ebs', 'tech', "Fastest way to get an EBS volume's data into another AZ?", ['Detach and reattach it', 'Snapshot it and restore there', 'Use CloudFront', 'Turn on EBS Multi-AZ'], 1, 'Snapshots are stored regionally and can be restored as a new volume in any AZ.'),
  Question('ebs-3', 'ebs', 'tech', 'EBS is which kind of storage?', ['Object', 'Block', 'Shared file (NFS)', 'Archive'], 1, 'EBS is block storage. S3 is object storage; EFS is shared file storage.'),
  Question('rds-1', 'rds', 'tech', 'The main purpose of RDS Multi-AZ?', ['Faster reads', 'High availability with automatic failover', 'Cheaper storage', 'Global replication'], 1, 'A synchronous standby in another AZ takes over automatically if the primary fails.'),
  Question('rds-2', 'rds', 'tech', 'Reporting dashboards slow down your main database with heavy reads. What helps?', ['A Multi-AZ standby', 'Read replicas', 'A bigger EBS volume', 'A security group'], 1, 'Read replicas take read traffic off the primary.'),
  Question('rds-3', 'rds', 'security', 'With RDS, who patches the database engine?', ['You, over SSH', 'AWS, in your maintenance window', 'Nobody', 'Your ISP'], 1, 'RDS is managed: AWS handles engine patching. You choose when.'),
  Question('ddb-1', 'dynamodb', 'tech', 'DynamoDB is best described as…', ['A relational SQL database', 'A serverless key-value and document database', 'A data warehouse', 'Only an in-memory cache'], 1, 'Serverless NoSQL with single-digit millisecond performance.'),
  Question('ddb-2', 'dynamodb', 'tech', 'Maximum size of one DynamoDB item?', ['400 KB', '4 MB', '64 KB', '5 TB'], 0, 'Items cap at 400 KB. Store big blobs in S3 and keep a pointer.'),
  Question('ddb-3', 'dynamodb', 'billing', 'Traffic is spiky and unpredictable. Which capacity mode?', ['Provisioned', 'On-demand', 'Reserved', 'Spot'], 1, 'On-demand scales instantly and bills per request.'),
  Question('ec-1', 'elasticache', 'tech', 'RDS is overloaded by the same product-page queries. Best fix?', ['Add ElastiCache in front', 'Move to Glacier', 'Add a network ACL', 'Turn on CloudTrail'], 0, 'Caching hot reads in memory takes the pressure off the database.'),
  Question('ec-2', 'elasticache', 'tech', 'Where does ElastiCache keep data?', ['Magnetic tape', 'In memory', 'In S3', 'At edge locations'], 1, 'In-memory, which is why reads take microseconds.'),
  Question('ec-3', 'elasticache', 'tech', 'A good fit for ElastiCache?', ['Long-term archives', 'User session storage', 'DNS routing', 'Encryption keys'], 1, 'Sessions, leaderboards and hot query results are classic cache jobs.'),
  Question('vpc-1', 'vpc', 'security', "What makes a subnet 'public'?", ['A public name', 'A route to an internet gateway', 'Using NACLs', 'Being in us-east-1'], 1, 'Public = its route table sends 0.0.0.0/0 to an internet gateway.'),
  Question('vpc-2', 'vpc', 'security', 'Security groups are…', ['Stateless, allow and deny', 'Stateful, allow rules only', 'Stateful, deny only', 'Applied per Region'], 1, 'They remember connections and only support allow rules.'),
  Question('vpc-3', 'vpc', 'security', 'Private instances must download updates but stay unreachable from the internet. Use a…', ['Internet gateway', 'NAT gateway', 'Route 53 record', 'Public IP on each'], 1, 'NAT gateways allow outbound-only internet access for private subnets.'),
  Question('cf-1', 'cloudfront', 'tech', 'What does CloudFront use to serve users with low latency?', ['Availability Zones', 'Edge locations', 'Dedicated Hosts', 'VPC peering'], 1, 'Content is cached at edge locations close to users.'),
  Question('cf-2', 'cloudfront', 'security', 'Keep an S3 origin private and reachable only through CloudFront with…', ['Origin Access Control', 'A NAT gateway', 'Spot', 'A read replica'], 0, 'OAC lets CloudFront sign requests to a bucket that stays private.'),
  Question('cf-3', 'cloudfront', 'tech', 'True or false: CloudFront can only cache content from S3.', ['True', 'False'], 1, 'Any HTTP origin works: ALB, EC2, or your own server.'),
  Question('r53-1', 'route53', 'tech', 'Send each user to the Region with the lowest latency for them:', ['Simple', 'Weighted', 'Latency-based', 'Multivalue'], 2, 'Latency-based routing picks the Region that answers fastest for that user.'),
  Question('r53-2', 'route53', 'tech', 'Route 53 is AWS…', ['CDN', 'DNS service', 'load balancer', 'firewall'], 1, 'DNS: names to addresses, with health checks and routing policies.'),
  Question('r53-3', 'route53', 'tech', 'Active-passive disaster recovery with health checks uses which policy?', ['Failover', 'Geolocation', 'Weighted', 'Simple'], 0, 'Failover routing switches to the standby when the primary health check fails.'),
  Question('elb-1', 'elb', 'tech', 'Route /api/* and /images/* to different servers:', ['Network Load Balancer', 'Application Load Balancer', 'Gateway Load Balancer', 'Route 53 simple'], 1, 'ALB works at layer 7 and understands paths and hosts.'),
  Question('elb-2', 'elb', 'tech', 'Ultra-low latency TCP with a static IP per AZ:', ['ALB', 'NLB', 'CloudFront', 'API Gateway'], 1, 'Network Load Balancers work at layer 4 and offer static IPs.'),
  Question('elb-3', 'elb', 'tech', 'A target fails health checks. The load balancer…', ['Deletes it', 'Stops sending it traffic', 'Restarts the Region', 'Emails AWS'], 1, 'Unhealthy targets are taken out of rotation until they recover.'),
  Question('apig-1', 'apigateway', 'tech', 'The classic serverless API stack?', ['ELB + EC2 + RDS', 'API Gateway + Lambda + DynamoDB', 'CloudFront + EBS', 'SQS + Glacier'], 1, 'No servers to manage anywhere in the chain.'),
  Question('apig-2', 'apigateway', 'tech', 'Protect a backend from too many requests with…', ['Throttling and usage plans', 'Multi-AZ', 'Snapshots', 'Lifecycle rules'], 0, 'API Gateway can rate-limit per client or globally.'),
  Question('apig-3', 'apigateway', 'tech', 'Which API type supports two-way, real-time messages?', ['REST', 'HTTP', 'WebSocket', 'SOAP'], 2, 'WebSocket APIs keep a live connection open for chat, games and dashboards.'),
  Question('iam-1', 'iam', 'security', 'An app on EC2 needs to read S3. Most secure option?', ['Access keys in the code', 'An IAM role on the instance', 'Use the root user', 'Make the bucket public'], 1, 'Roles hand out temporary credentials that rotate automatically.'),
  Question('iam-2', 'iam', 'security', 'One policy allows s3:*, another explicitly denies s3:DeleteObject. Delete is…', ['Allowed', 'Denied', 'Allowed for root only', 'Random'], 1, 'An explicit Deny always beats an Allow.'),
  Question('iam-3', 'iam', 'security', 'Best practice for the root user:', ['Use it daily', 'Turn on MFA and lock it away', 'Share it with the team', 'Delete it'], 1, 'Use root only for the few tasks that require it.'),
  Question('kms-1', 'kms', 'security', 'KMS mainly…', ['Stores files', 'Creates and controls encryption keys', 'Routes DNS', 'Balances load'], 1, 'Key Management Service: keys, policies, rotation, audit.'),
  Question('kms-2', 'kms', 'security', 'Where can you see every use of a KMS key?', ['CloudTrail', 'Route 53', 'EBS', 'SNS'], 0, 'KMS API calls are logged in CloudTrail.'),
  Question('kms-3', 'kms', 'security', 'Envelope encryption means…', ['Encrypting emails', 'A data key encrypts data; a KMS key encrypts the data key', 'Paying twice', 'Encrypting only metadata'], 1, 'It is fast for big data and keeps the master key inside KMS.'),
  Question('sqs-1', 'sqs', 'tech', 'Order spikes crush your processing servers. Decouple with…', ['SQS', 'CloudFront', 'Route 53', 'KMS'], 0, 'A queue absorbs the spike; workers drain it at their own pace.'),
  Question('sqs-2', 'sqs', 'tech', 'Strict ordering and exactly-once processing:', ['Standard queue', 'FIFO queue', 'Standard SNS topic', 'S3 events'], 1, 'FIFO queues preserve order and de-duplicate.'),
  Question('sqs-3', 'sqs', 'tech', 'Messages that keep failing go to a…', ['Dead-letter queue', 'Glacier vault', 'NAT gateway', 'Read replica'], 0, 'DLQs park poison messages so you can inspect them.'),
  Question('sns-1', 'sns', 'tech', 'One event must reach email, a Lambda and three SQS queues at once:', ['SQS alone', 'An SNS topic (fan-out)', 'CloudTrail', 'An EBS snapshot'], 1, 'Publish once to SNS; every subscriber gets a copy.'),
  Question('sns-2', 'sns', 'tech', 'SNS delivers messages by…', ['Consumers polling', 'Pushing to subscribers', 'Writing to disk', 'Edge caching'], 1, 'SNS pushes. SQS waits to be pulled.'),
  Question('sns-3', 'sns', 'tech', 'True or false: SNS can send SMS text messages.', ['True', 'False'], 0, 'SMS, email, mobile push, HTTP, Lambda and SQS are all subscriber types.'),
  Question('cw-1', 'cloudwatch', 'tech', 'Get alerted when EC2 CPU stays above 80%:', ['CloudTrail', 'A CloudWatch alarm', 'An IAM policy', 'Route 53'], 1, 'Alarms watch a metric and act (SNS, Auto Scaling) when it crosses a threshold.'),
  Question('cw-2', 'cloudwatch', 'tech', 'EC2 memory usage needs…', ['Nothing, it is default', 'The CloudWatch agent', 'KMS', 'A NAT gateway'], 1, 'Memory lives inside the OS, so an agent has to report it.'),
  Question('cw-3', 'cloudwatch', 'tech', 'Default (basic) EC2 metric interval:', ['1 second', '1 minute', '5 minutes', '1 hour'], 2, 'Basic monitoring is 5 minutes; detailed monitoring is 1 minute.'),
  Question('ct-1', 'cloudtrail', 'security', 'A production bucket was deleted. Which service tells you who did it?', ['CloudWatch', 'CloudTrail', 'SNS', 'ElastiCache'], 1, 'CloudTrail logs API calls with the identity that made them.'),
  Question('ct-2', 'cloudtrail', 'security', 'CloudTrail event history is free for…', ['7 days', '30 days', '90 days', 'Forever'], 2, '90 days of management events, no setup needed.'),
  Question('ct-3', 'cloudtrail', 'security', 'CloudTrail records…', ['CPU metrics', 'API calls and account activity', 'DNS queries', 'Cache hits'], 1, 'It is the audit log of your AWS account.'),
  Question('c-1', null, 'security', 'Shared responsibility: who handles physical security of data centers?', ['You', 'AWS', 'Both equally', 'Your ISP'], 1, 'Security OF the cloud is on AWS.'),
  Question('c-2', null, 'cloud', 'Each AWS Region has at least how many Availability Zones?', ['1', '2', '3', '10'], 2, 'AWS builds Regions with three or more AZs.'),
  Question('c-3', null, 'cloud', 'Paying for what you use instead of buying servers upfront is…', ['Trading capex for opex', 'Economies of scale', 'Reserved capacity', 'Multi-tenancy'], 0, 'One of the six advantages of cloud computing.'),
  Question('c-4', null, 'cloud', 'Which Well-Architected pillar is about recovering from failure?', ['Reliability', 'Cost optimization', 'Sustainability', 'Performance efficiency'], 0, 'Reliability: multi-AZ, backups, tested recovery.'),
  Question('c-5', null, 'cloud', 'Which of these is SaaS?', ['Amazon EC2', 'Gmail', 'Amazon VPC', 'AWS Elastic Beanstalk'], 1, 'You just use it. No servers or platform to manage.'),
  Question('c-6', null, 'billing', 'Which tool estimates the monthly cost of an architecture before you build it?', ['AWS Pricing Calculator', 'CloudTrail', 'Route 53', 'AWS Artifact'], 0, 'The Pricing Calculator models costs before you spend a rupee.'),
  Question('c-7', null, 'billing', 'Get an alert when monthly spend passes ₹2,000:', ['AWS Budgets', 'CloudTrail', 'KMS', 'Route 53'], 0, 'Budgets sends alerts on actual or forecasted spend.'),
  Question('c-8', null, 'security', 'Where do you download AWS compliance reports like SOC and ISO?', ['AWS Artifact', 'AWS Config', 'Amazon Inspector', 'AWS Budgets'], 0, 'Artifact is the self-service portal for compliance documents.'),
];

const Map<String, (String, int)> kDomains = {
  'cloud': ('Cloud concepts', 24),
  'security': ('Security & compliance', 30),
  'tech': ('Technology & services', 34),
  'billing': ('Billing & pricing', 12),
};

List<Question> questionsFor(String? svc) => [for (final q in kQuestions) if (q.svc == svc) q];

Question? questionById(String id) {
  for (final q in kQuestions) {
    if (q.id == id) return q;
  }
  return null;
}

/// A shuffled 12-question exam (seeded so a round stays stable while you take it).
List<Question> mockExam(int seed, [int n = 12]) {
  var x = seed % 2147483647;
  if (x <= 0) x += 2147483646;
  double rnd() {
    x = (x * 48271) % 2147483647;
    return x / 2147483647;
  }

  final pool = [...kQuestions];
  for (var i = pool.length - 1; i > 0; i--) {
    final j = (rnd() * (i + 1)).floor();
    final t = pool[i];
    pool[i] = pool[j];
    pool[j] = t;
  }
  return pool.sublist(0, n);
}
