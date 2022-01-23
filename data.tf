data "aws_caller_identity" "current" { }
#  aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended
data "aws_ami" "aws_optimized_ecs" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["591542846629"] # AWS
}
data "aws_ami" "amazon-linux-2-bastion" {
 most_recent = true
 filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
 owners = ["137112412989"] # AWS
}
