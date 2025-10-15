# Multi-Environment Deployment Guide

This infrastructure supports deployment across multiple environments: `dev`, `test`, and `prod`.

## Environment-Specific Configurations

Each environment has different resource allocations:

| Environment | CPU | Memory | Desired Count | Log Retention |
|-------------|-----|--------|---------------|---------------|
| dev         | 256 | 512MB | 1             | 3 days        |
| test        | 512 | 1GB   | 1             | 7 days        |
| prod        | 512 | 1GB   | 2             | 14 days       |

## Deployment Commands

### Deploy to Development
```bash
terraform apply -var-file=terraform.dev.tfvars -auto-approve
```

### Deploy to Test
```bash
terraform apply -var-file=terraform.test.tfvars -auto-approve
```

### Deploy to Production
```bash
terraform apply -var-file=terraform.prod.tfvars -auto-approve
```

## Environment Variables Override

You can override environment-specific defaults using these variables:

- `desired_count_override` - Override desired task count
- `cpu_override` - Override CPU allocation
- `memory_override` - Override memory allocation
- `log_retention_days_override` - Override log retention

Example:
```bash
terraform apply \
  -var-file=terraform.prod.tfvars \
  -var "cpu_override=1024" \
  -var "memory_override=2048" \
  -auto-approve
```

## Resource Naming

All resources are prefixed with `{project}-{env}-` for clear environment identification:
- VPC: `show-service-dev-vpc`
- DynamoDB: `shows-dev`
- ECS Cluster: `show-service-dev-cluster`
- ALB: `show-service-dev-alb`

## Application Configuration

The ECS task receives these environment variables:
- `APP_ENV` - Current environment (dev/test/prod)
- `GIN_MODE` - Gin mode (debug for dev/test, release for prod)
- `APP__DYNAMODB__SHOWSTABLE` - Environment-specific table name

## Notes

- Each environment uses separate DynamoDB tables (`shows-dev`, `shows-test`, `shows-prod`)
- Cognito domains are auto-generated with environment prefixes
- Log groups are environment-specific: `/ecs/show-service-{env}`
- All resources are tagged with `Environment`, `Project`, and `ManagedBy` tags
