#!/bin/bash
echo ECS_CLUSTER='${var.ecs_cluster_name}-cluster' > /etc/ecs/ecs.config 
sudo yum install amazon-cloudwatch-agent -y
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloudwatch-linux-mem

