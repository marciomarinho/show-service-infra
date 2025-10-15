# Development Environment Configuration
env = "dev"
region = "ap-southeast-2"

# Dev-specific settings (smaller resources, shorter retention)
desired_count = 1
cpu = 256
memory = 512
log_retention_days = 3

# Auto-generate domain prefix for dev
cognito_domain_prefix = ""
