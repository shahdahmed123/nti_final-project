# IAM role for EC2 (Jenkins)
resource "aws_iam_role" "jenkins_ec2_role" {
  name = "jenkins-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com" },
      Effect    = "Allow",
    }]
  })
}

# Attach managed policies (least privilege recommended to tighten later)
resource "aws_iam_role_policy_attachment" "jenkins_ec2_ecr" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
resource "aws_iam_role_policy_attachment" "jenkins_ec2_secrets" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
resource "aws_iam_role_policy_attachment" "jenkins_ec2_s3" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# instance profile
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_ec2_role.name
}

# Security group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["197.48.254.12/32"] 
    description = "SSH from admin"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # if you want public access (or tighten later)
    description = "Jenkins UI"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Data source for latest Amazon Linux 2 AMI (or use Ubuntu)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Jenkins EC2
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.jenkins_instance_type
  subnet_id                   = element(var.public_subnets, 0)
  key_name                    = var.jenkins_key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name
  associate_public_ip_address = true
  tags                        = { Name = "jenkins-server" }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y openjdk-11-jdk docker.io awscli
              systemctl enable --now docker
              # install Jenkins (use official instructions)
              wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
              sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
              apt update -y
              apt install -y jenkins
              systemctl enable --now jenkins
              # docker group
              usermod -aG docker ubuntu
              EOF
}

