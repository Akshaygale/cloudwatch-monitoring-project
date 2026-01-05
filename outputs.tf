output "instance_public_ip" {
  value = aws_instance.monitoring_server.public_ip
}
