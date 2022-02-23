# Create SG for LB, only TCP/80,TCP/443 & outbound access

resource "aws_security_group" "lb-sg" {
  provider    = aws.region-app
  name        = join("-", [var.environment, "lb-sg"])
  description = "Allow 443 and traffic to APP SG"
  vpc_id      = aws_vpc.vpc_app.id
  ingress {
    description = "Allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 80 from anywhere for redirection"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = join("-", [var.environment, "lb-sg"])
    Env  = var.environment
    Type = "Security group"

  }
}

# Create SG for allowing TCP/8080 from LB and TCP/22 from your IP in us-east-1

resource "aws_security_group" "app-sg" {
  provider    = aws.region-app
  name        = join("-", [var.environment, "application-sg"])
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.vpc_app.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description     = "allow anyone on port 8080"
    from_port       = var.webserver-port
    to_port         = var.webserver-port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = join("-", [var.environment, "application-sg"])
    Env  = var.environment
    Type = "Security group"

  }
}

resource "aws_security_group" "database-sg" {
  provider    = aws.region-app
  name        = join("-", [var.environment, "database-sg"])
  description = "Allow communication to Database from Application instances"
  vpc_id      = aws_vpc.vpc_app.id
  ingress {
    description     = "Allow on all port from Application SG to Database"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.app-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = join("-", [var.environment, "database-sg"])
    Env  = var.environment
    Type = "Security group"
  }
}















































