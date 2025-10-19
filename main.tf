terraform {
  backend "local" {}
}

resource "random_id" "suffix" {
  byte_length = 2
}

locals {
  name = "${var.project}-${var.env}"

  resource_prefix = "${var.project}-${var.env}"

  common_tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}
