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
