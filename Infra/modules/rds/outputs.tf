output "endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.app.endpoint
}

output "address" {
  description = "RDS instance address (host only)"
  value       = aws_db_instance.app.address
}
