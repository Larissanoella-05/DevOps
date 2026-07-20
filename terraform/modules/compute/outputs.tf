output "instance_id" {
  description = "ID of the application VM."
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IP address of the application VM."
  value       = aws_instance.app.public_ip
}
