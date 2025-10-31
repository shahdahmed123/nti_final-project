variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "vpc_id" {}
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }

variable "jenkins_key_name" { type = string } # key pair name for SSH
variable "jenkins_instance_type" { default = "t3.medium" }

variable "rds_engine" { default = "mysql" } # or "postgres"
variable "rds_engine_version" { default = "8.0" }
variable "rds_instance_class" { default = "db.t3.micro" }
variable "rds_allocated_storage" { default = 20 }
variable "rds_db_name" { default = "listenarydb" }

# secrets (don't hardcode passwords here in production)
variable "rds_master_username" { default = "listenary" }
variable "rds_master_password" {
  description = "RDS master password"
  type        = string
}
variable "public-subnet-2" {
  type        = list(string)
  description = "List of second public subnet IDs"
}


