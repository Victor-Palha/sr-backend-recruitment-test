resource "aws_db_subnet_group" "app" {
  name       = "${var.project_name}-db-subnet"
  subnet_ids = var.subnet_ids

  tags = { Name = "${var.project_name}-db-subnet" }
}

resource "aws_db_parameter_group" "no_ssl" {
  name   = "${var.project_name}-no-ssl"
  family = "postgres17"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  tags = { Name = "${var.project_name}-no-ssl" }
}

resource "aws_db_instance" "app" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "17"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  parameter_group_name   = aws_db_parameter_group.no_ssl.name
  db_subnet_group_name   = aws_db_subnet_group.app.name
  vpc_security_group_ids = [var.security_group_id]

  publicly_accessible     = true
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0

  tags = { Name = "${var.project_name}-db" }
}
