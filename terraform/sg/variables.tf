variable "sg_name" {
  description = "Name of the Security Group"
  type        = string
}

variable "sg_description" {
  description = "Description of the Security Group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the Security Group will be created"
  type        = string
}

variable "ingress_rules" {
  description = "List of ingress rules (allow CIDR or Security Groups)"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))  # Optional CIDR-based rules
    security_groups = optional(list(string))  # Optional Security Group references
  }))
}

variable "egress_rules" {
  description = "List of egress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "tags" {
  description = "Tags for the Security Group"
  type        = map(string)
  default     = {}
}