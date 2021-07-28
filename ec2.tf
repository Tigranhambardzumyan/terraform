resource "aws_vpc" "jager_vpc" {
  cidr_block = var.vpc_cidr
  tags       = var.tags
}


resource "aws_subnet" "jager_subnet" {
  vpc_id     = aws_vpc.jager_vpc.id
  cidr_block = var.subnet_cidr
  tags       = var.tags
}

resource "aws_route_table" "jager_route_table" {
  vpc_id = aws_vpc.jager_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jager_gateway.id
  }

  tags = var.tags
}

resource "aws_internet_gateway" "jager_gateway" {
  vpc_id = aws_vpc.jager_vpc.id
  tags   = var.tags
}



//resource "aws_default_route_table" "jager_dfroute" {
//  default_route_table_id = aws_vpc.jager_vpc.default_route_table_id
//
//  route {
//    cidr_block = "0.0.0.0/0"
//    gateway_id = aws_internet_gateway.jager_gw.id
//  }
//  tags = var.tags
//}

resource "aws_route_table_association" "table_associate" {
  subnet_id      = aws_subnet.jager_subnet.id
  route_table_id = aws_route_table.jager_route_table.id
}

resource "aws_security_group" "jager_sg" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.jager_vpc.id

  ingress {
    description = "Allow SSH access to the Instance"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "Allow tcp port 3000 access to the Instance"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = var.tags
}



data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jager" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.jager_subnet.id
  vpc_security_group_ids = [aws_security_group.jager_sg.id]
  key_name               = aws_key_pair.jager_ssh_key.id

  tags = var.tags
}

resource "aws_eip" "assign_eip" {
  instance = aws_instance.jager.id
  vpc      = true
  tags     = var.tags
}


resource "aws_key_pair" "jager_ssh_key" {
  key_name   = "New"
  public_key = file("${path.module}/public.key")

}

resource "local_file" "inventory" {
  content = templatefile("inventory.tmpl",
    {
      public_ip = aws_instance.jager.public_ip
    }
  )
  filename = "inventory"
}


resource "null_resource" "run_ansible" {
  provisioner "local-exec" {
    command = "sleep 120 && ansible-playbook -i inventory playbook.yml"
  }
  depends_on = [
    aws_instance.jager
  ]


}
