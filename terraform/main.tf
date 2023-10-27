provider "aws" {
  region = "us-east-1"
  access_key = "XXXX(placeholder - key should not be public)XXXX"
  secret_key = "XXXX(placeholder - key should not be public)XXXX"
}

resource "aws_instance" "ec2_instance" {
  instance_type = "t2.micro"
  key_name = aws_key_pair.tf_key.key_name
  vpc_security_group_ids = [aws_security_group.tf_sg.id]
  ami = "ami-053b0d53c279acc90"

  tags = {
    Name = "htw-master-ubuntu"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update
              apt-get install -y docker-ce
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu  # Add the 'ubuntu' user to the 'docker' group

              curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              EOF
}

resource "aws_key_pair" "tf_key" {
  key_name   = "tf_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "tf_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tf_key.pem"
}

resource "aws_security_group" "tf_sg" {
  name        = "aws security group"
  description = "aws security group"

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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