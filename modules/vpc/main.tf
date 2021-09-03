## VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  instance_tenancy     = "default" # (Optional) A tenancy option for instances launched into the VPC. Default is default, which makes your instances shared on the host. Using either of the other options (dedicated or host) costs at least $2/hr.
  enable_dns_support   = true # (Optional) A boolean flag to enable/disable DNS support in the VPC. Defaults true
  enable_dns_hostnames = true # (Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults false.
  enable_classiclink   = false # (Optional) A boolean flag to enable/disable ClassicLink for the VPC. Only valid in regions and accounts that support EC2 Classic. See the ClassicLink documentation for more information. Defaults false.

  tags = {
    Name = "${var.prefix_name}vpc"
  }
}

## 2 Public subnets
resource "aws_subnet" "main-public-subn" {
  count                   = length(var.public_subnets_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets_cidr[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.azs[count.index]

  tags = {
    Name = "${var.prefix_name}public-${count.index}"
  }
}

## Internet GW
resource "aws_internet_gateway" "main-gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix_name}public-gw"
  }

  # provisioner "local-exec" {
  #   when = destroy
  #   command = "echo 'Destruction de la passerelle internet ${self.arn}'"
  # }
}

## Public route tables
# Création d'une table de routage publique
# à associer à mes subnets publiques
resource "aws_route_table" "main-public-rtble" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-gw.id
  }

  tags = {
    Name = "${var.prefix_name}public-routetable"
  }
}

 ## Route associations public
 # Associer mes subnets publiques 
 # à ma table de routage publique
resource "aws_route_table_association" "main-public-assoc" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.main-public-subn[count.index].id
  route_table_id = aws_route_table.main-public-rtble.id
}

## Provide an AWS Elastic IP resource
# The EIP is in a VPC <vpc = true>
resource "aws_eip" "nat-eip" {
  vpc = true

  tags = {
    Name = "${var.prefix_name}eip"
  }
}

## NAT gw
# Le principe du NAT statique consiste à 
# associer une adresse IP publique 
# à une adresse IP privée interne au réseau.
resource "aws_nat_gateway" "nat-gw" {
  allocation_id     = aws_eip.nat-eip.id
  subnet_id         = aws_subnet.main-public-subn[0].id # (Required) The Subnet ID of the subnet in which to place the gateway.
  depends_on        = [aws_internet_gateway.main-gw]

  tags = {
    Name = "${var.prefix_name}nat"
  }
}

## 2 Private subnets
resource "aws_subnet" "main-private-subn" {
  count                   = length(var.private_subnets_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets_cidr[count.index]
  map_public_ip_on_launch = false # (Optional) Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is false.
  availability_zone       = var.azs[count.index]

  tags = {
    Name = "${var.prefix_name}private-${count.index}"
  }
}

## Private route tables
resource "aws_route_table" "main-private-rtble" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "${var.prefix_name}private-routetable"
  }
}

# Route associations private
resource "aws_route_table_association" "main-private-assoc"{
  count          = length(var.private_subnets_cidr)
  subnet_id      = aws_subnet.main-private-subn[count.index].id
  route_table_id = aws_route_table.main-private-rtble.id
}

