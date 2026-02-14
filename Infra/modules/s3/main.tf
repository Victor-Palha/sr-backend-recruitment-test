resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-tf-state"

  lifecycle {
    prevent_destroy = false
  }

  tags = { Name = "${var.project_name}-tf-state" }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}
