# vpc id
output "vpc_id" {
  value = aws_vpc.main.id
}

# private subnets list
output "private_subnet_ids" {
  value = [for private_subnet in aws_subnet.main-private-subn : private_subnet.id]
}

# public subnets list
output "public_subnet_ids" {
  value = [for public_subnet in aws_subnet.main-public-subn : public_subnet.id]
}
