provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  profile = "private"
}

locals {
  common_tags = {
    Name = "TF Database Task"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = local.common_tags
}

resource "aws_subnet" "main" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = local.common_tags
}
resource "aws_subnet" "secondary" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"

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

resource "aws_security_group" "allow_ssh" {
  name = "TF_Hello_Database_Security_Group"
  vpc_id = aws_vpc.main.id

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

resource "aws_security_group" "connect_db" {
  name = "TF_Hello_Connect_DB"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 3306
    protocol = "tcp"
    to_port = 3306
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 3306
    protocol = "tcp"
    to_port = 3306
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
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id = aws_subnet.main.id

  tags = local.common_tags
}

resource "aws_db_subnet_group" "mysql_subnet_group"{
  name = "mysqlsubgroup"
  subnet_ids = [aws_subnet.main.id, aws_subnet.secondary.id]

  tags = local.common_tags
}

resource "aws_db_instance" "mysql_db" {
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.connect_db.id]
  db_subnet_group_name = aws_db_subnet_group.mysql_subnet_group.name

  allocated_storage = 8
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "5.7.22"
  instance_class = "db.t2.micro"
  name = "mysqldb"
  username = var.db_username
  password = var.db_pass
  skip_final_snapshot = true
}
