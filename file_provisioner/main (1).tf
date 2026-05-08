provider "aws" {
  region = "ap-northeast-2" # 원하는 AWS 리전으로 변경하세요
}

# 1. VPC 생성
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-terraform-vpc"
  }
}

# 2. Subnet 생성
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a" # 원하는 가용 영역으로 변경하세요
  map_public_ip_on_launch = true # EC2 인스턴스에 Public IP 자동 할당
  tags = {
    Name = "my-terraform-subnet"
  }
}

# 3. Internet Gateway 생성 및 VPC에 연결
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "my-terraform-igw"
  }
}

# 4. Route Table 생성 및 Internet Gateway 연결
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "my-terraform-route-table"
  }
}

# 5. Subnet과 Route Table 연결
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# 6. Security Group 생성 (VPC ID 명시)
resource "aws_security_group" "web_sg" {
  name        = "web-security-group-for-html"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id # 새로 생성한 VPC ID 지정

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 7. EC2 Instance 생성 (user_data로 모든 설정 통합)
resource "aws_instance" "web_server" {
  ami           = "ami-0d4c056a16f3ae150" # 사용하려는 AMI ID로 변경하세요 (Ubuntu 24.04 LTS)
  instance_type = "t2.micro"
  key_name      = "rootkey" # AWS에 등록된 키 페어 이름으로 변경
  subnet_id     = aws_subnet.main.id # 새로 생성한 Subnet ID 지정
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<EOF
#!/bin/bash

# Ubuntu 패키지 업데이트 및 Apache2 설치
sudo apt-get update -y
sudo apt-get install -y apache2

# Apache2 서비스 시작 및 부팅 시 자동 실행 설정
sudo systemctl start apache2
sudo systemctl enable apache2

# 웹 루트 디렉토리 생성 (혹시 없을 경우)
sudo mkdir -p /var/www/html

# index.html 파일 생성 및 내용 삽입
sudo tee /var/www/html/index.html > /dev/null <<'HTML_CONTENT'
$(cat ${path.module}/index.html)
HTML_CONTENT

# Apache2 서비스 재시작 (변경사항 적용)
sudo systemctl restart apache2
EOF

  tags = {
    Name = "web-server-user-data-final"
  }
}

output "public_ip" {
  value = aws_instance.web_server.public_ip
  description = "The public IP address of the web server"
}
