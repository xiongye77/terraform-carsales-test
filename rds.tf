# CREATE RDS SECURITY GROUP

resource "aws_security_group" "carsales_db_sg" {
  name = "CarSales RDS Security Group"
  vpc_id = aws_vpc.carsales_vpc.id
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_security_group.ecs.id
    ]
  }
  tags = {
    Name        = "RDS Security Group"
    Terraform   = "true"
  }
}

# Create CarSales Database Subnet Group

resource "aws_db_subnet_group" "carsales-db-subnet" {
  name = "carsales-database-subnet-group"
  subnet_ids = [
    aws_subnet.carsales-private-1a.id,
    aws_subnet.carsales-private-1b.id
    ]

  tags = {
    Name        = "DB Subnet Group"
    Terraform   = "true"
  }
}

# Create CarSales Database Instance

resource "aws_db_instance" "carsales-db" {
  allocated_storage       = "20"
  storage_type            = "gp2"
  #storage_type            = "io1"   io1 size at least 100G
  #iops = "3000"
  engine                  = "postgres"
  engine_version          = "12.9"
  multi_az                = "true"
  monitoring_interval = "30" # interval of Enhanced Monitoring metrics are collected for the DB instance
  instance_class          = "db.t3.large"
  name                    = "carsalesdb"
  # Set the secrets from AWS Secrets Manager
  username = var.rds_username
  password = "${random_string.password.result}"
  identifier              = "carsales-db"
  skip_final_snapshot     = "true"
  publicly_accessible    = "false"
  monitoring_interval = "30"   # interval for collecting Enhanced Monitoring metrics
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  backup_retention_period = "1"
  # DB Instance class db.t2.micro does not support encryption at rest
  storage_encrypted       = "true"
  db_subnet_group_name    = aws_db_subnet_group.carsales-db-subnet.name
  vpc_security_group_ids  = [aws_security_group.carsales_db_sg.id]
   tags = {
    Name        = "CarSales Database"
    Terraform   = "true"
  }
}



resource "aws_db_instance" "carsales-db-replica" {
  identifier             = "carsales-db-replica"
  replicate_source_db    = aws_db_instance.carsales-db.identifier ## refer to the master instance
  name                   = "carsalesdbreplica"
  instance_class         = "db.t3.large"
  allocated_storage      = "20"
  storage_type            = "gp2"
  #storage_type            = "io1" io1 size at least 100G
  #iops = "3000"
  engine                 = "postgres"
  engine_version         = "12.9"
  skip_final_snapshot    = "true"
  publicly_accessible    = "false"
  vpc_security_group_ids = [aws_security_group.carsales_db_sg.id]
# Username and password must not be set for replicas
  storage_encrypted       = "true"
# disable backups to create DB faster
  backup_retention_period = 0
}


resource "random_string" "password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "rdspassword" {
  name = "/production/myapp/rds-password"
  type        = "SecureString"
  value = "${random_string.password.result}"
}
data "aws_secretsmanager_secret_version" "creds" {
  # Fill in the name you gave to your secret
  depends_on = [aws_secretsmanager_secret_version.secretmanager-version]
  secret_id = aws_secretsmanager_secret.RDS-postgres-username.id
}

locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}

resource "aws_ssm_parameter" "postgres_username" {
  name  = "/production/myapp/rds-postgres-username"
  type  = "String"
  value = var.rds_username
}

resource "aws_ssm_parameter" "db_host" {
  name  = "/production/myapp/db-host"
  type  = "String"
  value = aws_db_instance.carsales-db.endpoint
}


resource "aws_ssm_parameter" "db_host_read_replica" {
  name  = "/production/myapp/db-host-read-replica"
  type  = "String"
  value = aws_db_instance.carsales-db-replica.endpoint
}
