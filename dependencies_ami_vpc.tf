## AMIs 
## Roughly the equivalent of the following aws cli query
## aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn*kernel-5*x86_64*gp2" --query 'Images[*].[Name, OwnerId, State]' --profile tfadmin1
## 
data "aws_ami" "amazon_linux2_kernel_5" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0*x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

## Data sources to identify the default vpc and its subnets
## https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
data "aws_vpc" "def_vpc" {
  default = true
}

# Subnet data source
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet
data "aws_subnets" "def_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.def_vpc.id]
  }
}

data "aws_ecs_cluster" "my_cluster" {
  cluster_name = aws_ecs_cluster.web.name
}

## To use for example in IAM policies
data "aws_caller_identity" "current" {

}
