
output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.listenary_db.address
}

output "ecr_repo_url" {
  value = aws_ecr_repository.app_repo.repository_url
}

output "rds_secret_arn" {
  value = aws_secretsmanager_secret.rds_secret.arn
}
