resource "aws_dynamodb_table" "shows" {
  name         = "shows-${var.env}" # Environment-specific table names
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "slug"

  attribute {
    name = "slug"
    type = "S"
  }

  attribute {
    name = "drmKey"
    type = "N"
  }

  attribute {
    name = "episodeCount"
    type = "N"
  }

  global_secondary_index {
    name            = "gsi_drm_episode"
    hash_key        = "drmKey"
    range_key       = "episodeCount"
    projection_type = "ALL"
  }

  table_class = "STANDARD"

  tags = merge(local.common_tags, {
    Name = "shows-${var.env}"
  })
}
