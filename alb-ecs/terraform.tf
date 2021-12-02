terraform {
  backend "s3" {
    bucket         = "terraform-up-and-running-state-carsales-code"
    key            = "global/s3/terraform.tfstate"
    #region         = "ap-southeast-2"
    dynamodb_table = "terraform-up-and-running-locks-carsales-code"
    encrypt        = true
  }
}
