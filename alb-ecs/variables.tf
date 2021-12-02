variable "region" {
     default = "ap-southeast-2"
}

variable "vpcCIDRblock" {
    default = "10.0.0.0/16"
}

variable "my_first_ecr_repo" {
    default = "my_first_ecr_repo"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  default = "carsales"
}

variable "instance_type_spot" {
    default = "t2.medium"

}

variable "max_spot_instances" {
    default = 2

}

variable "min_spot_instances" {
    default = 1

}
# Make sure your bid price is enough. 
variable "spot_bid_price"  {
    default = "0.03"

}
variable "demo_dns_zone" {
  description = "Specific to your setup, pick a domain you have in route53"
  default = "poc.csnglobal.net"
}


variable "demo_dns_name" {
  description = "Just a demo domain name"
  default     = "ssldemo"
}

