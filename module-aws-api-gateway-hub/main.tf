# module-aws-api-gateway-hub/main.tf

########################################
# ONE Private REST API
########################################
resource "aws_api_gateway_rest_api" "this" {
  name        = "saas-api-gateway"
  description = "Single Private API Gateway for all environments"

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [var.vpc_endpoint_id]
  }

  tags = var.tags
}

########################################
# Resource Policy
########################################
resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "${aws_api_gateway_rest_api.this.execution_arn}/*"
      },
      {
        Effect    = "Deny"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "${aws_api_gateway_rest_api.this.execution_arn}/*"
        Condition = {
          StringNotEquals = {
            "aws:sourceVpce" = var.vpc_endpoint_id
          }
        }
      }
    ]
  })
}

########################################
# Proxy Resource: /{proxy+}
########################################
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "{proxy+}"
}

########################################
# ANY /{proxy+} Method
########################################
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy"  = true
    "method.request.header.Host" = true
  }
}

########################################
# Integration (uses stage variables)
########################################
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://$${stageVariables.nlbDns}/{proxy}"
  connection_type         = "VPC_LINK"
  connection_id           = "$${stageVariables.vpcLinkId}"

  request_parameters = {
    "integration.request.path.proxy"  = "method.request.path.proxy"
    "integration.request.header.Host" = "method.request.header.Host"
  }
}

########################################
# ANY / (root) Method
########################################
resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_rest_api.this.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.header.Host" = true
  }
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_rest_api.this.root_resource_id
  http_method             = aws_api_gateway_method.root.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://$${stageVariables.nlbDns}/"
  connection_type         = "VPC_LINK"
  connection_id           = "$${stageVariables.vpcLinkId}"

  request_parameters = {
    "integration.request.header.Host" = "method.request.header.Host"
  }
}

########################################
# REMOVED: Custom Domain Names
# REMOVED: Domain Name Access Associations
# ALB now handles host header rewrite
########################################
