terraform {
  backend "s3" {
    bucket = "terraform-state-ups-2025"
    key    = "terraform.tfstate.proyecto-final-grupo2"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


provider "kubernetes" {
  alias                  = "_internal"
  host                   = var.kubernetes_host
  cluster_ca_certificate = base64decode(var.kubernetes_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.kubernetes_cluster_name, "--region", var.aws_region]
    command     = "aws"
  }
}

data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = "terraform-state-ups-2025"
    key    = "terraform.tfstate.base"
    region = "us-east-1"
  }
}