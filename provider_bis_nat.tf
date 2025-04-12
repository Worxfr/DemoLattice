# Public subnet for the provider bis VPC
resource "aws_subnet" "provider_bis_public_subnet" {
  vpc_id                  = aws_vpc.provider_bis.id
  cidr_block             = "10.200.0.128/25"  # New CIDR for public subnet
  availability_zone       = aws_subnet.provider_bis_subnet.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "provider-bis-public-subnet"
  }
}

# Internet Gateway for provider bis
resource "aws_internet_gateway" "provider_bis_igw" {
  vpc_id = aws_vpc.provider_bis.id

  tags = {
    Name = "provider-bis-igw"
  }
}

# NAT Gateway for provider bis
resource "aws_eip" "provider_bis_nat_eip" {
  domain = "vpc"
  tags = {
    Name = "provider-bis-nat-eip"
  }
}

resource "aws_nat_gateway" "provider_bis_nat" {
  allocation_id = aws_eip.provider_bis_nat_eip.id
  subnet_id     = aws_subnet.provider_bis_public_subnet.id

  tags = {
    Name = "provider-bis-nat"
  }
}

# Route table for public subnet
resource "aws_route_table" "provider_bis_public_rt" {
  vpc_id = aws_vpc.provider_bis.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.provider_bis_igw.id
  }

  tags = {
    Name = "provider-bis-public-rt"
  }
}

# Associate public route table with public subnet
resource "aws_route_table_association" "provider_bis_public_rta" {
  subnet_id      = aws_subnet.provider_bis_public_subnet.id
  route_table_id = aws_route_table.provider_bis_public_rt.id
}

# Add NAT Gateway route to the private subnet route table
resource "aws_route" "provider_bis_private_nat_gateway" {
  route_table_id         = aws_route_table.provider_bis_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id        = aws_nat_gateway.provider_bis_nat.id
}