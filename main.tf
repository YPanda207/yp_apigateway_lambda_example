data "aws_vpc" "selected" {
  filter {
    name   = "cidr"
    values = ["10.*"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    Tier = "private"
  }
}

data "aws_security_group" "lambda_sg" {
  name = "${var.namespace}-lambda-sec-grp-${var.yp_environment}"
}

data "aws_iam_role" "lambda_role" {
  name = "${var.namespace}-lambda-exec-role"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name                  = "${var.namespace}-service-${var.yp_environment}"
  description                    = "This lambda saves the file in S3"
  role                           = data.aws_iam_role.lambda_role.arn
  handler                        = "handler.handle_request"
  runtime                        = "python3.13"
  timeout                        = 300
  memory_size                    = 1024
  reserved_concurrent_executions = "-1"
  filename                       = data.archive_file.lambda_zip.output_path
  # It is only for Terraform to detect changes in your zipped code.
  source_code_hash = data.archive_file.lambda_zip.output_base64sha512
  environment {
    variables = {
      ENVIRONMENT = var.yp_environment
      DEBUG       = true
    }
  }
  # 👇 This is what makes it a *VPC Lambda*
  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [data.aws_security_group.lambda_sg.id]
  }
}
