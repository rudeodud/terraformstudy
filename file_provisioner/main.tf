provider "aws" {
  region = "ap-northeast-2"
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
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
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

# 6. Security Group 생성
resource "aws_security_group" "web_sg" {
  name        = "web-security-group-for-html"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

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

# 7. EC2 Instance 생성
resource "aws_instance" "web_server" {
  ami                    = "ami-0d4c056a16f3ae150"
  instance_type          = "t2.micro"
  key_name               = "rootkey"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # user_data: Apache 설치 및 시작 + 완료 플래그 파일 생성
  user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
mkdir -p /var/www/html
# provisioner가 감지할 수 있도록 완료 플래그 파일 생성
touch /tmp/httpd_ready
EOF

  # file 프로비저너: 로컬 index.html 파일을 EC2로 복사
  provisioner "file" {
    source      = "${path.module}/index.html"
    destination = "/tmp/index.html"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/Users/gyeongdaeyeong/Desktop/key/rootkey.pem")
      host        = self.public_ip
      timeout     = "5m"
      agent       = false
    }
  }

  # remote-exec 프로비저너: httpd 설치 완료 대기 후 파일 이동
  provisioner "remote-exec" {
    inline = [
      # httpd 설치 완료 플래그 파일이 생길 때까지 대기 (최대 5분)
      "echo 'Waiting for httpd installation...'",
      "timeout 300 bash -c 'while [ ! -f /tmp/httpd_ready ]; do sleep 5; echo \"still waiting...\"; done'",
      "echo 'httpd is ready!'",

      # index.html 이동 및 권한 설정
      "sudo mkdir -p /var/www/html",
      "sudo cp /tmp/index.html /var/www/html/index.html",
      "sudo chmod 644 /var/www/html/index.html",
      "sudo chown apache:apache /var/www/html/index.html",

      # Apache 재시작
      "sudo systemctl restart httpd",
      "echo 'Done!'"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/Users/gyeongdaeyeong/Desktop/key/rootkey.pem")
      host        = self.public_ip
      timeout     = "5m"
      agent       = false
    }
  }

  tags = {
    Name = "web-server-file-provisioner"
  }
}

output "public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "The public IP address of the web server"
}