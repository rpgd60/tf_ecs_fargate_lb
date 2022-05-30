data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.14.0"

  name = var.project
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  public_subnets  = slice(cidrsubnets(var.vpc_cidr, 8,8,8,8,8,8,8),1,4)  ## /24s  .1 / .2 / .3
  private_subnets = slice(cidrsubnets(var.vpc_cidr, 8,8,8,8,8,8,8),5,7)  ## /24s  .4 / .5 / .6

  enable_ipv6          = false
  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 7.0"

  name = "${var.project}-alb-${var.environment}"

  load_balancer_type = "application"

  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.sec_alb.id]


  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
    }
  ]

  # https_listeners = [
  #   {
  #     port               = 443
  #     protocol           = "HTTPS"
  #     certificate_arn    = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
  #     target_group_index = 0
  #   }
  # ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

}
# Security group for web server in public subnet 

resource "aws_security_group" "sec_web" {
  vpc_id = module.vpc.vpc_id
  name   = "${var.project}-sec-web-${var.environment}"

  # ingress {
  #   description = "Ping from specific addresses"
  #   from_port   = 8 # ICMP Code 8 - echo  (0 is echo reply)
  #   to_port     = 0
  #   protocol    = "icmp"
  #   cidr_blocks = var.sec_allowed_external
  # }

  ingress {
    description = "TCP Port 80 from specific addresses"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # cidr_blocks = var.sec_allowed_external
    security_groups = [aws_security_group.sec_alb.id]
  }

  ingress {
    description = "TCP Port 443 from specific addresses"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # cidr_blocks = var.sec_allowed_external
    security_groups = [aws_security_group.sec_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name =  "${var.project}-sec-web-${var.environment}"
  }
}

resource "aws_security_group" "sec_alb" {
  vpc_id = module.vpc.vpc_id
  name   = "${var.project}-sec-alb-${var.environment}"
  ingress {
    description = "Ping from specific addresses"
    from_port   = 8 # ICMP Code 8 - echo  (0 is echo reply)
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = var.sec_allowed_external
  }

  ingress {
    description = "TCP Port 80 from specific addresses"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.sec_allowed_external
  }

  ingress {
    description = "TCP Port 443 from specific addresses"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.sec_allowed_external
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name =  "${var.project}-sec-alb-${var.environment}"
  }
}

 
