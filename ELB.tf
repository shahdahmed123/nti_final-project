# ----------------------------
# Random ID للـ S3 Bucket
# ----------------------------
resource "random_id" "elb_bucket_id" {
  byte_length = 4
}

# ----------------------------
# S3 Bucket لتخزين ELB Access Logs
# ----------------------------
resource "aws_s3_bucket" "elb_logs" {
  bucket = "listenary-elb-logs-${random_id.elb_bucket_id.hex}"

  tags = {
    Name = "listenary-elb-logs"
  }

  force_destroy = true # لازم تمسح أي objects جوه الـ bucket قبل destroy
}

# S3 Bucket versioning (بديل عن deprecated versioning block)
resource "aws_s3_bucket_versioning" "elb_logs_versioning" {
  bucket = aws_s3_bucket.elb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}


# ----------------------------
# Bucket policy للـ ELB logs
# ----------------------------
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "elb_logs_policy" {
  bucket = aws_s3_bucket.elb_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "elasticloadbalancing.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.elb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/listenary-alb/*"
          }
        }
      }
    ]
  })
}



# ----------------------------
# Security Group للـ ALB
# ----------------------------
resource "aws_security_group" "elb_sg" {
  name   = "listenary-elb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "listenary-elb-sg" }
}

# ----------------------------
# Application Load Balancer (ALB)
# ----------------------------
resource "aws_lb" "listenary_alb" {
  name               = "listenary-alb"
  load_balancer_type = "application"
  subnets = [
  aws_subnet.public_subnet.id,
  aws_subnet.public_subnet_2.id
]

  security_groups    = [aws_security_group.elb_sg.id]

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.elb_logs.bucket
    prefix  = "access-logs"
    enabled = true
  }

  tags = {
    Name = "listenary-alb"
  }
}

# ----------------------------
# Target Group للـ ALB
# ----------------------------
resource "aws_lb_target_group" "listenary_tg" {
  name        = "listenary-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
}

# ----------------------------
# Listener للـ ALB
# ----------------------------
# ----------------------------
# Outputs
# ----------------------------
output "alb_dns_name" {
  value = aws_lb.listenary_alb.dns_name
}

output "elb_logs_bucket" {
  value = aws_s3_bucket.elb_logs.bucket
}
resource "aws_lb_listener" "listenary_listener" {
  load_balancer_arn = aws_lb.listenary_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.listenary_tg.arn
  }
}
