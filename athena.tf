resource "aws_s3_bucket" "cloudfront_logs_bucket" {
  bucket = "cloudfront-logs-wwww.test1234567890"
  force_destroy = true
  grant {
            id = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
            type = "CanonicalUser"
            permissions = ["FULL_CONTROL"]
  }
  lifecycle_rule {
    id      = "cloudfront_logs_lifecycle_rule"
    enabled = true
 
    expiration {
      days = 365
    }
  }
}


resource "aws_s3_bucket" "cloudfront_logs_athena_results_bucket" {
  bucket = "cloudfront-logs-athena-results-wwww.test1234567890"
  force_destroy = true
  lifecycle_rule {
    id      = "cloudfront_logs_athena_results_lifecycle_rule"
    enabled = true

    expiration {
      days = 365
    }
  }
}

resource "aws_athena_database" "cloudfront_logs_athena_database" {
  name   = "cloudfront_logs"
  bucket = aws_s3_bucket.cloudfront_logs_athena_results_bucket.bucket
}

resource "aws_athena_workgroup" "cloudfront_logs_athena_workgroup" {
  name        = "cloudfront_logs_workgroup"
  description = "Workgroup for Athena queries on CloudFront access logs"
  force_destroy = true
  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.cloudfront_logs_athena_results_bucket.bucket}/output/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}


resource "null_resource" "cloudfront_logs_athena_table" {
  triggers = {
    athena_database       = aws_athena_database.cloudfront_logs_athena_database.id
    athena_results_bucket = aws_s3_bucket.cloudfront_logs_athena_results_bucket.id
  }

  provisioner "local-exec" {
    command = <<-EOF
aws athena start-query-execution --query-string "CREATE EXTERNAL TABLE IF NOT EXISTS cloudfront_logs.cloudfront_logs (
  access_date DATE,
  time STRING,
  location STRING,
  bytes BIGINT,
  request_ip STRING,
  method STRING,
  host STRING,
  uri STRING,
  status INT,
  referrer STRING,
  user_agent STRING,
  query_string STRING,
  cookie STRING,
  result_type STRING,
  request_id STRING,
  host_header STRING,
  request_protocol STRING,
  request_bytes BIGINT,
  time_taken FLOAT,
  xforwarded_for STRING,
  ssl_protocol STRING,
  ssl_cipher STRING,
  response_result_type STRING,
  http_version STRING,
  fle_status STRING,
  fle_encrypted_fields INT,
  c_port INT,
  time_to_first_byte FLOAT,
  x_edge_detailed_result_type STRING,
  sc_content_type STRING,
  sc_content_len BIGINT,
  sc_range_start BIGINT,
  sc_range_end BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\\t'
LOCATION 's3://cloudfront-logs-wwww.test1234567890/main/'
TBLPROPERTIES ('skip.header.line.count' = '2');
"  --output json --query-execution-context Database=${self.triggers.athena_database} --result-configuration OutputLocation=s3://${self.triggers.athena_results_bucket}
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
aws athena start-query-execution --query-string 'DROP TABLE IF EXISTS cloudfront_logs.cloudfront_logs' --output json --query-execution-context Database=${self.triggers.athena_database} --result-configuration OutputLocation=s3://${self.triggers.athena_results_bucket}
    EOF
  }
}
