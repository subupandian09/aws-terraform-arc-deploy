
terraform {

  required_version = ">=0.12.0"



  backend "s3" {
    region         = "us-east-1"
    profile        = "default"
    bucket         = "testlab021222-06"
    key            = "terraform.tfstate"
    dynamodb_table = "terraform_state"

  }
}








