variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "grupo" {
  type        = string
  description = "grupo-2"
  default= "grupo-2"
}


variable "kubernetes_cluster_name" {
  type    = string
  default = "master-dev-cluster"
}

variable "kubernetes_host" {
  type        = string
  description = "EKS Cluster Endpoint"
}

variable "kubernetes_ca_certificate" {
  type        = string
  description = "EKS Cluster CA Certificate"
}
