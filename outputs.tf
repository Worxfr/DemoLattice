output "vpc_client1_id" {
  value = aws_vpc.client1.id
}

output "vpc_client2_id" {
  value = aws_vpc.client2.id
}

output "vpc_client2_bis_id" {
  value = aws_vpc.client2_bis.id
}

output "vpc_provider_id" {
  value = aws_vpc.provider.id
}

output "vpc_provider_bis_id" {
  value = aws_vpc.provider_bis.id
}
