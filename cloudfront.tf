provider "aws" {
  alias      = "wafv2_provider"
  region     = "us-east-1"
}

resource "aws_wafv2_web_acl" "my_web_acl" {
  provider  = "aws.wafv2_provider" 
  name  = "my-web-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimit"
    priority = 1

    action {
      block {}
    }

    statement {

      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = 500
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "my-web-acl"
    sampled_requests_enabled   = false
  }
}


resource "random_string" "random-httpheader" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "random-httpheader" {
  name = "/production/myapp/random-httpheader"
  type        = "SecureString"
  value = "${random_string.random-httpheader.result}"
}


#resource "aws_cloudfront_response_headers_policy" "headers_policy" {
#  name = "security-headers-policy"
#
#  custom_headers_config {
#    items {
#      header = "X-Custom-Header"
#      override = true
#      value = "random-value-1234567890"
#    }
#  }
#}
resource "aws_cloudfront_distribution" "distribution" {
   logging_config {
    bucket = aws_s3_bucket.cloudfront_logs_bucket.bucket_domain_name
    prefix = "main/"
   }
   origin {
    domain_name = aws_lb.carsales_alb.dns_name
    origin_id   = "alb"
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
    custom_header  { 
      name = "X-Custom-Header"
      value = "random-value-${aws_ssm_parameter.random-httpheader.value}"
    }
  }

  origin {
    domain_name = aws_s3_bucket.www_bucket.bucket_regional_domain_name
    origin_id = "S3-${var.s3_bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.www_bucket.cloudfront_access_identity_path
    }

  }


  enabled = true
  aliases   = ["${var.demo_dns_name}.${data.aws_route53_zone.public.name}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id     = "alb"
    #response_headers_policy_id = aws_cloudfront_response_headers_policy.headers_policy.id
    forwarded_values {
      query_string = true
      headers        = ["All"]

      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

  }

    ordered_cache_behavior {
    path_pattern     = "/index.html"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${var.s3_bucket_name}"
    #forwarded_values {
    #  query_string = false
    #  headers      = ["Origin"]
    #  cookies {
    #    forward = "none"
    #  }
    #}
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.this.id
    cache_policy_id          = data.aws_cloudfront_cache_policy.this.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    #cloudfront_default_certificate = false
    ssl_support_method = "sni-only"
    acm_certificate_arn = "${aws_acm_certificate.myapp.arn}" 
    minimum_protocol_version = "TLSv1.2_2018"
  }

  web_acl_id = "${aws_wafv2_web_acl.my_web_acl.arn}"
}


resource "aws_cloudfront_origin_access_identity" "www_bucket" {
  comment = "www_bucket"
}

resource "aws_s3_bucket" "www_bucket" {
  bucket = var.s3_bucket_name
  acl = "public-read"
  #policy = templatefile("templates/s3-policy.json", { bucket = "www.${var.bucket_name}" })
  force_destroy = true
  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["https://{var.s3_bucket_name}"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

}
resource "aws_s3_bucket_policy" "www_bucket_policy" {
  bucket = aws_s3_bucket.www_bucket.id
  policy = data.aws_iam_policy_document.read_www_bucket.json
}


data "aws_iam_policy_document" "read_www_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.www_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.www_bucket.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.www_bucket.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.www_bucket.iam_arn]
    }
  }
}



resource "aws_s3_bucket_public_access_block" "www_bucket" {
  bucket = aws_s3_bucket.www_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false
}


# This data source looks up the public DNS zone
data "aws_route53_zone" "public" {
  name         = var.demo_dns_zone
  private_zone = false
  provider     = aws.account_route53
}
provider "aws" {
  alias      = "acm_provider"
  region     = "us-east-1"
}


# This creates an SSL certificate
resource "aws_acm_certificate" "myapp" {
  provider          = "aws.acm_provider" 
  domain_name       = "${var.demo_dns_name}.${data.aws_route53_zone.public.name}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# This is a DNS record for the ACM certificate validation to prove we own the domain
#
# This example, we make an assumption that the certificate is for a single domain name so can just use the first value of the
# domain_validation_options.  It allows the terraform to apply without having to be targeted.
# This is somewhat less complex than the example at https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
# - that above example, won't apply without targeting

resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_type
  zone_id  = data.aws_route53_zone.public.id
  ttl      = 60
  provider = aws.account_route53
}

# This tells terraform to cause the route53 validation to happen
resource "aws_acm_certificate_validation" "cert" {
  provider = "aws.acm_provider"
  certificate_arn         = aws_acm_certificate.myapp.arn
  validation_record_fqdns = [ aws_route53_record.cert_validation.fqdn ]
}



# Standard route53 DNS record for "myapp" pointing to an ALB
resource "aws_route53_record" "myapp" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "${var.demo_dns_name}.${data.aws_route53_zone.public.name}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
  provider = aws.account_route53
}

data "aws_cloudfront_cache_policy" "this" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "this" {
  name = "Managed-CORS-S3Origin"
}

resource "null_resource" "s3_objects" {
  depends_on =[aws_s3_bucket.www_bucket]
  provisioner "local-exec" {
    command = "aws s3 cp index.html  s3://${var.s3_bucket_name}"
  }
}

