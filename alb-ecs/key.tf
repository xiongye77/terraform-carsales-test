resource "tls_private_key" "carsales_ecs_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save Private key locally
resource "local_file" "carsales_ecs_private_key" {
  depends_on = [
    tls_private_key.carsales_ecs_key,
  ]
  content  = tls_private_key.carsales_ecs_key.private_key_pem
  filename = "carsales_ecs.pem"
}

# Upload public key to create keypair on AWS
resource "aws_key_pair" "carsales_ecs_public_key" {
  depends_on = [
    tls_private_key.carsales_ecs_key,
  ]
  key_name   = "carsales_ecs_public_key"
  public_key = tls_private_key.carsales_ecs_key.public_key_openssh
}
