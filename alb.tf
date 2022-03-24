resource "aws_security_group" "carsales_alb_sg" {
  vpc_id = aws_vpc.carsales_vpc.id
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = {
    Name        = "CarSales ALB Security Group"
    Terraform   = "True"
  }
}

# Create Application Load Balancer

resource "aws_lb" "carsales_alb" {
  name               = "carsales-app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.carsales_alb_sg.id]
  subnets = [
    aws_subnet.carsales-public-1a.id,
    aws_subnet.carsales-public-1b.id,
  ]
  enable_deletion_protection = false
  tags = {
    Name        = "CarSales Application Load Balancer"
    Terraform   = "True"
  }
}


resource "aws_lb_listener" "carsales_http" {
  load_balancer_arn = aws_lb.carsales_alb.arn
  port = 443
  #port = 80
  #protocol = "HTTP"
  protocol = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.myapp_alb.arn
  #default_action {
  #type = "forward"
  #target_group_arn = aws_lb_target_group.carsales-back-end-tg-1.arn
  #}
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No http header matched  No Access"
      status_code  = "403"
    }
  }
}

#resource "aws_lb_listener" "carsales_https_redirect" {
#  load_balancer_arn = aws_lb.carsales_alb.arn
#  port              = "80"
#  protocol          = "HTTP"
#
#  default_action {
#    type = "redirect"
#    redirect {
#      port        = "443"
#      protocol    = "HTTPS"
#      status_code = "HTTP_301"
#    }
#  }
#}

resource "aws_lb_listener_rule" "carsales_test1_http" {
  depends_on = [aws_ssm_parameter.random-httpheader]
  listener_arn = aws_lb_listener.carsales_http.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.carsales-back-end-tg-1.arn
  }
    condition {
    path_pattern {
      values = ["/carsales1/"]
    }
    }
    condition {
      http_header {
        http_header_name = "X-Custom-Header"
        values = ["${aws_ssm_parameter.random-httpheader.value}"]
     }
   }
}


resource "aws_lb_listener_rule" "carsales_test2_http" {
  depends_on = [aws_ssm_parameter.random-httpheader]
  listener_arn = aws_lb_listener.carsales_http.arn
  priority     = 200
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.carsales-back-end-tg-2.arn
  }
    condition {
      path_pattern {
        values = ["/carsales2/"]
      }
   }
    condition {
      http_header {
        http_header_name = "X-Custom-Header"
        values = ["${aws_ssm_parameter.random-httpheader.value}"]
     }
   }

}

resource "aws_lb_listener_rule" "carsales_test3_http" {
  depends_on = [aws_ssm_parameter.random-httpheader]
  listener_arn = aws_lb_listener.carsales_http.arn
  priority     = 300
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.carsales-back-end-tg-3.arn
  }
  condition {
    path_pattern {
      values = ["/lambda/"]
    }
  }
  condition {
      http_header {
        http_header_name = "X-Custom-Header"
        values = ["${aws_ssm_parameter.random-httpheader.value}"]
     }
   }
}


resource "aws_lb_target_group" "carsales-back-end-tg-1" {
  port = 80
  protocol = "HTTP"
  name = "carsales-back-end-tg-1"
  vpc_id = aws_vpc.carsales_vpc.id
  stickiness {
    type = "lb_cookie"
    enabled = true
  }
  health_check {
    protocol = "HTTP"
    path = "/health"
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 10
  }
  tags = {
    Name        = "CarSales Back End Target Group 1"
    Terraform   = "True"
  }
}

resource "aws_lb_target_group" "carsales-back-end-tg-1-blue" {
  port = 80
  protocol = "HTTP"
  name = "carsales-back-end-tg-1-blue"
  vpc_id = aws_vpc.carsales_vpc.id
  stickiness {
    type = "lb_cookie"
    enabled = true
  }
  health_check {
    protocol = "HTTP"
    path = "/health"
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 10
  }
  tags = {
    Name        = "CarSales Back End Target Group 1 Blue"
    Terraform   = "True"
  }
}

resource "aws_lb_target_group" "carsales-back-end-tg-2" {
  name                 = "carsales-back-end-tg-2"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.carsales_vpc.id
  deregistration_delay = "30"
  target_type = "ip"
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
    interval            = 10
  }
  tags = {
    Name        = "CarSales Back End Target Group 2"
    Terraform   = "True"
  }

}



resource "aws_lb_target_group" "carsales-back-end-tg-3" {
  name                 = "carsales-back-end-tg-3"
  target_type = "lambda"
  tags = {
    Name        = "CarSales Back End Target Group 3"
    Terraform   = "True"
  }

}

resource "aws_lambda_permission" "with_lb" {
  statement_id  = "AllowExecutionFromlb"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.arn
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.carsales-back-end-tg-3.arn
}
resource "aws_lb_target_group_attachment" "lambda_attachment" {
  target_group_arn = aws_lb_target_group.carsales-back-end-tg-3.arn
  target_id = aws_lambda_function.test_lambda.arn
  depends_on = [ aws_lambda_permission. with_lb]
}




resource "aws_acm_certificate" "myapp_alb" {
  #provider          = "aws.acm_provider"
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

resource "aws_route53_record" "cert_validation_alb" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.myapp_alb.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.myapp_alb.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.myapp_alb.domain_validation_options)[0].resource_record_type
  zone_id  = data.aws_route53_zone.public.id
  ttl      = 60
  provider = aws.account_route53
}

