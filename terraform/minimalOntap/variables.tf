variable "name" {
  type     = string
  nullable = false
  default  = "STACM3AWSSTORAGETESTING"
}

variable "main_box_instance_type" {
  type     = string
  nullable = false
}

variable "ontapSize" {
  type     = number
  nullable = false
  default  = 8096
}

variable "ontapThroughput" {
  type     = number
  nullable = false
  default  = 2048
}

variable "ontapIOPS" {
  type     = number
  nullable = false
  default  = 80000
}