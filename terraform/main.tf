terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.region
}

#Ecr repository
resource "aws_ecr_repository" "shipyard_app" {
  name = "shipyard-app"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name = "shipyard-app-repo"
  }
}
# create key pair
resource "aws_key_pair" "pem_key" {
  key_name   = var.key_pair_name
  public_key = var.public_key
}
# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "shipyard-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach ECR policy
resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
# Attach SSM policy
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
# Instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "shipyard-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
# network
# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "shipyard-vpc"
  }
}
# Create public subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "shipyard-public-subnet"
  }
  availability_zone = "${var.region}a"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "shipyard-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "shipyard-public-rt"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "sg" {
  name        = "shipyard-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "shipyard-sg"
  }
  # Allow SSH from your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow for application traffic (example: port 1000)
  ingress {
    from_port   = 1000
    to_port     = 1000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance
resource "aws_instance" "app_server" {
  ami                    = "ami-0dee22c13ea7a9a67" # ubuntu 22.04 in ap-south-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.pem_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  tags                   = { Name = "shipyard-app-server" }
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install -y docker.io unzip
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker ubuntu
  # SSM Agent
  sudo snap install amazon-ssm-agent --classic
  sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
EOF
}

resource "aws_sns_topic" "app_notifications" {
  name = "shipyard-app-notifications"
  tags = {
    Name = "shipyard-sns-topic"
  }
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.app_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "shipyard-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when CPU exceeds 80%"
  dimensions = {
    InstanceId = aws_instance.app_server.id
  }
  alarm_actions = [aws_sns_topic.app_notifications.arn]
}

resource "aws_cloudwatch_log_group" "shipyard_log_group" {
  name = "/shipyard-app"
  retention_in_days = 7
}