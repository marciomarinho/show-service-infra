resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"
}

# JWT Authorizer using Cognito
resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.http_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${local.name}-jwt"
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.app_client.id]
    issuer   = "https://${aws_cognito_user_pool_domain.domain.domain}.auth.${var.region}.amazoncognito.com"
  }
}

# Integration to ALB for /shows
resource "aws_apigatewayv2_integration" "alb_integ" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${aws_lb.app_alb.dns_name}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "get_shows" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /shows"
  target             = "integrations/${aws_apigatewayv2_integration.alb_integ.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

resource "aws_apigatewayv2_route" "post_shows" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "POST /shows"
  target             = "integrations/${aws_apigatewayv2_integration.alb_integ.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

# Public passthrough to Cognito token endpoint
resource "aws_apigatewayv2_integration" "cognito_token_integ" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "POST"
  integration_uri        = "https://${aws_cognito_user_pool_domain.domain.domain}.auth.${var.region}.amazoncognito.com/oauth2/token"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "token_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /oauth/token"
  target    = "integrations/${aws_apigatewayv2_integration.cognito_token_integ.id}"
  # No authorizer – callers pass Basic Auth (client_id:client_secret) themselves
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}
