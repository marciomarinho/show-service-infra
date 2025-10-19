resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.http_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${local.name}-jwt"

  jwt_configuration {
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.pool.id}"
    audience = [aws_cognito_user_pool_client.app_client.id]
  }

  depends_on = [
    aws_cognito_user_pool.pool,
    aws_cognito_user_pool_client.app_client,
    aws_cognito_user_pool_domain.domain
  ]
}

resource "aws_apigatewayv2_vpc_link" "alb_link" {
  name               = "${local.name}-vpc-link"
  security_group_ids = [aws_security_group.alb_sg.id]
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "alb_integ" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = aws_lb_listener.http.arn
  integration_method     = "ANY"
  payload_format_version = "1.0"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.alb_link.id
}

resource "aws_apigatewayv2_route" "post_shows" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "POST /v1/shows"
  target             = "integrations/${aws_apigatewayv2_integration.alb_integ.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  depends_on = [
    aws_apigatewayv2_vpc_link.alb_link
  ]
}

resource "aws_apigatewayv2_route" "get_shows" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /v1/shows"
  target             = "integrations/${aws_apigatewayv2_integration.alb_integ.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  depends_on = [
    aws_apigatewayv2_vpc_link.alb_link
  ]
}

resource "aws_apigatewayv2_route" "health_check" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /v1/health"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integ.id}"
  depends_on = [
    aws_apigatewayv2_vpc_link.alb_link
  ]
}

resource "aws_apigatewayv2_route" "catch_all" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integ.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

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
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}
