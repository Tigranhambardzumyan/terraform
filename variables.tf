variable "tags" {
  type = map(string)
  default = {
    Name = "Tigran_hambardzumyan"
    ResourceName = "Tigran_hambardzumyan"
  }
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  type = string
  default = "192.168.20.0/24"
}

variable "subnet_cidr" {
  type = string
  default = "192.168.20.0/25"
}
