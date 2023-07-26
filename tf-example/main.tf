data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/*20.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
    
    owners = ["099720109477"] # Canonical
}

provider "aws" {
  region  = "eu-north-1"
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
 # vpc_security_group_ids = [aws_security_group.allow_tls.id]
  security_groups = [aws_security_group.allow_tls.name]
  key_name      = "app-ssh-key"

  tags = {
    Name = var.ec2_name
  }
 provisioner "local-exec" {
     command = "echo ${aws_instance.app_server.public_ip} >> /home/ubuntu/testfile.txt"
     command = "echo ${aws_instance.app_server.instance_id} >> /home/ubuntu/testfile.txt"
 }

 output "EC2IPAddress" {
 value = aws_instance.app_server.public_ip
 }
 output "EC2InstanceId" {
 value = aws_instance.app_server.instance_id
 }
 
}
