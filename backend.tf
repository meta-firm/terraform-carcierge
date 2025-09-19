terraform {
  backend "s3" {
    bucket         = "terraform-state-carcierge-staging"
    key            = "terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock-carcierge-staging"
    encrypt        = true
  }
}