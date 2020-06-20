provider "aws" {
  region = "us-east-1"
  shared_credentials_file = var.local_creds_file
  profile = "private"
}

locals {
  common_tags = {
    Name = "TF_Hello"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = local.common_tags
}

resource "aws_eip" "ip-test-env" {
  instance = "${aws_instance.a.id}"
  vpc      = true

  tags = local.common_tags
}

resource "aws_subnet" "main" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = local.common_tags
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = local.common_tags
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = local.common_tags
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.main.id
  route_table_id = aws_route_table.r.id
}

resource "aws_security_group" "allow_http" {
  name = "TF_Hello Security Group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}


resource "aws_instance" "a" {
  connection {
    user = "ubuntu"
    host = self.public_ip
  }
  key_name = aws_key_pair.auth.id

  ami = "ami-1d4e7a66"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  subnet_id = aws_subnet.main.id

  provisioner "file" {
    source = var.local_nginx_conf
    destination = "/tmp/nginx.conf"
  }

  provisioner "file" {
    source = var.local_index_html
    destination = "/tmp/index.html"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo scp /tmp/nginx.conf /etc/nginx/",
      "sudo scp /tmp/index.html /var/www/html/index.html",
      "sudo service nginx start",
    ]
  }

  tags = local.common_tags
}
