resource "aws_codecommit_repository" "demo" {
  repository_name = "demo"
  description     = "This is the demo repository"
}


resource "null_resource" "codecommit_push" {
  depends_on =[aws_codecommit_repository.demo]
  provisioner "local-exec" {
    command = "./codecommit_push.sh"
  }
}

