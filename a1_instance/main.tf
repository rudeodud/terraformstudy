resource "aws_instance" "name" {
    ami = data.aws_ami.amazom_linux_20203.id
    instance_type = var.instance_type
}