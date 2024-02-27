# Allowed CIDR Blocks

variable "antiers_ip" {
  type        = list(string)
  description = "List of CIDR blocks allowed for Redis security group"
  default     = ["112.196.25.234/32", "182.73.149.42/32", "112.196.81.250/32", "125.21.216.158/32"]
}
