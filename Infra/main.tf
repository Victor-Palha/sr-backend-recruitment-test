terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "ash-recruitment-tf-state"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = "ash/recruitment"
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  app_port     = var.app_port
}

module "rds" {
  source            = "./modules/rds"
  project_name      = var.project_name
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security.rds_security_group_id
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

module "alb" {
  source                = "./modules/alb"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  app_port              = var.app_port
}

module "ecs" {
  source                = "./modules/ecs"
  project_name          = var.project_name
  aws_region            = var.aws_region
  container_cpu         = var.container_cpu
  container_memory      = var.container_memory
  execution_role_arn    = module.iam.execution_role_arn
  task_role_arn         = module.iam.task_role_arn
  ecr_repository_url    = module.ecr.repository_url
  app_port              = var.app_port
  subnet_ids            = module.vpc.public_subnet_ids
  ecs_security_group_id = module.security.ecs_security_group_id
  target_group_arn      = module.alb.target_group_arn
  lb_listener_arn       = module.alb.listener_arn
  database_url          = var.database_url
  db_username           = var.db_username
  db_password           = var.db_password
  rds_endpoint          = module.rds.endpoint
  db_name               = var.db_name
  guardian_issuer       = var.guardian_issuer
  guardian_secret_key   = var.guardian_secret_key
  secret_key_base       = var.secret_key_base
  resend_api_key        = var.resend_api_key
}
