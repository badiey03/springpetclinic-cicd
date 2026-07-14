provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "springpetclinic-cicd"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "badiey03"
    }
  }
}