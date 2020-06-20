output "instance_ip" {
  value = aws_eip.ip-test-env.public_ip
}