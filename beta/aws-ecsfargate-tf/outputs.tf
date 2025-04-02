output "scim_bridge_url" {
  description = "The URL for your SCIM bridge. Use this and your bearer token to connect your identity provider to 1Password."
  value       = aws_apigatewayv2_api.api_gateway.api_endpoint
}