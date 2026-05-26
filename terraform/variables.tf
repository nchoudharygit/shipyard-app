variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
}
variable "my_ip" {
  description = "Your local machine IP for SSH access"
  type        = string
}

variable "public_key" {
  description = "SSH public key content"
  type        = string
}