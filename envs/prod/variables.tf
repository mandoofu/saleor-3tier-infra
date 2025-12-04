variable "aws_region" {
  type    = string
  default = "ap-northeast-3"   # ✅ 오사카
}

variable "project_name" {
  description = "리소스 이름 prefix"
  type        = string
  default     = "saleor-3tier"
}

variable "env" {
  description = "환경명 (dev, prod 등)"
  type        = string
  default     = "prod"         # ✅ prod
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"     # ✅ dev(10.10.x)와 다른 대역
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "saleor_db_name" {
  type    = string
  default = "saleor"
}

variable "saleor_media_bucket_name" {
  description = "상품 이미지/정적 파일용 S3 버킷 (prod)"
  type        = string
}

variable "allowed_cidrs_to_alb" {
  description = "ALB에 접근 허용할 CIDR 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"] 
}
