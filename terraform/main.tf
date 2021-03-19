module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "github-runners-vpc"
  cidr = var.vpc_cidr
  azs             = var.vpc_azs
  public_subnets  = module.subnet_addrs.networks[*].cidr_block
  enable_dynamodb_endpoint = true
  tags = var.tags
}

module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"
  base_cidr_block = var.vpc_cidr
  networks = [
    {
      name     = "one"
      new_bits = 4
    },
    {
      name     = "two"
      new_bits = 4
    },
    {
      name     = "three"
      new_bits = 4
    }
  ]
}

resource "aws_autoscaling_group" "runners" {
  name                      = "ci-runners-asg"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  placement_group           = aws_placement_group.test.id
  launch_configuration      = aws_launch_configuration.foobar.name
  vpc_zone_identifier       = module.vpc.public_subnets
  tags = var.tags 
  launch_template {
    id      = aws_launch_template.runners.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "example" {
  name                   = "foobar3-terraform-test"
  autoscaling_group_name = aws_autoscaling_group.runners.name
  policy_type = 
}

resource "aws_launch_template" "runners" {
  name_prefix   = "ci-runner"
  image_id      = data.aws_ami.runner.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.github_runners.id]
  user_data = filebase64("${path.module}/example.sh")

  network_interfaces {
    associate_public_ip_address = true
    security_groups = []
  }

  iam_instance_profile {
    name = "test"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "test"
    }
  }
}

data "aws_ami" "runner" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_dynamodb_table" "github-runner-locks" {
  name           = "GithubRunnerLocks"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "lock_key"
  range_key      = "sort_key"
  tags = var.tags
}

resource "aws_dynamodb_table" "github-runner-queue" {
  name           = "GithubRunnerQueue"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"
  tags = var.tags
}

resource "aws_security_group" "github_runners" {
  name = "Github Runner"
  vpc_id = module.vpc.vpc_id	
  description = "Security group to enable github runners "
  tags = var.tags
}

resource "aws_iam_role" "runner_role" {
  name = "Runner Policy"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "test_policy" {
  name = "RunnerPolicy"
  role = aws_iam_role.test_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "cloudwatch:PutMetricData",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "cloudwatch:namespace": "github.actions"
                }
            }
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters",
                "ec2:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "sqs:DeleteMessage",
                "s3:GetObject",
                "dynamodb:PutItem",
                "autoscaling:CompleteLifecycleAction",
                "dynamodb:DeleteItem",
                "autoscaling:SetInstanceProtection",
                "sqs:ReceiveMessage",
                "dynamodb:GetItem",
                "dynamodb:UpdateItem",
                "autoscaling:RecordLifecycleActionHeartbeat"
            ],
            "Resource": [
                "arn:aws:dynamodb:*:827901512104:table/GitHubRunnerLocks",
                "arn:aws:sqs:*:827901512104:actions-runner-requests",
                "arn:aws:autoscaling:*:827901512104:autoScalingGroup:*:autoScalingGroupName/AshbRunnerASG",
                "arn:aws:s3:::airflow-ci-assets//*",
                "arn:aws:s3:::airflow-ci-assets"
            ]
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParametersByPath",
                "dynamodb:UpdateItem",
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": [
                "arn:aws:ssm:*:827901512104:parameter/runners//*",
                "arn:aws:dynamodb:*:827901512104:table/GithubRunnerQueue"
            ]
        }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "test_policy" {
  name = "GithubCloudWatchLogs"
  role = aws_iam_role.test_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "ssm:GetParameter"
            ],
            "Resource": [
                "arn:aws:logs:*:827901512104:log-group:GitHubRunners:log-stream:*",
                "arn:aws:logs:*:827901512104:log-group:*",
                "arn:aws:ssm:*:*:parameter/runners/apache/airflow/AmazonCloudWatch-*"
            ]
        }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

