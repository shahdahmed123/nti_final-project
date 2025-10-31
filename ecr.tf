resource "aws_ecr_repository" "app_repo" {
  name = "listenary-app"
  image_scanning_configuration { scan_on_push = true }
  tags = { Name = "listenary-ecr" }
}
