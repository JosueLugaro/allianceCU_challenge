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
    resources = ["arn:aws:s3:::candidate-bucket-01"]
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
  ami           = "ami-0e001c9271cf7f3b9"
  instance_type = "t3.micro"
  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
  key_name = aws_key_pair.aws_key.key_name

  tags = {
    Name = "AllianceCUServerInstance"
  }
}

resource "aws_s3_bucket" "candidate-bucket-01" {
  bucket = "candidate-bucket-01"

  tags = {
    Name = "allianceCU_challenge_s3"
  }
}

