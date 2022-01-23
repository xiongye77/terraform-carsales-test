resource "aws_ssm_parameter" "cloudwatch-linux-mem" {
  name  = "cloudwatch-linux-mem"
  type  = "String"
  value = file("ssm.json")
}

