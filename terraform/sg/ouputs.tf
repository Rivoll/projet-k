output "security_group_id" {
  description = "L'ID du Security Group créé"
  value       = aws_security_group.this.id
}

output "security_group_name" {
  description = "Le nom du Security Group créé"
  value       = aws_security_group.this.name
}
