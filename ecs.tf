# ECR repository
resource "aws_ecr_repository" "repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  tags = { Name = "${local.name}-ecr" }
}

# Logs
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.resource_prefix}"
  retention_in_days = local.final_log_retention

  tags = local.common_tags
}

# ECS
resource "aws_ecs_cluster" "this" {
  name = "${local.name}-cluster"
}

# ALB + target group + listener
resource "aws_lb" "app_alb" {
  name               = "${local.name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "tg" {
  name        = "${local.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Service SG
resource "aws_security_group" "service_sg" {
  name        = "${local.resource_prefix}-service-sg"
  description = "ECS service SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# IAM roles
data "aws_iam_policy_document" "task_exec_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution_role" {
  name               = "${local.name}-exec"
  assume_role_policy = data.aws_iam_policy_document.task_exec_assume.json
}

resource "aws_iam_role_policy_attachment" "exec_logs" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name               = "${local.name}-task"
  assume_role_policy = data.aws_iam_policy_document.task_exec_assume.json
}

# IAM role for CodeBuild
data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "${local.resource_prefix}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeTasks",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = [aws_iam_role.task_execution_role.arn]
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role   = aws_iam_role.codebuild_role.name
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

# CodeBuild project for Go application
resource "aws_codebuild_project" "app_build" {
  name          = "${local.resource_prefix}-build"
  description   = "Build and deploy Go application to ECS"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode            = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.ecr_repo_name
    }

    environment_variable {
      name  = "ECS_CLUSTER_NAME"
      value = aws_ecs_cluster.this.name
    }

    environment_variable {
      name  = "ECS_SERVICE_NAME"
      value = aws_ecs_service.svc.name
    }

    environment_variable {
      name  = "ECS_TASK_DEFINITION"
      value = aws_ecs_task_definition.task.family
    }
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/marciomarinho/show-service.git"
    buildspec = "buildspec.yml"
  }

  tags = local.common_tags
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ddb_access" {
  statement {
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.shows.arn]
  }
}

resource "aws_iam_policy" "ddb_policy" {
  name   = "${local.name}-ddb"
  policy = data.aws_iam_policy_document.ddb_access.json
}

resource "aws_iam_role_policy_attachment" "task_ddb" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.ddb_policy.arn
}

# Task Definition
resource "aws_ecs_task_definition" "task" {
  family                   = "${local.resource_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.final_cpu
  memory                   = local.final_memory
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = true
      portMappings = [
        { containerPort = var.container_port, hostPort = var.container_port, protocol = "tcp" }
      ]
      environment = [
        { name = "APP_ENV", value = var.env },
        { name = "APP__DYNAMODB__REGION", value = var.region },
        { name = "APP__DYNAMODB__ENDPOINTOVERRIDE", value = "" },
        { name = "APP__DYNAMODB__SHOWSTABLE", value = aws_dynamodb_table.shows.name },
        { name = "APP__DYNAMODB__SHOWSGSI", value = "gsi_drm_episode" },
        { name = "GIN_MODE", value = var.env == "prod" ? "release" : "debug" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = local.common_tags
}

# ECS Service
resource "aws_ecs_service" "svc" {
  name            = "${local.resource_prefix}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = local.final_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.service_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]

  tags = local.common_tags
}
