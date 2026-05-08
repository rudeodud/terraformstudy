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
resource "aws_security_group" "web_sg_provisioner" {
  name        = "web-security-group-for-provisioner"
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

# 7. EC2 Instance 생성 (Subnet ID 명시)
resource "aws_instance" "web_server_provisioner" {
  ami           = "ami-0d4c056a16f3ae150" # 사용하려는 AMI ID로 변경하세요
  instance_type = "t2.micro"
  key_name      = "rootkey" # AWS에 등록된 키 페어 이름으로 변경
  subnet_id     = aws_subnet.main.id # 새로 생성한 Subnet ID 지정
  vpc_security_group_ids = [aws_security_group.web_sg_provisioner.id]

  user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
EOF

  provisioner "file" {
    source      = "${path.module}/index.html" # 로컬 HTML 파일 경로
    destination = "/tmp/index.html"       # EC2 인스턴스 내 임시 경로

    connection {
      type        = "ssh"
      user        = "ec2-user" # AMI에 따라 사용자 이름 변경 (예: ubuntu, centos )
      private_key = file("/Users/gyeongdaeyeong/Desktop/key/rootkey.pem") # SSH 키 파일의 로컬 전체 경로
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/index.html /var/www/html/index.html", # HTML 파일을 웹 서버 경로로 이동
      "sudo systemctl restart httpd" # 웹 서버 재시작
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/Users/gyeongdaeyeong/Desktop/key/rootkey.pem") # SSH 키 파일의 로컬 전체 경로
      host        = self.public_ip
    }
  }

  tags = {
    Name = "web-server-provisioner"
  }
}

output "public_ip" {
  value = aws_instance.web_server_provisioner.public_ip
  description = "The public IP address of the web server"
}
