variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}

variable "region" {
    type = string
    description = "This is the AWS region"
    default = "us-east-2" # région USA Est (Virginie du Nord) 
    # default = "us-east-1" # région USA Est (Virginie du Nord) 
    # default = "eu-west-3" # région Paris
}
# It can also be sourced from the AWS_DEFAULT_REGION environment variables
# or via a shared credentials file if profile is specified

variable "prefix_name" {
  type = string
  description = "To prefix name of different resources"
  default = "ack-"
  }

variable "bucket_name" {
  default = "stockage-des-sources-ec2"
}

variable "db_password" {}

data "aws_ami" "ubuntu-ami" {
    most_recent = true

    filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20200430"]
    }

    filter {
      name   = "virtualization-type"
      values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}
