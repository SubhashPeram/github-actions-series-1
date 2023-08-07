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

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.11.0"
    }
  }
}

provider "aws" {
  region  = "eu-north-1"
}
resource "aws_key_pair" "app-ssh-key" {
  key_name = "app-ssh-key"
  public_key = ""
}

variable "privatekey" {
  default = "developer"
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
provisioner "remote-exec" {
  inline = [
     "echo 'build ssh connection' "
]
  
connection {
  type		= "ssh"
  user		= "ubuntu"
# private_key = file("./app-ssh-key")
  host		= self.public_ip
  }
}

provisioner "local-exec" {
  command = "ansible-playbook -i ${aws_instance.app_server.public_ip}, --private-key ${var.privatekey} deploy2tomcat.yml"
 } 
}

output "EC2IPAddress" {
  value = aws_instance.app_server.public_ip
}
output "EC2PublicDNS" {
  value = aws_instance.app_server.public_dns
}
output "EC2AZ" {
  value = aws_instance.app_server.availability_zone
}
