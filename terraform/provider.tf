# Downloads AWS and Docker and then logs in to both

# Specify where to find the AWS & Docker providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.7.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.0"
    }
  }
}

# Configure AWS credentials & region
provider "aws" {
  region     = var.aws_region
}

# Fetch an ECR auth token so Terraform's Docker provider can log in
# Takes your exisiting AWS credentials and then asks for an ECR temp login token
data "aws_ecr_authorization_token" "registry" {}

# Docker takes the 3 parts of the token to now be able to push an image
# to the ECR address
provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.registry.proxy_endpoint
    username = data.aws_ecr_authorization_token.registry.user_name
    password = data.aws_ecr_authorization_token.registry.password
  }
}