resource "aws_vpc" "tform_vpc" {
  cidr_block = "10.123.0.0/16"

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "tform_public_subnet" { ###Create Subnet
  vpc_id                  = aws_vpc.tform_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "tform_internet_gateway" { ###Create Internet Gateway
  vpc_id = aws_vpc.tform_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "tform_public_rt" { ###Create Route Table
  vpc_id = aws_vpc.tform_vpc.id

  tags = {
    Name = "dev-public-rt"
  }
}

resource "aws_route" "default_route" { ###Create Route
  route_table_id         = aws_route_table.tform_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tform_internet_gateway.id

}

resource "aws_route_table_association" "tform_public_assoc" { ###Create Route Table Association
  route_table_id = aws_route_table.tform_public_rt.id
  subnet_id      = aws_subnet.tform_public_subnet.id
}

resource "aws_security_group" "tform_sg" { ###Create Security Group
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.tform_vpc.id


  ingress { ### Allow SSH 
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["76.21.202.116/32"]
  }

  ingress { ### Allow HTTPS 
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev_security_group"
  }
}


resource "aws_key_pair" "tform_auth" { ###Create SSH Key Pair
  key_name   = "tformkey"
  public_key = file("~/.ssh/aws_tformkey.pub")
}


resource "aws_instance" "dev_node" {
  ami                    = data.aws_ami.server_ami.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.tform_auth.id
  vpc_security_group_ids = [aws_security_group.tform_sg.id]
  subnet_id              = aws_subnet.tform_public_subnet.id
  user_data              = file("aws_customdata.tpl")
  root_block_device {
    volume_size = 10

  }
  tags = {
    Name = "dev-node"
  }

  provisioner "local-exec" {
    command = templatefile("mac-ssh-script.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/aws_tformkey"
    })
    interpreter = var.host_os == "mac" ? ["bash", "-c"] : ["zsh", "-c"]
  }

}


locals {
  dev_name = coalesce(
    try(aws_instance.dev_node.tags["Name"], null),
    try(aws_instance.dev_node.tags_all["Name"], null),
    aws_instance.dev_node.id
  )
}

output "dev_public_ip_address" {
  value = format("%s:%s", local.dev_name, aws_instance.dev_node.public_ip)
}
