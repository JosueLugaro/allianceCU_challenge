terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    name = "AWS VPC"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = aws_vpc.main.cidr_block
  availability_zone = "${data.aws_region.current.name}a"
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id = aws_subnet.main.id
  route_table_id = aws_route_table.route_table.id
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "aws_key" {
  key_name = "ansible-ssh-key"
  public_key = tls_private_key.key.public_key_openssh
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type	  = "Service"
      identifiers = ["ec2.amazonaws.com"] 
    }
  }
}

data "aws_iam_policy_document" "s3_write_access" {
  statement {
    actions   = ["s3:PutObject"]
    resources = [
      aws_s3_bucket.candidate-bucket-01.arn,
      "${aws_s3_bucket.candidate-bucket-01.arn}/*"
    ]
  }
}

resource "aws_iam_role" "ec2_iam_role" {
  name               = "ec2_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_role.json}"
}

resource "aws_iam_role_policy" "join_policy" {
  depends_on = [aws_iam_role.ec2_iam_role]
  name       = "join_policy"
  role       = "${aws_iam_role.ec2_iam_role.name}"
  policy     = "${data.aws_iam_policy_document.s3_write_access.json}"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = "${aws_iam_role.ec2_iam_role.name}"
}

resource "aws_instance" "app_server" {
  ami           = "ami-04e5276ebb8451442"
  instance_type = "t3.micro"
  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
  key_name = aws_key_pair.aws_key.key_name
  associate_public_ip_address = true
  subnet_id = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "AllianceCUServerInstance"
  }
}

resource "aws_s3_bucket" "candidate-bucket-01" {
  bucket = "candidate-bucket-01"
  force_destroy = true

  tags = {
    Name = "allianceCU_challenge_s3"
  }
}

data "aws_iam_policy_document" "allow_access_from_ec2" {
  statement {
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = [
      aws_s3_bucket.candidate-bucket-01.arn,
      "${aws_s3_bucket.candidate-bucket-01.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_ec2" {
  bucket = aws_s3_bucket.candidate-bucket-01.id
  policy = data.aws_iam_policy_document.allow_access_from_ec2.json
}
