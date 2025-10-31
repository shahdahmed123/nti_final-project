resource "aws_secretsmanager_secret" "rds_secret" {
  name        = "listenary/rds"
  description = "RDS credentials for Listenary app"
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = aws_db_instance.listenary_db.username
    password = aws_db_instance.listenary_db.password
    host     = aws_db_instance.listenary_db.address
    port     = aws_db_instance.listenary_db.port
    dbname   = var.rds_db_name
  })
  depends_on = [aws_db_instance.listenary_db]
}
