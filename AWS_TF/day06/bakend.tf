terraform {
      backend "s3" {
        bucket = "mybuket-rudeodud"
        key = "dev/terraform.tfstate"
        region = "ap-northeast-2"
        encrypt = true
        # use_lockfile = true  ← 이 줄을 삭제하세요
    } 
}