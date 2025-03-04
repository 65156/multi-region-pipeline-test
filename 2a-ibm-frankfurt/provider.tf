terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.66.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.70"
    }
  }

  backend "s3" {
    bucket         = "ferarri-cicd-dtm8f"
    key            = "" 
    dynamodb_table = "terraform-state"
    region         = "eu-central-1"
    encrypt        = true
  }
}

provider "ibm" {
  region           = var.IBMC_DEFAULT_REGION
  ibmcloud_api_key = var.IBMC_AUTH_KEY
}

provider "aws" {
  region = var.AWS_DEFAULT_REGION
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}
######################
#### REMOTE STATE ####
######################
# data "terraform_remote_state" "0-global-services" {
#   backend = "s3"
#   config = {
#     bucket = "null"
#     key    = "0-global-services.tfstate"
#     region = "eu-central-1"
#   }
# }