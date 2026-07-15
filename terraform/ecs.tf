# ====================================
# ECS Cluster
# ====================================

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# ====================================
# CloudWatch Log Group
# ====================================

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-logs"
  }
}
# ====================================
# ECS Task Definition
# ====================================

resource "aws_ecs_task_definition" "springpetclinic" {
  family                   = "springpetclinic"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "512"
  memory = "1024"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "springpetclinic"
      image     = "${aws_ecr_repository.springpetclinic.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
# ====================================
# ECS Service
# ====================================

resource "aws_ecs_service" "springpetclinic" {

  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.springpetclinic.arn

  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {

    subnets = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id
    ]

    security_groups = [
      aws_security_group.ecs_sg.id
    ]

    assign_public_ip = true
  }

  load_balancer {

    target_group_arn = aws_lb_target_group.springpetclinic.arn

    container_name = "springpetclinic"

    container_port = 8080
  }

  depends_on = [
    aws_lb_listener.http
  ]
}