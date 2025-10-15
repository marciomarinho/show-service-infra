resource "aws_cognito_user_pool" "pool" {
  name = "${local.resource_prefix}-pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  tags = local.common_tags
}

resource "aws_cognito_user_pool_client" "app_client" {
  name                                  = "${local.resource_prefix}-client"
  user_pool_id                          = aws_cognito_user_pool.pool.id
  generate_secret                       = true
  allowed_oauth_flows                   = ["client_credentials"]
  allowed_oauth_scopes                  = ["openid"]
  allowed_oauth_flows_user_pool_client  = true
  supported_identity_providers          = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = var.cognito_domain_prefix != "" ? var.cognito_domain_prefix : "${local.resource_prefix}-${random_id.suffix.hex}"
  user_pool_id = aws_cognito_user_pool.pool.id
}
