resource "aws_security_group" "ecs" {
  name        = "ecs_security_group"
  description = "Allows inbound access from the ALB only"
  vpc_id      = aws_vpc.carsales_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.carsales_alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.carsales_bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "ecs" {
  depends_on =[aws_ssm_parameter.cloudwatch-linux-mem]
  name                        = "${var.ecs_cluster_name}-lt"
  image_id                    =  data.aws_ami.aws_optimized_ecs.id
  #image_id                    = data.aws_ami.ecs.id  aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended
  instance_type               = var.instance_type_spot
  #spot_price                  = var.spot_bid_price
  #security_groups             = [aws_security_group.ecs.id]
  iam_instance_profile   {
    name = aws_iam_instance_profile.ecs.name
  }
  network_interfaces {
  security_groups = [aws_security_group.ecs.id]
  }
  key_name                    = aws_key_pair.carsales_ecs_public_key.key_name
  user_data                   = "${base64encode(<<EOF
   #!/bin/bash
   echo ECS_CLUSTER='${var.ecs_cluster_name}-cluster' > /etc/ecs/ecs.config
   sudo yum install amazon-cloudwatch-agent -y
   sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloudwatch-linux-mem
  EOF
  )}"
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "ecs-cluster" {
  name                 = "${var.asg_name}"
  termination_policies = [
     "OldestInstance" # When a “scale down” event occurs, which instances to kill first?
  ]
  default_cooldown          = 30
  health_check_grace_period = 30
  max_size                  = var.max_spot_instances
  min_size                  = var.min_spot_instances
  desired_capacity          = var.min_spot_instances
  health_check_type    = "EC2"
  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
    #version = aws_launch_template.ecs.latest_version
  }

  vpc_zone_identifier  = [aws_subnet.carsales-private-1a.id, aws_subnet.carsales-private-1b.id]
  lifecycle {
    create_before_destroy = true
  }
  instance_refresh {
    strategy = "Rolling"
    #enabled = true
    preferences {
      // You probably want more than 50% healthy depending on how much headroom you have
      min_healthy_percentage = 0
   }
   triggers = ["tag"]
  }
  tag {
    key                 = "launch_template_version"
    value               = "${aws_launch_template.ecs.latest_version}"
    propagate_at_launch = "true"
  }
}


resource "aws_autoscaling_policy" "ecs-cluster-cpu-scale-out" {
    name = "ecs-cluster-cpu-scale-out"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ecs-cluster.name}"
}

resource "aws_autoscaling_policy" "ecs-cluster-cpu-scale-in" {
    name = "ecs-cluster-cpu-scale-in"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ecs-cluster.name}"
}


resource "aws_autoscaling_policy" "ecs-cluster-mem-scale-out" {
    name = "ecs-cluster-mem-scale-out"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ecs-cluster.name}"
}

resource "aws_autoscaling_policy" "ecs-cluster-mem-scale-in" {
    name = "ecs-cluster-mem-scale-in"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ecs-cluster.name}"
}


resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name = "mem-util-high-agents"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "mem_used_percent"
    namespace = "CWAgent"
    period = "300"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors ec2 memory for high utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.ecs-cluster-mem-scale-out.arn}"
    ]
    dimensions = {
          AutoScalingGroupName = "${aws_autoscaling_group.ecs-cluster.name}"

    }
}

resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "mem-util-low-agents"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "mem_used_percent"
    namespace = "CWAgent"
    period = "300"
    statistic = "Average"
    threshold = "20"
    alarm_description = "This metric monitors ec2 memory for low utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.ecs-cluster-mem-scale-in.arn}"
    ]
    dimensions = {
            AutoScalingGroupName = "${aws_autoscaling_group.ecs-cluster.name}"
    }

}


resource "aws_cloudwatch_metric_alarm" "cpu-high" {
    alarm_name = "cpu-util-high-agents"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "30"
    statistic = "Average"
    threshold = "30"
    alarm_description = "This metric monitors ec2 cpu for high utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.ecs-cluster-cpu-scale-out.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.ecs-cluster.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "cpu-low" {
    alarm_name = "cpu-util-low-agents"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "30"
    statistic = "Average"
    threshold = "10"
    alarm_description = "This metric monitors ec2 cpu for low utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.ecs-cluster-cpu-scale-in.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.ecs-cluster.name}"
    }
}



#data "template_file" "carsales1" {
#  template = file("carsales1.json.tpl")
#}

resource "aws_ecs_task_definition" "carsales1" {
  family                = "carsales1"
  execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
  task_role_arn      = aws_iam_role.ecs-demo-task-role.arn
  container_definitions = <<DEFINITION
  [
  {
    "name": "carsales1",
    "image": "${aws_ecr_repository.repo.repository_url}:${var.tag}",
    "essential": true,
    "cpu": 256,
    "memory": 512,
    "links": [],
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 0,
        "protocol": "tcp"
      }
    ],
    "healthCheck":  {
      "retries":  2,
      "command":  [ "CMD-SHELL", "curl -f http://localhost:80/health || exit 1" ],
      "timeout": 5,
      "interval": 10
    },
    "mountPoints": [
          {
            "sourceVolume": "efs-carsales-demo",
            "containerPath": "/efs",
            "readOnly": false
          }
        ],
    "secrets": [{"name": "db_url","valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/production/myapp/db-host"},
          {"name": "DATABASE_PASSWORD", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/production/myapp/rds-password"},
          {"name": "DATABASE_PASSWORD_From_Secret_Manager", "valueFrom": "${aws_secretsmanager_secret.RDS-postgres-username.arn}"}
    ],
    "environment": [],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-create-group":"true",
        "awslogs-group": "carsales1",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "carsales1-log-stream"
      }
    }
  }
]
DEFINITION
  volume {
    name = "efs-carsales-demo"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs_volume.id
      root_directory = "/"
    }
  }
}

#data "template_file" "carsales2" {
#  template = file("carsales2.json.tpl")
#}

resource "aws_ecs_task_definition" "carsales2" {
  family                = "carsales2"
  execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
  task_role_arn      = aws_iam_role.ecs-task-execution-role.arn
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  container_definitions = <<DEFINITION
  [
  {
    "name": "carsales2",
    "image": "dbaxy770928/carsales2:latest",
    "essential": true,
    "links": [],
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ],
    "mountPoints": [
          {
            "sourceVolume": "efs-carsales-demo",
            "containerPath": "/efs",
            "readOnly": false
          }
        ],
    "secrets": [{"name": "db_url","valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/production/myapp/db-host"},
                {"name": "DATABASE_PASSWORD", "valueFrom": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/production/myapp/rds-password"
    }],
    "environment": [],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-create-group":"true",
        "awslogs-group": "carsales2",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "carsales-app-log-stream"
      }
    }
  }
  ]
  DEFINITION
  volume {
    name = "efs-carsales-demo"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs_volume.id
      root_directory = "/"
    }
  }
}

resource "aws_ecs_service" "carsales-dealer-service"{
  name            = "${var.ecs_cluster_name}-dealer-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.carsales1.arn
  deployment_controller {
      type = "CODE_DEPLOY"
  }
  desired_count   = 1
  load_balancer {
    target_group_arn = aws_lb_target_group.carsales-back-end-tg-1.id
    container_name  = "carsales1"
    container_port   = "80"
  }

}


resource "aws_ecs_service" "carsales-commerical-service"{
  name            = "${var.ecs_cluster_name}-commerical-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  launch_type = "FARGATE"
  task_definition = aws_ecs_task_definition.carsales2.arn
  #iam_role        = aws_iam_role.ecs-service-role.arn
  desired_count   = 1
  network_configuration {
   subnets = [aws_subnet.carsales-private-1a.id, aws_subnet.carsales-private-1b.id]
   security_groups = [aws_security_group.ecs.id]
   assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.carsales-back-end-tg-2.id
    container_name  = "carsales2"
    container_port   = "80"
  }
}

resource "aws_appautoscaling_target" "carsales-dealer_to_target" {
  max_capacity = 5
  min_capacity = 1
  resource_id = "service/${aws_ecs_cluster.my_cluster.name}/${aws_ecs_service.carsales-dealer-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "carsales-dealer_to_target_memory" {
  name               = "carsales-dealer-to-target-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.carsales-dealer_to_target.resource_id
  scalable_dimension = aws_appautoscaling_target.carsales-dealer_to_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.carsales-dealer_to_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
  }
}

resource "aws_appautoscaling_policy" "carsales-dealer_to_target_cpu" {
  name = "carsales-dealer-to-target-cpu"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.carsales-dealer_to_target.resource_id
  scalable_dimension = aws_appautoscaling_target.carsales-dealer_to_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.carsales-dealer_to_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}
