provider "aws" {
  region     = "ap-south-1"
  profile = "my1"
}

resource "aws_vpc" "taskvpc" {
    cidr_block= "192.168.0.0/16"
    enable_dns_hostnames= "true"
tags= {

    NAME= "taskvpc"  
      }  
}
resource "aws_subnet" "sub1" {
  availability_zone="ap-south-1a"
  vpc_id     = "${aws_vpc.taskvpc.id}"
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch= "true"

  tags = {
    Name = "sub1"
  }
}
resource "aws_subnet" "sub2" {
  availability_zone="ap-south-1b"  
  vpc_id     = "${aws_vpc.taskvpc.id}"
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "sub2"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.taskvpc.id}"

  tags = {
    Name = "mygw"
  }
}
resource "aws_route_table" "myroute" {
  vpc_id = "${aws_vpc.taskvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }


  tags = {
    Name = "myroute"
  }
}
resource "aws_route_table_association" "ras" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.myroute.id
}

resource "aws_security_group" "allow-http" {
  
  depends_on= [
	   aws_vpc.taskvpc
]
  name        = "allow-http"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.taskvpc.id}"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
}
 
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-http"
  }
}

resource "aws_security_group" "allow-bation-host" {
  
  depends_on= [
	   aws_vpc.taskvpc
]
  name        = "allow-bation-host"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.taskvpc.id}"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
}
 
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-bation-host"
  }
}
resource "aws_security_group" "allow-database" {
  name        = "allow-database"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.taskvpc.id}"

  ingress {
    description = "DATABASE"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [ "${aws_security_group.allow-http.id}" ]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-database"
  }
}

resource "aws_instance" "wordpress" {
  ami           = "ami-052c08d70def0ac62"
  instance_type = "t2.micro"
  key_name      =  "gpu"
  subnet_id = aws_subnet.sub1.id
  vpc_security_group_ids= [aws_security_group.allow-http.id ]
 
  tags = {
    Name = "wordpress"
  }
}

resource "aws_instance" "bation" {
  ami           = "ami-0732b62d310b80e97"
  instance_type = "t2.micro"
  key_name      =  "gpu"
  subnet_id = aws_subnet.sub1.id
  vpc_security_group_ids= [aws_security_group.allow-bation-host.id ]
  tags = {
    Name = "bation"
  }
}

resource "aws_instance" "dbos" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name      =  "gpu"
  subnet_id = aws_subnet.sub2.id
  vpc_security_group_ids= [aws_security_group.allow-database.id, aws_security_group.allow-bation-host.id ]
  tags = {
    Name = "dbos"
  }
}
/*
resource "aws_eip" "lb" {
  instance = "${aws_instance.dbos.id}"
  vpc      = true
  
}
*/
resource "aws_nat_gateway" "netgw" {
depends_on= [
        aws_internet_gateway.gw
]
  
  allocation_id = "eipalloc-01fb4a3dfe1944a26"
  subnet_id     = "${aws_subnet.sub1.id}"
tags = {
    Name = "my-nat"
  }
}

resource "aws_route_table" "natroute" {
  vpc_id = "${aws_vpc.taskvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.netgw.id}"
  }


  tags = {
    Name = "netroute"
  }
}


resource "aws_route_table_association" "ras1" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.natroute.id
}
