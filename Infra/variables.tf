variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ash-recruitment"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "recruitment_test"
}

variable "database_url" {
  description = "Full DATABASE_URL for the application"
  type        = string
  sensitive   = true
  default     = ""
}

variable "guardian_issuer" {
  description = "Guardian issuer"
  type        = string
  default     = "recruitment_test"
}

variable "guardian_secret_key" {
  description = "Guardian secret key"
  type        = string
  sensitive   = true
}

variable "secret_key_base" {
  description = "Phoenix secret key base"
  type        = string
  sensitive   = true
}

variable "resend_api_key" {
  description = "Resend API key"
  type        = string
  sensitive   = true
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 4000
}

variable "container_cpu" {
  description = "ECS task CPU units"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "ECS task memory (MiB)"
  type        = number
  default     = 512
}
