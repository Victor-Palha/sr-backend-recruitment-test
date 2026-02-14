variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "container_cpu" {
  description = "ECS task CPU units"
  type        = number
}

variable "container_memory" {
  description = "ECS task memory (MiB)"
  type        = number
}

variable "execution_role_arn" {
  description = "IAM execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "IAM task role ARN"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "app_port" {
  description = "Application port"
  type        = number
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS service"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "lb_listener_arn" {
  description = "ALB listener ARN (used for depends_on)"
  type        = string
}

# App environment variables
variable "database_url" {
  description = "Full DATABASE_URL override"
  type        = string
  default     = ""
}

variable "db_username" {
  description = "DB username for constructing DATABASE_URL"
  type        = string
  default     = ""
}

variable "db_password" {
  description = "DB password for constructing DATABASE_URL"
  type        = string
  sensitive   = true
  default     = ""
}

variable "rds_endpoint" {
  description = "RDS endpoint for constructing DATABASE_URL"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "DB name for constructing DATABASE_URL"
  type        = string
  default     = ""
}

variable "guardian_issuer" {
  description = "Guardian issuer"
  type        = string
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
