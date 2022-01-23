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
    "secrets": [{"name": "db_url","valueFrom": "arn:aws:ssm:ap-south-1:${data.aws_caller_identity.current.account_id}:parameter/production/myapp/db-host"},
                     {"name": "DATABASE_PASSWORD", "valueFrom": "arn:aws:ssm:ap-south-1:${data.aws_caller_identity.current.account_id}:parameter/production/myapp/rds-password"
    }],
    "environment": [],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-create-group":"true",
        "awslogs-group": "carsales1",
        "awslogs-region": "ap-south-1",
        "awslogs-stream-prefix": "carsales1-log-stream"
      }
    }
  }
]
