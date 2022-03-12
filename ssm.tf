resource "aws_ssm_parameter" "cloudwatch-linux-mem" {
  name  = "cloudwatch-linux-mem"
  type  = "String"
  value = file("ssm.json")
}

resource "aws_ssm_parameter" "ASG_launch_template_version" {
  name  = "ASG_launch_template_version"
  type  = "String"
  value = "${aws_launch_template.ecs.latest_version}"
  lifecycle {
    ignore_changes = all
  }
}
