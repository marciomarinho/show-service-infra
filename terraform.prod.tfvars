# Production Environment Configuration
env = "prod"
region = "ap-southeast-2"

# Production-specific settings (higher availability, longer retention)
desired_count = 2
cpu = 512
memory = 1024
log_retention_days = 14

# Auto-generate domain prefix for prod
cognito_domain_prefix = ""
