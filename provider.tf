provider "aws" {
  alias = "account_route53" # Specific to your setup
  version = ">= 3.4.0"
}

# your normal provider
#provider "aws" {
#  version = ">= 3.4.0"
#}
# version 4 has some changes https://stackoverflow.com/questions/71078462/terraform-aws-provider-error-value-for-unconfigurable-attribute-cant-configur
terraform {
  required_version = ">= 0.13.1"
  required_providers {
    aws  = "~> 3.73.0"
  }
}
