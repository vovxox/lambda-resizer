provider "aws" {
  region = var.region
}

# S3 Bucket and Object. This is where the application is located.
resource "aws_s3_bucket" "lambda" {
  bucket = "resizer-lambda-bucket"
  acl    = "private"

  force_destroy = true
  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["POST", "GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_object" "lambda" {
  bucket = aws_s3_bucket.lambda.id
  key    = "deploy.zip"
  source = "../deploy.zip"
}

# New function, uses s3 obj as source of function.
resource "aws_lambda_function" "main" {
  function_name = "Resizer"

  s3_bucket = aws_s3_bucket_object.lambda.bucket
  s3_key    = aws_s3_bucket_object.lambda.key

  handler = "main.handler"
  runtime = "python3.7"

  role = aws_iam_role.tf_role_for_lambda.arn

  memory_size = 128

  environment {
    variables = {
      BUCKET = aws_s3_bucket_object.lambda.bucket,
      REGION = var.region
    }
  }
}

# IAM role to be used across resources.

resource "aws_iam_role" "tf_role_for_lambda" {
  name = "tf_role_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3_access" {
  name        = "s3_access"
  path        = "/"
  description = "IAM policy for S3 events from a lambda handler"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::*",
      "Effect": "Allow"
    },
    {
      "Action": "logs:*",
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  role       = aws_iam_role.tf_role_for_lambda.name
  policy_arn = aws_iam_policy.s3_access.arn
}


# Create a REST API.
resource "aws_api_gateway_rest_api" "main" {
  name = "InferLambdaExample"

  binary_media_types = [
    "image/png",
    "image/jpeg",
  ]
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}


##Top Level Identifier
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}

resource "aws_api_gateway_deployment" "example" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = "dev"
}

# The "/*/*" portion grants access from any method on any resource
# within the API Gateway REST API.
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

