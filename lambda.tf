resource "aws_iam_policy" "lambda_logging" {
  name        = "asg_ir_lambda_logging"
  path        = "/"
  description = "IAM policy for logging from ASG lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_ssm" {
  name        = "asg_ir_lambda_ssm"
  path        = "/"
  description = "IAM policy for SSM Access from ASG lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters"
            ],
            "Resource": "*"
        },
     {
            "Effect": "Allow",
            "Action": [
                "ssm:*"
            ],
            "Resource": "*"
        }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_ec2_access" {
  name        = "asg_ir_lambda_ec2_access"
  path        = "/"
  description = "IAM policy for Ec2 Access from ASG lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Effect": "Allow",
            "Action": [
                "autoscaling:StartInstanceRefresh",
                "autoscaling:Describe*",
                "ec2:CreateLaunchTemplateVersion",
                "ec2:DescribeLaunchTemplates",
                "ec2:Describe*"
            ],
            "Resource": "*"
        }
  ]
}
EOF
}


resource "aws_iam_role" "asg_ir_lambda_role" {
  name = "asg_instance_refresh_lambda_role"

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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.asg_ir_lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_ssmps_read" {
  role       = aws_iam_role.asg_ir_lambda_role.name
  policy_arn = aws_iam_policy.lambda_ssm.arn
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_access" {
  role       = aws_iam_role.asg_ir_lambda_role.name
  policy_arn = aws_iam_policy.lambda_ec2_access.arn
}


data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "index.js"
    output_path   = "lambda_function.zip"
}




data "archive_file" "refresh_asg_zip" {
    type          = "zip"
    source_file   = "refresh_asg.py"
    output_path   = "refresh_asg.zip"
}


data "archive_file" "compare_and_change_ssm_zip" {
    type          = "zip"
    source_file   = "compare_and_change_ssm.py"
    output_path   = "compare_and_change_ssm.zip"
}


resource "aws_lambda_function" "compare_and_change_ssm" {
  filename         = "compare_and_change_ssm.zip"
  function_name    = "compare_and_change_ssm"
  role             = "${aws_iam_role.asg_ir_lambda_role.arn}"
  handler          = "compare_and_change_ssm.lambda_handler"
  source_code_hash = "${data.archive_file.compare_and_change_ssm_zip.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "30"
  memory_size      = "256"

}



resource "aws_lambda_function" "refresh_asg" {
  filename         = "refresh_asg.zip"
  function_name    = "refresh_asg"
  role             = "${aws_iam_role.asg_ir_lambda_role.arn}"
  handler          = "refresh_asg.lambda_handler"
  source_code_hash = "${data.archive_file.refresh_asg_zip.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "30"
  memory_size      = "256"
  environment {
    variables = {
      ASGName = var.asg_name
    }
  }
}

resource "aws_lambda_function" "test_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "test_lambda"
  role             = "${aws_iam_role.iam_for_lambda_tf.arn}"
  handler          = "index.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "nodejs14.x"
}


resource "aws_iam_role" "iam_for_lambda_tf" {
  name = "iam_for_lambda_tf"

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
