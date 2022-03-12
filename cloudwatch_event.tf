resource "aws_cloudwatch_event_rule" "launchtemplate_updated_rule" {
  name        = "launchtemplate_updated"
  description = "Event when launch template  updated in Parameter store."

  event_pattern = <<EOF
{
    "source": [
        "aws.ssm"
    ],
    "detail-type": [
        "Parameter Store Change"
    ],
    "detail": {
        "name": [
            "ASG_launch_template_version"
        ],
        "operation": [
            "Update"
        ]
    }
}
EOF
}


resource "aws_cloudwatch_event_target" "refresh_asg" {
  rule      = aws_cloudwatch_event_rule.launchtemplate_updated_rule.name
  target_id = "SentToLambda"
  arn       = aws_lambda_function.refresh_asg.arn
}


resource "aws_cloudwatch_event_rule" "every_five_minute_check_ssm_setting" {
  name                = "every-five-minutes-check-ssm-setting"
  description         = "Fires every five minutes to check SSM launch template setting"
  schedule_expression = "rate(5 minutes)"

}


resource "aws_cloudwatch_event_target" "check_launchtempalte_five_minute" {
  rule      = "${aws_cloudwatch_event_rule.every_five_minute_check_ssm_setting.name}"
  target_id = "lambda"
  arn       = aws_lambda_function.compare_and_change_ssm.arn
}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_check_ssm" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.compare_and_change_ssm.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_five_minute_check_ssm_setting.arn}"
}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_refresh_asg" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.refresh_asg.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.launchtemplate_updated_rule.arn}"
}
