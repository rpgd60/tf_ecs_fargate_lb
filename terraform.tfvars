profile = "tfadmin1"
region  = "eu-west-1"

project     = "acme-ecs"
environment = "dev"


instance_type = "t2.micro"

vpc_cidr = "10.1.0.0/16"

sec_allowed_external = ["0.0.0.0/0"]
key_name             = "tf-course"

## ECS
container_port = "80"