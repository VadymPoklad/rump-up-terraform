variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "table_name" {
  description = "Name of the DynamoDB table"
  default     = "UsersTable"
}

locals {
  http_methods = ["GET", "POST", "PUT", "DELETE"]
}

resource "aws_dynamodb_table" "users_table" {
  name         = var.table_name
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"
  
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect    = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = flatten([
      for action in ["GetItem", "PutItem", "UpdateItem", "DeleteItem"] : {
        Action   = "dynamodb:${action}"
        Effect   = "Allow"
        Resource = aws_dynamodb_table.users_table.arn
      },
      {
        Action   = "logs:*"
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ])
  })
}

resource "aws_lambda_function" "api_lambda" {
  filename         = "${path.module}/source/lambda_function.zip"
  function_name    = "user_management_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users_table.name
      REGION     = var.region
    }
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "user-management-api"
  description = "API for managing users"
}

resource "aws_api_gateway_resource" "user_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "user"
}

resource "aws_api_gateway_method" "user_methods" {
  for_each    = toset(local.http_methods)
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.user_resource.id
  http_method = each.value
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  for_each = toset(local.http_methods)
  
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.user_resource.id
  http_method             = each.value
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.api_lambda.arn}/invocations"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on = [
    aws_api_gateway_method.user_methods,
    aws_api_gateway_integration.lambda_integration,
    aws_lambda_permission.api_lambda_permission
  ]
}

resource "aws_lambda_permission" "api_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}
