# Define VPC Variable

variable "aws-vpc-cidr" {
  type= string
  default="10.0.0.0/16"
}

variable "public_1_subnetCIDR" {
    default = "10.0.1.0/24"
}

variable "public_2_subnetCIDR" {
    default = "10.0.2.0/24"
}

variable "private_1_subnetCIDR" {
    default = "10.0.3.0/24"
}

variable "private_2_subnetCIDR" {
    default = "10.0.4.0/24"
}


# Create VPC

resource "aws_vpc" "carsales_vpc" {
  cidr_block = var.aws-vpc-cidr
  instance_tenancy = "default"
  enable_dns_hostnames=true
  tags = {
    Name = "CarSales VPC"
    Terrafrom = "True"
  }
}
# Create and Attach internet gateway

resource "aws_internet_gateway" "carsales-igw" {
  vpc_id = aws_vpc.carsales_vpc.id
  tags = {
    Name        = "CarSales Internet Gateway"
    Terraform   = "true"
  }
}
# CREATE ELASTIC IP ADDRESS FOR NAT GATEWAY

  resource "aws_eip" "carsales-nat1" {
}
  resource "aws_eip" "carsales-nat2" {
}
  

# CREATE NAT GATEWAY in Region-1A

resource "aws_nat_gateway" "carsales-nat-gateway-1a" {
  allocation_id = aws_eip.carsales-nat1.id
  subnet_id     = aws_subnet.carsales-public-1a.id

  tags = {
    Name        = "Nat Gateway-1a"
    Terraform   = "True"
  }
}

# CREATE NAT GATEWAY in Region-1B

resource "aws_nat_gateway" "carsales-nat-gateway-1b" {
  allocation_id = aws_eip.carsales-nat2.id
  subnet_id     = aws_subnet.carsales-public-1b.id

  tags = {
    Name        = "Nat Gateway-1b"
    Terraform   = "True"
  }
}
# Create Public Subnets

resource "aws_subnet" "carsales-public-1a" {
  vpc_id = aws_vpc.carsales_vpc.id
  cidr_block = var.public_1_subnetCIDR
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = "true"
  tags = {
    Name        = "CarSales Public Subnet - 1A"
    Terraform   = "True"
  }
}
resource "aws_subnet" "carsales-public-1b" {
  vpc_id = aws_vpc.carsales_vpc.id
  cidr_block = var.public_2_subnetCIDR
  availability_zone = "${var.region}b"
  map_public_ip_on_launch = "true"
  tags = {
    Name        = "CarSales Public Subnet - 1B"
    Terraform   = "True"
  }
}


# Create Private Subnets


resource "aws_subnet" "carsales-private-1a" {
  vpc_id = aws_vpc.carsales_vpc.id
  cidr_block = var.private_1_subnetCIDR
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = "false"
  tags = {
    Name        = "CarSales Private Subnet - 1A"
    Terraform   = "True"
  }
}

resource "aws_subnet" "carsales-private-1b" {
  vpc_id = aws_vpc.carsales_vpc.id
  cidr_block = var.private_2_subnetCIDR
  availability_zone = "${var.region}b"
  map_public_ip_on_launch = "false"
  tags = {
    Name        = "CarSales Private Subnet - 1B"
    Terraform   = "True"
  }
}
# Create first private route table and associate it with private subnet in Region-1a
 
resource "aws_route_table" "carsales_private_route_table_1a" {
    vpc_id = aws_vpc.carsales_vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.carsales-nat-gateway-1a.id
  }
    tags =  {
        Name      = "CarSales Private route table 1A"
        Terraform = "True"
  }
}
 
resource "aws_route_table_association" "carsales-1a" {
    subnet_id = aws_subnet.carsales-private-1a.id
    route_table_id = aws_route_table.carsales_private_route_table_1a.id
}
 
# Create second private route table and associate it with private subnet in Region-1b 
 
resource "aws_route_table" "carsales_private_route_table_1b" {
    vpc_id = aws_vpc.carsales_vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.carsales-nat-gateway-1b.id
  }
    tags =  {
        Name      = "CarSales Private route table 1B"
        Terraform = "True"
  }
}
 
resource "aws_route_table_association" "carsales-1b" {
    subnet_id = aws_subnet.carsales-private-1b.id
    route_table_id = aws_route_table.carsales_private_route_table_1b.id
}

# Create a public route table for Public Subnets

resource "aws_route_table" "carsales-public" {
  vpc_id = aws_vpc.carsales_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.carsales-igw.id
  }
  tags = {
    Name        = "CarSales Public Route Table"
    Terraform   = "true"
    }
}

# Attach a public route table to Public Subnets

resource "aws_route_table_association" "carsales-public-1a-association" {
  subnet_id = aws_subnet.carsales-public-1a.id
  route_table_id = aws_route_table.carsales-public.id
}

resource "aws_route_table_association" "carsales-public-1b-association" {
  subnet_id = aws_subnet.carsales-public-1b.id
  route_table_id = aws_route_table.carsales-public.id
}
