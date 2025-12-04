aws_region   = "ap-northeast-3"
project_name = "saleor-3tier"
env          = "prod"

# ✅ prod DB 계정은 dev와 다르게 가져가는 걸 권장
db_username = "saleor_prod"
db_password = "StrongPassword123!"

# ✅ dev와 다른 VPC CIDR (variables.tf default와 동일하게 쓰거나 여기서 override 가능)
vpc_cidr        = "10.20.0.0/16"
public_subnets  = ["10.20.1.0/24", "10.20.2.0/24"]
private_subnets = ["10.20.11.0/24", "10.20.12.0/24"]

# ✅ prod용 media 버킷 (dev랑 이름 다르게)
saleor_media_bucket_name = "saleor-media-prod-251204"

# ✅ 초반에는 0.0.0.0/0 쓰더라도, 안정되면 회사/집 IP만 허용하는 걸 강력 추천
allowed_cidrs_to_alb = ["0.0.0.0/0"]
