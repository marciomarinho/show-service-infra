output "apigw_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "alb_url" {
  value = "http://${aws_lb.app_alb.dns_name}"
}

output "dynamodb_table" {
  value = aws_dynamodb_table.shows.name
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.app_client.id
}

output "cognito_client_secret" {
  value     = aws_cognito_user_pool_client.app_client.client_secret
  sensitive = true
}

output "cognito_token_endpoint" {
  value = "https://cognito-idp.${var.region}.amazonaws.com"
}

output "codebuild_project_name" {
  value = aws_codebuild_project.app_build.name
}
