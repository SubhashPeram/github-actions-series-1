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
    inline = ["echo 'Wait until SSH is ready'"]
  
    connection {
      type		= "ssh"
	  user		= local.ssh_user
	  private_key = file(local.private_key_path)
	  host		= aws_instance.app_server.public_ip
    }
}

provisioner "local-exec" {
  command = "ansible-playbook -i $(aws_instance.app_server.public_ip), --private-key $(local.pri} deploy2tomcat.yml"
}
  
 provisioner "local-exec" {
     command = "echo ${aws_instance.app_server.public_ip} >> /home/ubuntu/testfile.txt"
 } 
}

output "EC2IPAddress" {
  value = aws_instance.app_server.public_ip
}
output "EC2PublicDNS" {
  value = aws_instance.app_server.public_dns
}
