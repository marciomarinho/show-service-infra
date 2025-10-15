terraform {
  backend "local" {}
}

resource "random_id" "suffix" {
  byte_length = 2
}

locals {
  name = "${var.project}-${var.env}"

  # Environment-specific naming for better organization
  resource_prefix = "${var.project}-${var.env}"

  # Tags for all resources
  common_tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}
