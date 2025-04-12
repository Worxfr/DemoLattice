# Public subnet for the provider VPC
resource "aws_subnet" "provider_public_subnet" {
  vpc_id                  = aws_vpc.provider.id
  cidr_block             = "10.1.0.128/25"  # New CIDR for public subnet
  availability_zone       = aws_subnet.provider_subnet.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "provider-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "provider_igw" {
  vpc_id = aws_vpc.provider.id

  tags = {
    Name = "provider-igw"
  }
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "provider-nat-eip"
  }
}

resource "aws_nat_gateway" "provider_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.provider_public_subnet.id

  tags = {
    Name = "provider-nat"
  }
}

# Route table for public subnet
resource "aws_route_table" "provider_public_rt" {
  vpc_id = aws_vpc.provider.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.provider_igw.id
  }

  tags = {
    Name = "provider-public-rt"
  }
}

# Associate public route table with public subnet
resource "aws_route_table_association" "provider_public_rta" {
  subnet_id      = aws_subnet.provider_public_subnet.id
  route_table_id = aws_route_table.provider_public_rt.id
}

# Add NAT Gateway route to the private subnet route table
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.provider_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id        = aws_nat_gateway.provider_nat.id
}


