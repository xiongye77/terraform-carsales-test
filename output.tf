output "The_static_content_on_S3_through_cloudfront" {
  value       =  "${var.demo_dns_name}.${data.aws_route53_zone.public.name}/index.html"
  description = "The static content on S3 through cloudfront"
}


output "The_ECS_docker1_through_cloudfront-alb" {
  value       =  "${var.demo_dns_name}.${data.aws_route53_zone.public.name}/carsales1/"
  description = "The_ECS_docker1_through_cloudfront-alb"
}


output "The_ECS_docker2_through_cloudfront-alb" {
  value       =  "${var.demo_dns_name}.${data.aws_route53_zone.public.name}/carsales2/"
  description = "The_ECS_docker2_through_cloudfront-alb"
}

output "The_lambda_through_cloudfront-alb" {
  value       =  "${var.demo_dns_name}.${data.aws_route53_zone.public.name}/lambda/"
  description = "The_lambda_through_cloudfront-alb"
}

output "Public_IP_of_Bastion" {
  value   = "${aws_instance.carsales_bastion_host-1a.public_ip}"
   description = "Public_IP_of_Bastion"

}
#data "kubernetes_ingress" "address" {
#  metadata {
#    name = "owncloud-lb"
#    namespace = "fargate-node"
#  }
#}

#output "server_dns" {
#    value = "${data.kubernetes_ingress.address.status.0.load_balancer.0.ingress.0.hostname}"
#}
