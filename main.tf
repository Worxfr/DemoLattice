# Provider Configuration
provider "aws" {
  region = var.region
}

# Backend configuration for S3
terraform {
  backend "s3" {
  }
}

# VPC Client 1
resource "aws_vpc" "client1" {
  cidr_block           = "10.1.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "VPC-Client1"
  }
}

# VPC S3 Gateway Endpoint - Client 1
resource "aws_vpc_endpoint" "s3_client1" {
  vpc_id            = aws_vpc.client1.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_vpc.client1.main_route_table_id
  ]
  tags = {
    Name = "s3-endpoint-client1"
  }
}

resource "aws_subnet" "client1_subnet" {
  vpc_id            = aws_vpc.client1.id
  cidr_block        = "10.1.0.0/25"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "Client1-Subnet"
  }
}

# VPC Client 2
resource "aws_vpc" "client2" {
  cidr_block           = "10.1.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "VPC-Client2"
  }
}

# VPC S3 Gateway Endpoint - Client 2
resource "aws_vpc_endpoint" "s3_client2" {
  vpc_id            = aws_vpc.client2.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.client2_rt.id
  ]

  tags = {
    Name = "s3-endpoint-client2"
  }
}

resource "aws_subnet" "client2_subnet" {
  vpc_id            = aws_vpc.client2.id
  cidr_block        = "10.1.0.0/25"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "Client2-Subnet"
  }
}

# VPC Client 2 Bis (Site 2)
resource "aws_vpc" "client2_bis" {
  cidr_block           = "10.101.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "VPC-Client2-Bis"
  }
}


# VPC S3 Gateway Endpoint - Client2 Bis
resource "aws_vpc_endpoint" "s3_client2_bis" {
  vpc_id            = aws_vpc.client2_bis.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.client2_bis_rt.id
  ]

  tags = {
    Name = "s3-endpoint-client2-bis"
  }
}

resource "aws_subnet" "client2_bis_subnet" {
  vpc_id            = aws_vpc.client2_bis.id
  cidr_block        = "10.101.0.0/25"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "Client2-Bis-Subnet"
  }
}

# Provider VPC
resource "aws_vpc" "provider" {
  cidr_block           = "10.1.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "VPC-Provider"
  }
}

resource "aws_subnet" "provider_subnet" {
  vpc_id            = aws_vpc.provider.id
  cidr_block        = "10.1.0.0/25"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "Provider-Subnet"
  }
}


resource "aws_route_table" "provider_rt_priv"{
  vpc_id = aws_vpc.provider.id

  route {
    cidr_block                = aws_vpc.provider_bis.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.provider_to_bis.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.provider_nat.id
  }

  tags = {
    Name = "Provider-Route-Table-Private"
  }

}

# Route table associations
resource "aws_route_table_association" "provider_subnet_association" {
  subnet_id      = aws_subnet.provider_subnet.id
  route_table_id = aws_route_table.provider_rt_priv.id
}

# Provider Bis VPC
resource "aws_vpc" "provider_bis" {
  cidr_block           = "10.200.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "VPC-Provider-Bis"
  }
}



resource "aws_subnet" "provider_bis_subnet" {
  vpc_id            = aws_vpc.provider_bis.id
  cidr_block        = "10.200.0.0/25"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "Provider-Bis-Subnet"
  }
}

resource "aws_route_table" "provider_bis_rt_priv"{
  vpc_id = aws_vpc.provider_bis.id

  route {
    cidr_block                = aws_vpc.provider.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.provider_to_bis.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.provider_bis_nat.id
  }

  tags = {
    Name = "Provider_bis-Route-Table-Private"
  }

}

# Route table associations
resource "aws_route_table_association" "provider_bis_subnet_association" {
  subnet_id      = aws_subnet.provider_bis_subnet.id
  route_table_id = aws_route_table.provider_bis_rt_priv.id
}

# VPC Peering between Provider and Provider Bis
resource "aws_vpc_peering_connection" "provider_to_bis" {
  peer_vpc_id = aws_vpc.provider.id
  vpc_id      = aws_vpc.provider_bis.id
  auto_accept = true
  

  tags = {
    Name = "Provider-to-Bis-Peering"
  }
}

resource "aws_vpc_peering_connection_options" "bis_to_provider_option_vpcpeering" {
  # Options can't be set until the connection has been accepted
  # You can try a provisioner here if you want to do some task once the connection is accepted

  vpc_peering_connection_id = aws_vpc_peering_connection.client2_to_bis.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}



# Route tables for VPC peering
resource "aws_route_table" "provider_rt" {
  vpc_id = aws_vpc.provider.id

  route {
    cidr_block                = aws_vpc.provider_bis.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.provider_to_bis.id
  }

  tags = {
    Name = "Provider-Route-Table"
  }
}

resource "aws_route_table" "provider_bis_rt" {
  vpc_id = aws_vpc.provider_bis.id

  route {
    cidr_block                = aws_vpc.provider.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.provider_to_bis.id
  }

  tags = {
    Name = "Provider-Bis-Route-Table"
  }
}


# VPC Peering between Client 2 and Client 2 Bis
resource "aws_vpc_peering_connection" "client2_to_bis" {
  peer_vpc_id = aws_vpc.client2.id
  vpc_id      = aws_vpc.client2_bis.id
  auto_accept = true
  

  tags = {
    Name = "Client2-to-Bis-Peering"
  }
}

resource "aws_vpc_peering_connection_options" "client2_to_bis_option_vpcpeering" {
  # Options can't be set until the connection has been accepted
  # You can try a provisioner here if you want to do some task once the connection is accepted

  vpc_peering_connection_id = aws_vpc_peering_connection.provider_to_bis.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}


# Route tables for VPC peering
resource "aws_route_table" "client2_rt" {
  vpc_id = aws_vpc.client2.id

  route {
    cidr_block                = aws_vpc.client2_bis.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.client2_to_bis.id
  }


  tags = {
    Name = "Client2-Route-Table"
  }
}

resource "aws_route_table" "client2_bis_rt" {
  vpc_id = aws_vpc.client2_bis.id

  route {
    cidr_block                = aws_vpc.client2.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.client2_to_bis.id
  }

  tags = {
    Name = "Client2-Bis-Route-Table"
  }
}


# Route table associations for Client2
resource "aws_route_table_association" "client2_subnet_association" {
  subnet_id      = aws_subnet.client2_subnet.id
  route_table_id = aws_route_table.client2_rt.id
}

# Route table associations for Client2 Bis
resource "aws_route_table_association" "client2_bis_subnet_association" {
  subnet_id      = aws_subnet.client2_bis_subnet.id
  route_table_id = aws_route_table.client2_bis_rt.id
}


data "aws_subnets" "client1sublist" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.client1.id]
  }
}

data "aws_subnets" "client2sublist" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.client2.id]
  }
}

data "aws_subnets" "client2bissublist" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.client2_bis.id]
  }
}

data "aws_subnets" "providersublist" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.provider.id]
  }
}

data "aws_subnets" "providerbissublist" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.provider_bis.id]
  }
}

# VPC Endpoints for Systems Manager (SSM) - Client1 VPC
resource "aws_vpc_endpoint" "client1_ssm" {
  vpc_id             = aws_vpc.client1.id
  service_name       = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client1_vpce.id]
  subnet_ids         = [aws_subnet.client1_subnet.id] 
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "client1_ssmmessages" {
  vpc_id             = aws_vpc.client1.id
  service_name       = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client1_vpce.id]
  subnet_ids         = [aws_subnet.client1_subnet.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "client1_ec2messages" {
  vpc_id             = aws_vpc.client1.id
  service_name       = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client1_vpce.id]
  subnet_ids         = [aws_subnet.client1_subnet.id]
  private_dns_enabled = true
}


resource "aws_vpc_endpoint" "client1_ec2" {
  vpc_id             = aws_vpc.client1.id
  service_name       = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client1_vpce.id]
  subnet_ids         = [aws_subnet.client1_subnet.id]
  private_dns_enabled = true
}

# VPC Endpoints for Systems Manager (SSM) - Client2 VPC
resource "aws_vpc_endpoint" "client2_ssm" {
  vpc_id             = aws_vpc.client2.id
  service_name       = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client2_vpce.id]
  subnet_ids         = [aws_subnet.client2_subnet.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "client2_ssmmessages" {
  vpc_id             = aws_vpc.client2.id
  service_name       = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client2_vpce.id]
  subnet_ids         = [aws_subnet.client2_subnet.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "client2_ec2messages" {
  vpc_id             = aws_vpc.client2.id
  service_name       = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client2_vpce.id]
  subnet_ids         = [aws_subnet.client2_subnet.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "client2_ec2" {
  vpc_id             = aws_vpc.client2.id
  service_name       = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client2_vpce.id]
  subnet_ids         = [aws_subnet.client2_subnet.id]
  private_dns_enabled = true
}

# VPC Endpoints for Systems Manager (SSM) - Client2_bis VPC
resource "aws_vpc_endpoint" "client2_bis_ssm" {
  vpc_id             = aws_vpc.client2_bis.id
  service_name       = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client2_bis_vpce.id]
  subnet_ids         = [aws_subnet.client2_bis_subnet.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "client2_bis_ssmmessages" {
  vpc_id             = aws_vpc.client2_bis.id
  service_name       = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client2_bis_vpce.id]
  subnet_ids         = [aws_subnet.client2_bis_subnet.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "client2_bis_ec2messages" {
  vpc_id             = aws_vpc.client2_bis.id
  service_name       = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client2_bis_vpce.id]
  subnet_ids         = [aws_subnet.client2_bis_subnet.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "client2_bis_ec2" {
  vpc_id             = aws_vpc.client2_bis.id
  service_name       = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.client2_bis_vpce.id]
  subnet_ids         = [aws_subnet.client2_bis_subnet.id]
  private_dns_enabled = true
}




# Security Groups for VPC Endpoints
resource "aws_security_group" "client1_vpce" {
  name        = "client1-vpce-sg"
  description = "Security group for Client1 VPC Endpoints"
  vpc_id      = aws_vpc.client1.id


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.client1.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "client2_vpce" {
  name        = "client2-vpce-sg"
  description = "Security group for Client2 VPC Endpoints"
  vpc_id      = aws_vpc.client2.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.client2.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "client2_bis_vpce" {
  name        = "client2-bis-vpce-sg"
  description = "Security group for Client2_bis VPC Endpoints"
  vpc_id      = aws_vpc.client2_bis.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.client2_bis.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# Data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# Create an IAM role for EC2 instances to use with Session Manager
resource "aws_iam_role" "ssm_role" {
  name = "${var.name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name}-ssm-role"
  }
}

# Attach the AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_role.name
}

# Create an instance profile
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "${var.name}-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}


# EC2 Instance in Client1 VPC
resource "aws_instance" "client1_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3a.micro"
  subnet_id     = aws_subnet.client1_subnet.id
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  tags = {
    Name = "Client1-Instance"
  }

}

# EC2 Instance in Client2 VPC
resource "aws_instance" "client2_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3a.micro"
  subnet_id     = aws_subnet.client2_subnet.id
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  tags = {
    Name = "Client2-Instance"
  }

}

# EC2 Instance in Client2 Bis VPC
resource "aws_instance" "client2_bis_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3a.micro"
  subnet_id     = aws_subnet.client2_bis_subnet.id
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  tags = {
    Name = "Client2-Bis-Instance"
  }
}

resource "aws_security_group" "allow_http_icmp" {
  name        = "allow_http_icmp"
  description = "Allow HTTP and ICMP inbound traffic"
  vpc_id      = aws_vpc.provider.id

  ingress {
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_icmp"
  }
}

# EC2 Instance in Provider VPC
resource "aws_instance" "provider_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3a.micro"
  subnet_id     = aws_subnet.provider_subnet.id
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  security_groups = [aws_security_group.allow_http_icmp.id]
  user_data     = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd php
              systemctl start httpd
              systemctl enable httpd
              cat << 'PHPSCRIPT' > /var/www/html/index.php
              <?php
                # Print my IP:
                echo "\n";
                echo "███████╗███████╗██████╗ ██╗   ██╗██╗ ██████╗███████╗     ██╗\n";
                echo "██╔════╝██╔════╝██╔══██╗██║   ██║██║██╔════╝██╔════╝    ███║\n";
                echo "███████╗█████╗  ██████╔╝██║   ██║██║██║     █████╗      ╚██║\n";
                echo "╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║██║     ██╔══╝       ██║\n";
                echo "███████║███████╗██║  ██║ ╚████╔╝ ██║╚██████╗███████╗     ██║\n";
                echo "╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝ ╚═════╝╚══════╝     ╚═╝\n";
                echo "\n";
                echo "LOCAL SERVER IP: ";
                echo $_SERVER['SERVER_ADDR'];

                # Print out the client IP
                echo "\n";
                echo "REMOTE CLIENT IP: ";
                echo $_SERVER['REMOTE_ADDR'];

                # Print out the x-forwarded IP (if behind a proxy/load balancer)
                echo "\n";
                echo "X-FORWARDED-FOR: ";
                echo isset($_SERVER['HTTP_X_FORWARDED_FOR']) ? $_SERVER['HTTP_X_FORWARDED_FOR'] : 'N/A';

                # Print HTTP Host Header
                echo "\n";
                echo "HOST-HEADER: ";
                echo $_SERVER['HTTP_HOST'];

                # Print the TCP port the client is connecting to
                echo "\n";
                echo "SERVER PORT: ";
                echo $_SERVER['SERVER_PORT'];

                # Print AWS Lattice Headers
                echo "\n";
                echo "X-AMZN-LATTICE-IDENTITY: ";
                echo isset($_SERVER['HTTP_X_AMZN_LATTICE_IDENTITY']) ? $_SERVER['HTTP_X_AMZN_LATTICE_IDENTITY'] : 'N/A';

                echo "\n";
                echo "X-AMZN-LATTICE-NETWORK: ";
                echo isset($_SERVER['HTTP_X_AMZN_LATTICE_NETWORK']) ? $_SERVER['HTTP_X_AMZN_LATTICE_NETWORK'] : 'N/A';

                echo "\n";
                echo "X-AMZN-LATTICE-TARGET: ";
                echo isset($_SERVER['HTTP_X_AMZN_LATTICE_TARGET']) ? $_SERVER['HTTP_X_AMZN_LATTICE_TARGET'] : 'N/A';

                echo "\n";
                echo "\n";
              ?>
              PHPSCRIPT
              EOF
  tags = {
    Name = "Provider-Instance"
  }

  depends_on = [ aws_nat_gateway.provider_nat ]
}

# Create target group for provider instance
resource "aws_vpclattice_target_group" "provider_tg" {
  name = "provider-target-group"
  type = "INSTANCE"
  config {
    port = 80
    protocol = "HTTP"
    vpc_identifier = aws_vpc.provider.id
    health_check {
      enabled = true
      protocol = "HTTP"
      path = "/index.php"
      port = 80
    }
  }
  tags = {
    Name = "Provider-Target-Group"
  }
}

# Attach provider instance to target group
resource "aws_vpclattice_target_group_attachment" "provider_tg_attachment" {
  target_group_identifier = aws_vpclattice_target_group.provider_tg.id
  target {
    id   = aws_instance.provider_instance.id
    port = 80
  }
}


# Create VPC Lattice Service
resource "aws_vpclattice_service" "service1" {
  name               = "service1"
  auth_type         = "NONE"

  tags = {
    Name = "Example Service"
  }
}

# Associate service with service network
resource "aws_vpclattice_service_network_service_association" "service1asso" {
  service_identifier         = aws_vpclattice_service.service1.id
  service_network_identifier = aws_vpclattice_service_network.service_network.id

  tags = {
    Name = "Service-Network-Association"
  }
}

# Create listener for the service
resource "aws_vpclattice_listener" "service1" {
  name               = "example-listener"
  protocol          = "HTTP"
  port              = 80
  service_identifier = aws_vpclattice_service.service1.id

  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.provider_tg.id
        weight                 = 100
      }
    }
  }
}

resource "aws_security_group" "allow_http_icmp_bis" {
  name        = "allow_http_icmp"
  description = "Allow HTTP and ICMP inbound traffic"
  vpc_id      = aws_vpc.provider_bis.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_icmp"
  }
}


# EC2 Instance in Provider Bis VPC
resource "aws_instance" "provider_bis_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3a.micro"
  subnet_id     = aws_subnet.provider_bis_subnet.id
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  security_groups = [aws_security_group.allow_http_icmp_bis.id]
    user_data     = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd php
              systemctl start httpd
              systemctl enable httpd
              cat << 'PHPSCRIPT' > /var/www/html/index.php
              <?php
                # Print my IP:
                echo "\n";
                echo "██████╗ ███████╗███████╗ ██████╗ ██╗   ██╗██████╗  ██████╗███████╗     ██╗\n";
                echo "██╔══██╗██╔════╝██╔════╝██╔═══██╗██║   ██║██╔══██╗██╔════╝██╔════╝    ███║\n";
                echo "██████╔╝█████╗  ███████╗██║   ██║██║   ██║██████╔╝██║     █████╗      ╚██║\n";
                echo "██╔══██╗██╔══╝  ╚════██║██║   ██║██║   ██║██╔══██╗██║     ██╔══╝       ██║\n";
                echo "██║  ██║███████╗███████║╚██████╔╝╚██████╔╝██║  ██║╚██████╗███████╗     ██║\n";
                echo "╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚══════╝     ╚═╝\n";
                echo "\n";
                echo "LOCAL SERVER IP: ";
                echo $_SERVER['SERVER_ADDR'];

                # Print out the client IP
                echo "\n";
                echo "REMOTE CLIENT IP: ";
                echo $_SERVER['REMOTE_ADDR'];

                # Print out the x-forwarded IP (if behind a proxy/load balancer)
                echo "\n";
                echo "X-FORWARDED-FOR: ";
                echo isset($_SERVER['HTTP_X_FORWARDED_FOR']) ? $_SERVER['HTTP_X_FORWARDED_FOR'] : 'N/A';

                # Print HTTP Host Header
                echo "\n";
                echo "HOST-HEADER: ";
                echo $_SERVER['HTTP_HOST'];

                # Print the TCP port the client is connecting to
                echo "\n";
                echo "SERVER PORT: ";
                echo $_SERVER['SERVER_PORT'];

                # Print AWS Lattice Headers
                echo "\n";
                echo "X-AMZN-LATTICE-IDENTITY: ";
                echo isset($_SERVER['HTTP_X_AMZN_LATTICE_IDENTITY']) ? $_SERVER['HTTP_X_AMZN_LATTICE_IDENTITY'] : 'N/A';

                echo "\n";
                echo "X-AMZN-LATTICE-NETWORK: ";
                echo isset($_SERVER['HTTP_X_AMZN_LATTICE_NETWORK']) ? $_SERVER['HTTP_X_AMZN_LATTICE_NETWORK'] : 'N/A';

                echo "\n";
                echo "X-AMZN-LATTICE-TARGET: ";
                echo isset($_SERVER['HTTP_X_AMZN_LATTICE_TARGET']) ? $_SERVER['HTTP_X_AMZN_LATTICE_TARGET'] : 'N/A';

                echo "\n";
                echo "\n";
              ?>
              PHPSCRIPT
              EOF
  tags = {
    Name = "Provider-Bis-Instance"
  }

  depends_on = [ aws_nat_gateway.provider_bis_nat ]
}


# Create VPC Lattice Service Network
resource "aws_vpclattice_service_network" "service_network" {
  name = "example-service-network"
  
  tags = {
    Name = "Example Service Network"
  }
}

# Associate VPCs with the Service Network
resource "aws_vpclattice_service_network_vpc_association" "client1_association" {
  vpc_identifier             = aws_vpc.client1.id
  service_network_identifier = aws_vpclattice_service_network.service_network.id
  
  tags = {
    Name = "Client1-ServiceNetwork-Association"
  }
}




resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound/outbound traffic"
  vpc_id      = aws_vpc.client2.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all"
  }
}

resource "aws_vpc_endpoint" "SNI-VPC2-Tg" {
  vpc_id             = aws_vpc.client2.id
  service_network_arn = aws_vpclattice_service_network.service_network.arn
  vpc_endpoint_type  = "ServiceNetwork"
  security_group_ids = [aws_security_group.allow_all.id]
  subnet_ids         = [aws_subnet.client2_subnet.id]
  private_dns_enabled = true
}

resource "aws_vpclattice_resource_gateway" "provider_rg" {
  name       = "latticerg-provider"
  vpc_id     = aws_vpc.provider.id
  subnet_ids = [aws_subnet.provider_subnet.id]

  tags = {
    Name = "Provider-Resource-Gateway"
  }

  depends_on = [aws_vpc.provider, aws_subnet.provider_subnet]
}


resource "aws_vpclattice_resource_configuration" "example" {
  name = "example"

  resource_gateway_identifier = aws_vpclattice_resource_gateway.provider_rg.id

  port_ranges = ["80"]
  protocol    = "TCP"

  resource_configuration_definition {
    ip_resource {
      ip_address = aws_instance.provider_bis_instance.private_ip
    }
  }

  tags = {
    Environment = "Example"
  }
}

resource "aws_vpclattice_service_network_resource_association" "example" {
  resource_configuration_identifier = aws_vpclattice_resource_configuration.example.id
  service_network_identifier        = aws_vpclattice_service_network.service_network.id

  tags = {
    Name = "Example"
  }
}

resource "aws_vpc_endpoint" "SNI-VPC2-Res" {
  vpc_id             = aws_vpc.client2.id
  resource_configuration_arn = aws_vpclattice_resource_configuration.example.arn
  vpc_endpoint_type  = "Resource"
  security_group_ids = [aws_security_group.allow_all.id]
  subnet_ids         = [aws_subnet.client2_subnet.id]
  private_dns_enabled = true
}