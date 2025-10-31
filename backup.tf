resource "aws_backup_vault" "jenkins_vault" {
  name = "jenkins-backup-vault"
}

resource "aws_backup_plan" "jenkins_daily" {
  name = "jenkins-daily"
  rule {
    rule_name         = "daily-rule"
    target_vault_name = aws_backup_vault.jenkins_vault.name
    schedule          = "cron(0 3 * * ? *)" # daily at 03:00 UTC
    lifecycle {
      delete_after = 30
    }
  }
}

# iam role for backup (if needed)
resource "aws_iam_role" "backup_role" {
  name = "aws-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "backup.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}
# attach managed policy
resource "aws_iam_role_policy_attachment" "backup_role_attach" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_selection" "jenkins_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "jenkins-selection"
  plan_id      = aws_backup_plan.jenkins_daily.id
  resources    = [aws_instance.jenkins.arn]
}
