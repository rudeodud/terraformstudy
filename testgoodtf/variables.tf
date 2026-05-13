variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
}

variable "key_name" {
  description = "EC2 인스턴스에 사용할 키 페어 이름"
  type        = string
}

variable "private_key_path" {
  description = "프라이빗 키 파일 경로"
  type        = string
}