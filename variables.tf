variable "region-master" {
  type = string
}

variable "region-worker" {
  type = string
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "ip" {
  type = string
}

variable "mykey" {
  type = string
}

variable "workers-count" {
  type    = number
  default = 1
}

variable "instance-type" {
  type    = string
  default = "t2.micro"
}
