# Reference existing Cognito User Pool (for JWT tokens issued by this pool)
data "aws_cognito_user_pool" "existing" {
  user_pool_id = "ap-southeast-2_qBsVVpnmV"  # From JWT token issuer
}

# Reference existing Cognito User Pool Client
data "aws_cognito_user_pool_client" "existing_client" {
  user_pool_id = data.aws_cognito_user_pool.existing.id
  client_id    = "3dcrjo0k0d1b11jj8eru71rrgc"  # From JWT token client_id
}

# Custom API (resource server) for machine-to-machine scopes
resource "aws_cognito_resource_server" "shows_api" {
  user_pool_id = data.aws_cognito_user_pool.existing.id
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
  user_pool_id                          = data.aws_cognito_user_pool.existing.id
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
  domain       = "show-service-dev-f87c"  # Use the known existing domain
  user_pool_id = data.aws_cognito_user_pool.existing.id
}
