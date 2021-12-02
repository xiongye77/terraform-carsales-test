resource "aws_s3_bucket" "terraform-up-and-running-state-carsales-code" {
    bucket = "terraform-up-and-running-state-carsales-code"
    versioning {
      enabled = true
    }
    acl = "private"

    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm     = "AES256"
        }
      }
    }
    lifecycle {
      prevent_destroy = false
    }
}

resource "aws_s3_bucket_public_access_block" "private-bucket-public-access-block" {
  bucket = aws_s3_bucket.terraform-up-and-running-state-carsales-code.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}


resource "aws_dynamodb_table" "terraform-up-and-running-locks-carsales-code" {
  name = "terraform-up-and-running-locks-carsales-code"
  hash_key = "LockID"
  read_capacity = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }
}

