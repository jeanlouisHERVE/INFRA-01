variable "key_name" {
  type = string
}

variable "public_key_path" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "public_ssh_key" {
  description = "The public SSH key to use"
  type        = string
}

variable "private_ssh_key" {
  description = "The public SSH key to use"
  type        = string
}
