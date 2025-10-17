# Cognito User Pool for authentication
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

# Custom API (resource server) for machine-to-machine scopes
resource "aws_cognito_resource_server" "shows_api" {
  user_pool_id = aws_cognito_user_pool.pool.id
  identifier   = "https://show-service-dev.api"
  name         = "show-service-dev-api"

  scope {
    scope_name        = "shows.read"
    scope_description = "Read shows"
  }

  scope {
    scope_name        = "shows.write"
    scope_description = "Write shows"
  }
}

resource "aws_cognito_user_pool_client" "app_client" {
  name                                  = "${local.resource_prefix}-client"
  user_pool_id                          = aws_cognito_user_pool.pool.id
  generate_secret                       = true
  allowed_oauth_flows                   = ["client_credentials"]
  allowed_oauth_scopes                  = [
    "https://show-service-dev.api/shows.read",
    "https://show-service-dev.api/shows.write"
  ]
  allowed_oauth_flows_user_pool_client  = true
  supported_identity_providers          = ["COGNITO"]

  depends_on = [aws_cognito_resource_server.shows_api]
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = var.cognito_domain_prefix != "" ? var.cognito_domain_prefix : "${local.resource_prefix}-${random_id.suffix.hex}"
  user_pool_id = aws_cognito_user_pool.pool.id
}
