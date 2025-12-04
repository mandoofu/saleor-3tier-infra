terraform {
  backend "s3" {
    bucket         = "saleor-store-251204"  
    key            = "prod/terraform.tfstate"     
    region         = "ap-northeast-3"             
    dynamodb_table = "tf-state-lock"
    encrypt        = true
  }
}
