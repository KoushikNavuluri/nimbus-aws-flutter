/// Spaced-repetition deck. Cards unlock when their Cloudling is collected (svc null = always on).
class Flash {
  const Flash(this.id, this.svc, this.front, this.back);
  final String id;
  final String? svc;
  final String front;
  final String back;
}

const kFlash = <Flash>[
  Flash('f-ec2-1', 'ec2', 'Interruptible job, cheapest EC2 option?', 'Spot Instances: up to 90% off.'),
  Flash('f-ec2-2', 'ec2', 'What is an AMI?', 'The template an EC2 instance boots from (OS + software).'),
  Flash('f-lam-1', 'lambda', 'Lambda max run time?', '15 minutes per invocation.'),
  Flash('f-lam-2', 'lambda', 'Lambda free tier per month?', '1M requests + 400,000 GB-seconds.'),
  Flash('f-s3-1', 's3', 'S3 durability?', '99.999999999%: eleven nines.'),
  Flash('f-s3-2', 's3', 'Largest single S3 object?', '5 TB. Use multipart upload for big files.'),
  Flash('f-s3-3', 's3', 'Rarely read, needs ms access?', 'S3 Glacier Instant Retrieval.'),
  Flash('f-ebs-1', 'ebs', 'EBS scope?', 'One Availability Zone.'),
  Flash('f-rds-1', 'rds', 'Multi-AZ vs read replica?', 'Multi-AZ = availability. Replicas = read scaling.'),
  Flash('f-ddb-1', 'dynamodb', 'DynamoDB max item size?', '400 KB.'),
  Flash('f-ec-1', 'elasticache', 'Repeated reads crushing your DB?', 'Cache them in ElastiCache.'),
  Flash('f-vpc-1', 'vpc', 'Security group vs NACL?', 'SG: stateful, allow only. NACL: stateless, allow + deny.'),
  Flash('f-vpc-2', 'vpc', 'Private subnet needs outbound internet?', 'NAT gateway.'),
  Flash('f-cf-1', 'cloudfront', 'CloudFront caches where?', 'At 600+ edge locations.'),
  Flash('f-r53-1', 'route53', 'Why "53"?', 'DNS runs on port 53.'),
  Flash('f-r53-2', 'route53', 'Fastest Region per user?', 'Latency-based routing.'),
  Flash('f-elb-1', 'elb', 'Path-based routing?', 'Application Load Balancer (layer 7).'),
  Flash('f-apig-1', 'apigateway', 'Serverless API trio?', 'API Gateway + Lambda + DynamoDB.'),
  Flash('f-iam-1', 'iam', 'Allow vs explicit Deny?', 'Explicit Deny always wins.'),
  Flash('f-iam-2', 'iam', 'EC2 app needs AWS access?', 'IAM role. Never hard-code keys.'),
  Flash('f-kms-1', 'kms', 'Who logs KMS key use?', 'CloudTrail.'),
  Flash('f-sqs-1', 'sqs', 'SQS default visibility timeout?', '30 seconds.'),
  Flash('f-sqs-2', 'sqs', 'Order + exactly-once?', 'FIFO queue.'),
  Flash('f-sns-1', 'sns', 'SNS + SQS together?', 'Fan-out: one publish, many queues.'),
  Flash('f-cw-1', 'cloudwatch', 'Basic EC2 metric interval?', '5 minutes (1 with detailed).'),
  Flash('f-ct-1', 'cloudtrail', '"Who deleted it?"', 'CloudTrail.'),
  Flash('f-c-1', null, 'Security OF the cloud is…', 'AWS: buildings, hardware, network, hypervisor.'),
  Flash('f-c-2', null, 'Minimum AZs per Region?', 'Three.'),
  Flash('f-c-3', null, 'Six pillars?', 'Ops excellence, security, reliability, performance, cost, sustainability.'),
  Flash('f-c-4', null, 'Capex vs opex?', 'Upfront purchases vs pay-as-you-go spending.'),
];

const kBoxDays = [0, 1, 3, 7, 14, 30];
