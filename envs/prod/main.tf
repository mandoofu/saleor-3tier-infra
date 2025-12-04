terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.env}"
}

# 1. VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name_prefix
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}c"]
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    "Environment" = var.env
    "Project"     = var.project_name
  }
}

# 2. EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${local.name_prefix}-eks"
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 3         # ✅ prod: dev보다 조금 여유 있게
      max_size       = 6
      desired_size   = 3
    }
  }

  enable_irsa = true

  tags = {
    "Environment" = var.env
    "Project"     = var.project_name
  }
}

# 3. ALB SG
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs_to_alb
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs_to_alb
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-alb-sg"
    Environment = var.env
    Project     = var.project_name
  }
}

# 4. RDS PostgreSQL
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${local.name_prefix}-pg"

  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.medium"  # ✅ 필요하면 m5.large 등으로 조정 가능
  allocated_storage = 100             # ✅ dev보다 여유

  db_name  = var.saleor_db_name
  username = var.db_username
  password = var.db_password

  multi_az                = true       # ✅ prod: 가용성 고려 (비용 아끼려면 false 로 변경 가능)
  publicly_accessible     = false
  storage_encrypted       = true
  deletion_protection     = true
  skip_final_snapshot     = false
  backup_retention_period = 14         # ✅ dev보다 길게

  vpc_security_group_ids = [aws_security_group.rds.id]

  subnet_ids = module.vpc.private_subnets

  tags = {
    Environment = var.env
    Project     = var.project_name
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "RDS SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-rds-sg"
    Environment = var.env
    Project     = var.project_name
  }
}

# 5. ElastiCache Redis
module "redis" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 6.0"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.small"
  num_cache_nodes      = 1
  transit_encryption_enabled   = true
  at_rest_encryption_enabled   = true

  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  security_group_ids     = [aws_security_group.redis.id]
  automatic_failover_enabled = false   # ✅ 비용/요구사항에 맞게 true로 바꿀 수 있음

  tags = {
    Environment = var.env
    Project     = var.project_name
  }
}

resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Redis SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-redis-sg"
    Environment = var.env
    Project     = var.project_name
  }
}

# 6. Media S3
resource "aws_s3_bucket" "saleor_media" {
  bucket = var.saleor_media_bucket_name

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Environment = var.env
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "saleor_media_pab" {
  bucket = aws_s3_bucket.saleor_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "saleor_media_sse" {
  bucket = aws_s3_bucket.saleor_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 7. ECR
resource "aws_ecr_repository" "saleor_core" {
  name = "${local.name_prefix}-core"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "saleor_storefront" {
  name = "${local.name_prefix}-storefront"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "saleor_dashboard" {
  name = "${local.name_prefix}-dashboard"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 8. Outputs
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  value = module.eks.cluster_certificate_authority_data
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "redis_endpoint" {
  value = module.redis.primary_endpoint_address
}
