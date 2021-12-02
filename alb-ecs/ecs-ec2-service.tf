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

resource "aws_launch_configuration" "ecs" {
  name                        = "${var.ecs_cluster_name}-cluster"
  image_id                    =  data.aws_ami.aws_optimized_ecs.id 
  #image_id                    = data.aws_ami.ecs.id  aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended
  instance_type               = var.instance_type_spot
  spot_price                  = var.spot_bid_price
  security_groups             = [aws_security_group.ecs.id]
  iam_instance_profile        = aws_iam_instance_profile.ecs.name
  key_name                    = aws_key_pair.carsales_ecs_public_key.key_name
  associate_public_ip_address = true
  user_data                   = "#!/bin/bash\necho ECS_CLUSTER='${var.ecs_cluster_name}-cluster' > /etc/ecs/ecs.config"
}

resource "aws_autoscaling_group" "ecs-cluster" {
  name                 = "${var.ecs_cluster_name}_auto_scaling_group"
  termination_policies = [
     "OldestInstance" # When a “scale down” event occurs, which instances to kill first?
  ]
  default_cooldown          = 30
  health_check_grace_period = 30
  max_size                  = var.max_spot_instances
  min_size                  = var.min_spot_instances
  desired_capacity          = var.min_spot_instances
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.ecs.name
  vpc_zone_identifier  = [aws_subnet.carsales-private-1a.id, aws_subnet.carsales-private-1b.id]

   tag {
    key                 = "Name"
    value               = "asg-${var.ecs_cluster_name}"
    propagate_at_launch = "true"
  }
}


resource "aws_autoscaling_policy" "ecs-cluster-scale-out" {
    name = "ecs-cluster-scale-out"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ecs-cluster.name}"
}

resource "aws_autoscaling_policy" "ecs-cluster-scale-in" {
    name = "ecs-cluster-scale-in"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ecs-cluster.name}"
}


resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name = "mem-util-high-agents"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors ec2 memory for high utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.ecs-cluster-scale-out.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.ecs-cluster.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "mem-util-low-agents"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "20"
    alarm_description = "This metric monitors ec2 memory for low utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.ecs-cluster-scale-in.arn}"
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
    "image": "dbaxy770928/carsales1:latest",
    "essential": true,
    "cpu": 1,
    "memory": 256,
    "links": [],
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 0,
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
  container_definitions = <<DEFINITION
[
  {
    "name": "carsales2",
    "image": "dbaxy770928/carsales2:latest",
    "essential": true,
    "cpu": 1,
    "memory": 256,
    "links": [],
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 0,
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
  task_definition = aws_ecs_task_definition.carsales2.arn
  iam_role        = aws_iam_role.ecs-service-role.arn
  desired_count   = 1
  
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

