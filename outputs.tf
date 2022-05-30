output "user_identity" {
    description = "Info about IAM principal used by Terraform to configure AWS"
    value = data.aws_caller_identity.current
}

output "ecs_cluster_info" {
    description = "ECS Cluster Information"
    value = aws_ecs_cluster.web
}

output "load_balancer_dns" {
    value = module.alb.lb_dns_name
}

output "ecs_service_info" {
    value = aws_ecs_service.simple
}