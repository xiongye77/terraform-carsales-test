output "The_application_URL_through_cloudfront" {
  value       =  "${var.demo_dns_name}.${data.aws_route53_zone.public.name}"
  description = "The application URL through cloudfront"
}	
