resource "aws_secretsmanager_secret" "RDS-postgres-username" {
   recovery_window_in_days = 0
   name = "carsales-rds-postgres-admin"
}

resource "aws_secretsmanager_secret_version" "secretmanager-version" {
  secret_id = aws_secretsmanager_secret.RDS-postgres-username.id
  secret_string = <<EOF
  {
    "password": "${random_string.password.result}"
  }
  EOF
}
