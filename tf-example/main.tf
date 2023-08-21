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
resource "aws_key_pair" "developer" {
  key_name = "developer"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDvb5Qcxrh/LoZm/PtK70hMsYyqBHIbrpNBGtuvhE8fINTxGzHAOjly++ngAKEZwTIAn6mXvnosmks8zYS6L9E2Zq8bM8y57FA25E84i07fpUcvoJx+7AcJCRaxgrUp7C6AhqeB7rq5zF9wY53me4SDCbKyTwzWH9zsHSc3OAQJz0nwej6ispPc0WFTiyyVx4aPMRz18suZMGttIqHmCqstUpPTwc9nctjd5xOk92kGr80lmlc2C0cf+OpODQmEwGupYVssvm3wvquqxQZSA+KAw262ziV+0GxsVJqZ6T3KBa7xSIfPDrA6/SUBx3etgLpAQ6i7XLcnScXmEy9lYi0l app-ssh-key"
}

variable "privatekey" {
  default = "developer"
}
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
 # vpc_security_group_ids = [aws_security_group.allow_tls.id]
  security_groups = [aws_security_group.allow_tls.name]
  key_name      = "developer"

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
