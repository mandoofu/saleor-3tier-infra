// infra-terraform/bootstrap/main.tf
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-3"
}

variable "tf_state_bucket_name" {
  description = "Terraform state S3 bucket name (must be globally unique)"
  type        = string
  default     = "saleor-store-251204" 
}

variable "tf_state_dynamodb_table" {
  description = "Terraform state 락용 DynamoDB 테이블 이름"
  type        = string
  default     = "tf-state-lock"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = var.tf_state_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_sse" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "tf_state_lock" {
  name         = var.tf_state_dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
