
module "vpc" {
  source          = "./module/vpc"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets = ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"]
  environment = "prod"
  region-app = "us-east-1"
  profile = "default"
}


