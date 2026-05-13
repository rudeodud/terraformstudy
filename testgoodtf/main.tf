resource "aws_instance" "helloworld" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = {
    Name = "HelloWorld"
  }
  
}