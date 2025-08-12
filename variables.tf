variable "key_name" {
  default = "sartrouville-laptop"
  type    = string
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
  type    = string
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
  type    = string
}

