resource "aws_ecr_repository" "backend" {
  name                 = "self-healing-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = false
}

resource "aws_ecr_repository" "frontend" {
  name                 = "self-healing-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = false
}
