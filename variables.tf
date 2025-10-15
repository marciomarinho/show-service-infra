variable "project" {
  type        = string
  default     = "show-service"
  description = "Project name used for resource naming"
}

variable "env" {
  type        = string
  default     = "dev"
  description = "Environment name (dev, test, prod)"
  validation {
    condition     = contains(["dev", "test", "prod"], var.env)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "region" {
  type        = string
  default     = "ap-southeast-2"
  description = "AWS region for deployment"
}

variable "ecr_repo_name" {
  type        = string
  default     = "show-service"
  description = "ECR repository name"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Docker image tag to deploy"
}

variable "container_port" {
  type        = number
  default     = 8080
  description = "Container port for the application"
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Desired number of ECS tasks"
}

variable "cpu" {
  type        = number
  default     = 512
  description = "CPU units for ECS task (1024 = 1 vCPU)"
}

variable "memory" {
  type        = number
  default     = 1024
  description = "Memory for ECS task in MB"
}

# Environment-specific configurations
locals {
  environment_configs = {
    dev = {
      desired_count         = 1
      cpu                  = 256
      memory               = 512
      cognito_domain_prefix = "show-svc-dev-${random_id.suffix.hex}"
      log_retention_days   = 3
    }
    test = {
      desired_count         = 1
      cpu                  = 512
      memory               = 1024
      cognito_domain_prefix = "show-svc-test-${random_id.suffix.hex}"
      log_retention_days   = 7
    }
    prod = {
      desired_count         = 2
      cpu                  = 512
      memory               = 1024
      cognito_domain_prefix = "show-svc-prod-${random_id.suffix.hex}"
      log_retention_days   = 14
    }
  }

  current_env_config = local.environment_configs[var.env]
}

# Override variables with environment-specific defaults
variable "desired_count_override" {
  type        = number
  default     = null
  description = "Override desired count (uses env default if null)"
}

variable "cpu_override" {
  type        = number
  default     = null
  description = "Override CPU (uses env default if null)"
}

variable "memory_override" {
  type        = number
  default     = null
  description = "Override memory (uses env default if null)"
}

variable "log_retention_days_override" {
  type        = number
  default     = null
  description = "Override log retention days (uses env default if null)"
}

variable "cognito_domain_prefix" {
  type        = string
  default     = ""
  description = "Cognito domain prefix (auto-generated if empty)"
}
