// infra-terraform/envs/dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "saleor-store-251204"  # bootstrap에서 만든 버킷
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-3"
    dynamodb_table = "tf-state-lock"
    encrypt        = true
  }
}
