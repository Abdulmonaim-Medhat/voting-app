output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "web_private_ip" {
  value = aws_instance.web.private_ip
}

output "data_public_ip" {
  value = aws_instance.data.public_ip
}

output "data_private_ip" {
  value = aws_instance.data.private_ip
}
