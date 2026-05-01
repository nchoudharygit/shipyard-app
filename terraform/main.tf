# Terraform configuration
terraform {
  required_providers {
    aws = { source  = "hashicorp/aws", version = "~> 4.0" }
  }
}

provider "aws" {
  region = var.region
}
# network 
# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "foodrush-vpc" }
}

#public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.  0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"    
  tags = { Name = "foodrush-public-subnet" }

}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "foodrush-igw" }
}

# Create a Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "foodrush-public-rt" }
}

# Create a Route to allow internet access
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#### security #####
# Create a Security Group
resource "aws_security_group" "web_sg" {
  name        = "foodrush-app-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  #ssh access
    ingress {
        description = "SSH access"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Replace with your desired IP range
    }

    # App traffic #
    ingress {
        description = "Allow HTTP traffic"
        from_port   = 1000
        to_port     = 1000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Replace with your desired IP range
    }

    # outbound traffic
    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]  # Replace with your desired IP range
    }
    tags = { Name = "foodrush-app-sg" }
}
    # Create an EC2 instance
resource "aws_instance" "app_server" {
  ami           = "ami-0f5ee92e2d63afc18" # Ubuntu Server 20.04 LTS (HVM), SSD Volume Type - ap-south-1
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name      = var.key_pair_name
  user_data     = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install -y nginx
                sudo systemctl start nginx
                sudo systemctl enable nginx
                echo "Welcome to FoodRush!" > /var/www/html/index.html
                EOF
  tags = { Name = "foodrush-app-server" , Environment = "dev"}
}