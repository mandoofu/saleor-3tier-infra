// infra-terraform/envs/dev/variables.tf
variable "aws_region" {
  type    = string
  default = "ap-northeast-3"
}

variable "project_name" {
  description = "리소스 이름 prefix"
  type        = string
  default     = "saleor-3tier"
}

variable "env" {
  description = "환경명 (dev, prod 등)"
  type        = string
  default     = "dev"
}

variable "eks_public_access_cidrs" {
  description = "EKS API public endpoint에 접근을 허용할 CIDR 목록 (운영에서는 회사 고정 IP만 허용 권장)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # dev에서는 0.0.0.0/0 허용, prod에서만 좁히는 식으로 사용
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.10.11.0/24", "10.10.12.0/24"]
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
  description = "saleor_media_bucket_251204"
  type        = string
}

variable "allowed_cidrs_to_alb" {
  description = "ALB에 접근 허용할 CIDR 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
