variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "ecs_ami_id" {
  type        = string
  default     = "ami-04e4606740c9c9381"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "security_groups" {
  type        = list(string)
  default     = ["sg-"]
}

variable "iam_instance_profile" {
  type        = string
  default     = "ecs-instance-profile"
}

variable "key_pair_name" {
  type        = string
  default     = "mykey"
}

variable "subnets" {
  type        = list(string)
  default     = ["subnet-", "subnet-", "subnet-"]
}

variable "vpc_id" {
  type        = string
  default     = "vpc-"
}
