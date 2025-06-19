terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "${var.account_id}-terraform-state"

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_ownership_controls" "terraform_state_bucket_control" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "terraform_state_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.terraform_state_bucket_control]

  bucket = aws_s3_bucket.terraform_state_bucket.id
  acl    = "private"
}
