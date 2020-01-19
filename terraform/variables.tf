variable "region" {
  description = "The AWS region to deploy into."
  default     = "ap-southeast-2"
}

variable "app_version" {
}

variable "bucket_name" {
  default = "resizer-lambda-bucket"
}