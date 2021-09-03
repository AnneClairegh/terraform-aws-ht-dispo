variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  type    = list
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  type    = list
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "azs" {
  type        = list
  description = "AZs to use in your public and private subnet  (make sure they are consistent with your AWS region)"
  default     = ["us-east-2a", "us-east-2b"]
  # AWS region "us-east-2" described in vars.tf of main module, ["us-east-2a", "us-east-2b"]
  # AWS region "us-east-1" described in vars.tf of main module, ["us-east-1a", "us-east-1b"]
  # AWS region "eu-west-3" described in vars.tf of main module, ["eu-west-3a", "eu-west-3b"]
}

variable "prefix_name" {
  type = string
  description = "To prefix name of different resources"
  # default = "ack_"
  }
