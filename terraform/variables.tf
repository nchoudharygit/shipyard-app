variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1"
  
}

variable "key_pair_name" {
  description = "The name of the AWS EC2 Key Pair for SSH access"
}