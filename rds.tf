# Security group for RDS (allow from VPC / specific SGs)
resource "aws_security_group" "rds_sg" {
  name        = "listenary-rds-sg"
  description = "Allow DB access from EKS and Jenkins"
  vpc_id      = var.vpc_id

  # allow MySQL from private subnets (adjust in production)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # or better: reference specific security groups
    description = "Allow MySQL within VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "listenary-rds-sg" }
}

# DB subnet group (use private subnets)
resource "aws_db_subnet_group" "rds_subnets" {
  name = "listenary-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet.id,
    aws_subnet.private_subnet_2.id
  ]
  tags = {
    Name = "listenary-db-subnet-group"
  }
}


# RDS instance
resource "aws_db_instance" "listenary_db" {
  identifier              = "listenary-db"
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  db_name                 = var.rds_db_name
  username                = var.rds_master_username
  password                = var.rds_master_password
  db_subnet_group_name    = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false # change true for HA (cost up)
  storage_encrypted       = true
  backup_retention_period = 7
  deletion_protection     = false
  tags                    = { Name = "listenary-rds" }
}
