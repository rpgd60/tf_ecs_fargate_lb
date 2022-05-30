resource "aws_cloudwatch_log_group" "ecs_log" {
    name = "/rafa/ecs"
}

resource "aws_ecs_cluster" "web" {
  name = "simple"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
    #   kms_key_id = aws_kms_key.example.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = false
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_log.name
        
      }
    }
  }

}

resource "aws_ecs_task_definition" "task_web" {
  family                        = "service"
  network_mode                  = "awsvpc"
  requires_compatibilities      = ["FARGATE", "EC2"]
  cpu                           = 512
  memory                        = 2048
  ## TODO make generic or create role
  execution_role_arn = "arn:aws:iam::245790757869:role/ecsTaskExecutionRole"
  container_definitions         = jsonencode([
    {
      name      = "nginx-app"
      image     = "nginx:latest"
      cpu       = 512
      memory    = 2048
      essential = true  # if true and if fails, all other containers fail. Must have at least one essential
      portMappings = [
        {
          containerPort = tonumber(var.container_port)
          hostPort      = tonumber(var.container_port)
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "simple" {
  name              = "${var.project}-simple-${var.environment}"
  cluster           = aws_ecs_cluster.web.id
  task_definition   = aws_ecs_task_definition.task_web.id
  desired_count     = 3
  launch_type       = "FARGATE"
  platform_version  = "LATEST"

  network_configuration {
    assign_public_ip  = true
    security_groups   = [aws_security_group.sec_web.id]
    subnets           = module.vpc.public_subnets
  }

  load_balancer {
    target_group_arn = module.alb.target_group_arns[0]
    container_name =  "nginx-app"
    container_port = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

