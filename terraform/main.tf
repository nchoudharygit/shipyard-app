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
  public_key = file("~/.ssh/shipyard-key.pub") # fixed path
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
    cidr_blocks = [var.my_ip]
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
  tags                   = { Name = "shipyard-app-server" }
}