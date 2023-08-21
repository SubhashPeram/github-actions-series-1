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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCJVNzcZlBKJAlhGL8LNjHJ72AtXmE1aAI9X3bFOerujfYMxp2a8+dVJ2uXHe1nR4Y1fdOWLsHoDRDgBuqTasbBIiCblBwR41tanYJnvVSNMirPkRQD46y/p3sMWGatxF8WgKId329izCqS3dn5X3W0WfPYToFobsyD6doc0vG4SP4ZtGnm9G4lQnMjBFYBisdT4wOG5w0Oi51W2JvGbeBnZZuZQZzapsqNuJbKygC3M9WrCWF7i4ENJH+dC9GFDOzSjAMDF8UEPXwgFqRwBlqnz2HD4hxtC2eKSJuQWdiaQF2eCsX3fs6Xf8PL6Q9QDDVngRVXGw4jdzf+v38fvp3Jh2SFCdaBQFYCnEXtjrGSVdsAZX1o221lEHDd0HQqPYAeJr7fmR5zxzNVVOOql9ZbNxpVbHFxVnqPhS/AnJn7assTAIZo0Zv1x0IzDnenSo7WLH5jk+p6paiidf3J0/KTY8Hd6Z5nGFm5nKhk1G1Jt+/IvqYMoi7NMjSrFrqiejs= ubuntu@ip-172-31-33-94"
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
#  private_key = file("./developer")
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
