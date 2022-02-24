# Create VPC for DIG Application

resource "aws_vpc" "vpc_app" {
  provider             = aws.region-app
  cidr_block           = var.app-cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = join("_", [var.environment, "DIG Application vpc"])
    Env  = var.environment
    Type = "VPC"
  }
}

# Create IGW 

resource "aws_internet_gateway" "igw" {
  provider = aws.region-app
  vpc_id   = aws_vpc.vpc_app.id
  tags = {
    Name = join("_", [var.environment, "Internet Gateway"])
    Env  = var.environment
    Type = "IGW"
  }
}

# Get all available AZ's in app VPC

data "aws_availability_zones" "azs" {
  provider = aws.region-app
  state    = "available"
}


#  Create Elastic IP for NAT gateway

resource "aws_eip" "nat-ip" {
  provider   = aws.region-app
  count      = length(var.public_subnets)
  depends_on = [aws_internet_gateway.igw]
  vpc        = true
  tags = {
    Name = join("_", [var.environment, "Elastic IP for NAT Gateway", count.index + 1])
    Env  = var.environment
    Type = "EIP"
  }
}


# Create Public subnet #1

resource "aws_subnet" "publicsubnet" {
  count             = length(var.public_subnets)
  provider          = aws.region-app
  availability_zone = element(data.aws_availability_zones.azs.names, count.index)
  vpc_id            = aws_vpc.vpc_app.id
  cidr_block        = element(var.public_subnets, count.index)
  tags = {
    Name = join("-", [var.environment, "public", "subnet", count.index + 1])
    Env  = var.environment
    Type = "subnet"
  }
}

# Create Nat gateway in each Public Subnet

resource "aws_nat_gateway" "nat-gw" {
  provider      = aws.region-app
  count         = length(var.public_subnets)
  allocation_id = element(aws_eip.nat-ip.*.id, count.index)
  subnet_id     = element(aws_subnet.publicsubnet.*.id, count.index)
  depends_on    = [aws_eip.nat-ip, aws_subnet.publicsubnet]
  tags = {
    Name = join("-", [var.environment, "Nat Gateway", count.index + 1])
    Env  = var.environment
    Type = "Nat Gateway"
  }
}

# Create Private subnet #2


resource "aws_subnet" "privatesubnet" {
  count = length(var.private_subnets)

  provider          = aws.region-app
  availability_zone = element(data.aws_availability_zones.azs.names, count.index)
  vpc_id            = aws_vpc.vpc_app.id
  cidr_block        = element(var.private_subnets, count.index)
  tags = {
    Name = join("-", [var.environment, "private", "subnet", count.index + 1])
    Env  = var.environment
    Type = "subnet"
  }
}

# Create internet Public Subnet Route Table

resource "aws_route_table" "internet_route" {
  provider = aws.region-app
  vpc_id   = aws_vpc.vpc_app.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = join("-", [var.environment, "Public Subnet Route Table"])
    Env  = var.environment
    Type = "Route Table"
  }
  depends_on = [aws_internet_gateway.igw]
}

# Associate Public Route table to Public Subnets

resource "aws_route_table_association" "public-subnet-association" {
  provider       = aws.region-app
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.publicsubnet.*.id, count.index)
  route_table_id = aws_route_table.internet_route.id
  depends_on     = [aws_route_table.internet_route]
}

# Create Route table for Private Subnets

resource "aws_route_table" "private_route" {
  provider = aws.region-app
  count    = length(var.private_subnets)
  vpc_id   = aws_vpc.vpc_app.id
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = join("-", [var.environment, "Private Route Table", count.index + 1])
    Env  = var.environment
    Type = "Route Table"
  }
}


# Private Route table and Private Subnet association

resource "aws_route_table_association" "private-subnet-association" {
  provider       = aws.region-app
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.privatesubnet.*.id, count.index)
  route_table_id = element(aws_route_table.private_route.*.id, count.index)
}


# Overwrite default route table of VPC  with our route table entries

resource "aws_main_route_table_association" "set-master-default-assoc" {
  provider       = aws.region-app
  vpc_id         = aws_vpc.vpc_app.id
  route_table_id = element(aws_route_table.private_route.*.id, 0)
  depends_on = [
    aws_route_table.private_route, aws_route_table_association.private-subnet-association
  ]
}

# Add NAT gateway route to private Route Table

resource "aws_route" "subnets-private-rtable" {
  provider               = aws.region-app
  count                  = length(var.private_subnets)
  route_table_id         = element(aws_route_table.private_route.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat-gw.*.id, count.index)
}































