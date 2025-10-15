resource "aws_dynamodb_table" "shows" {
  name         = "shows-${var.env}" # Environment-specific table names
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "slug"

  attribute {
    name = "slug"
    type = "S"
  }

  table_class = "STANDARD"

  tags = merge(local.common_tags, {
    Name = "shows-${var.env}"
  })
}
