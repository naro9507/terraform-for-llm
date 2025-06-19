variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "region" {
  description = "The AWS region for resource deployment"
  type        = string
  default     = "ap-northeast-1" # 東京リージョン
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "Local"
}
