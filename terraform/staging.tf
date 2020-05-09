/*====
Variables used across all modules
======*/
locals {
  staging_availability_zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

# Configure the AWS Provider

provider "aws" {
  version = "~> 2.8"
  region  = var.region
  profile = "bops-staging"

  allowed_account_ids = ["735309401039"]
}

# resource "aws_key_pair" "key" {
#   key_name   = "staging_key"
#   public_key = "${file("staging_key.pub")}"
# }

module "networking" {
  source               = "./modules/networking"
  environment          = "staging"
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidr = ["10.0.10.0/24", "10.0.20.0/24"]
  region               = var.region
  availability_zones   = "${local.staging_availability_zones}"
  key_name             = "staging_key"
}
