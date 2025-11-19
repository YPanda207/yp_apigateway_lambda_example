provider "aws" {
  # 👇 Dummy credentials so the provider stops looking at EC2 metadata / real accounts
  access_key = "dummy"
  secret_key = "dummy"

  # 👇 Turn off all real AWS validation calls
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  default_tags {
    tags = {
      yp_tagId       = var.tag_id
      yp_environment = var.yp_environment
    }
  }
}
terraform {
  required_version = ">= 1.13.5"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "local" {
    path = "state/yp-lambda-service-terraform.tfstate"
  }
}

# For actual AWS deploy
# provider "aws" {
#   region = "us-east-1"
#   default_tags {
#     tags = {
#       yp-tagId       = var.tagId
#       yp-environment = var.yp_environment
#     }
#   }
# }

# terraform {
#   required_providers {
#     aws = {
#       source  = "harshicorp/aws"
#       version = "~> 5.0"
#     }
#   }
#   backend "s3" {
#     bucket  = "yp-bucket"
#     key     = "terraform/state/yp-lambda-service-terraform.tfstate"
#     region  = "us-east-1"
#     encrypt = true
#   }
# }
