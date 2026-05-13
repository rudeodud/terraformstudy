terraform {
    backend "s3" {
        bucket = "mybuket-rudeodud"
        key = "dev/terraform.tfstate"
        region = "ap-northeast-2"
        encrypt = true
        # use_lockfile = true  ← 이 줄을 삭제하세요
    }  
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2" 
}

resource "aws_s3_bucket" "good_bucket" {
    bucket = "my-tf-text-bucket"

    tags = {
        name = "my-bucket 2.0"
        Environment = "dev" 
    }
}
