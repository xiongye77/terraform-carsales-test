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

variable "cluster_name" {
   description = "EKS cluster name"
   default = "eks-cluster"
}

variable "s3_bucket_name" {
    description = "Bucket name used as cloudfront origin"
   default = "www.test1234567890"
}
variable "fargate_namespace" {
   description = "fargate_namespace"
   default ="fargate-namespace"
}

variable "environment" {
   description = "EKS environment"
   default = "test-eks-environment"
}

variable "instance_type_spot" {
    default = "t2.small"

}
variable "rds_username" {
   default = "postgresadmin"
}

variable "asg_name" {
  description = "AWS EC2 ASG Name"
  default = "carsales-ecs-asg"
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
  description = "Specific to your setup, pick a public domain you have in route53, this must be changed. check output of aws route53 list-hosted-zones"
  default = "poc.csnglobal.net"

}


variable "demo_dns_name" {
  description = " A demo domain name for the web access"
  default     = "ssldemo"
}



variable "ecr_repo_name" {
  description = "Name of ECR repo"
  type        = string
  default = "test_ecr_repo"
}

variable "source_path" {
  description = "Path to Docker image source"
  type        = string
  default = "$PWD"
  #default = "/home/ec2-user/carsales-test/terraform-carsales-test/alb-ecs"
}

variable "tag" {
  description = "Tag to use for deployed Docker image"
  type        = string
  default     = "latest"
}

variable "hash_script" {
  description = "Path to script to generate hash of source contents"
  type        = string
  default     = ""
}

variable "push_script" {
  description = "Path to script to build and push Docker image"
  type        = string
  default     = ""
}

