variable "project" {
  description = "Google Cloud Project"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "Google Cloud zone"
  type        = string
  default     = "asia-northeast1-a"
}
