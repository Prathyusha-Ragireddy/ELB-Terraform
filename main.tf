# Provider - specifying the cloud you want to use
provider "aws"{
region = "${var.aws_region}"
}

# Define VPC
resource "aws_vpc" "main"{
cidr_block       = "10.0.0.0/16"
enable_dns_hostnames = true
tags = {
    Name = "ELB-VPC"
  }
}

# Define Public DNS
resource "AWS_subnet" "public-subnet" {
 vpc_id = "${aws_vpc.main.id}"
 cidr_block = "${var.public_subnet_cidr}"
 availability_zone = "us-east-1a"
 tags = {
 Name = "ELB-VPC Public Subnet"
 }
}


# Define Public DNS
resource "AWS_subnet" "Private-subnet" {
 vpc_id = "${aws_vpc.main.id}"
 cidr_block = "${var.Private_subnet_cidr}"
 availability_zone = "us-east-1a"
 tags = {
 Name = "ELB-VPC Private Subnet"
 }
}

# Define Internet Gateway
resource "Aws_internet_gateway" "IGW" {
vpc_id = "${aws_vpc.main.id}"
tags = {
Name = "ELB-VPC IGW"
}
}

# Define Route Table
resource "aws_route_table" "public-RT" {
vpc_id = "${aws_vpc.main.id}"

route {
  cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.IGW.id}"
}

tags = {
Name = "ELB-VPC public Route Table"
}
}

# Assign the route table to the public Subnet
resource "aws_route_table_association" "public-RT" {
  subnet_id = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.public-RT.id}"
}
# Define the security group for public subnet
resource "aws_security_group" "sgweb" {
  name = "vpc_test_web"
  description = "Allow incoming HTTP connections & SSH access"

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
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  vpc_id="${aws_vpc.main.id}"

  tags = {
    Name = "Web Server SG"
  }
}
# Define SSH key pair for our instances
resource "aws_key_pair" "default" {
  key_name = "vpctestkeypair"
  public_key = "${file("${var.key_path}")}"
}



# Creating Launch Configuration
resource "aws_launch_configuration" "test" {
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.sgweb.id}"]
  key_name = "${aws_key_pair.default.id}"
  user_data = "${file("install.sh")}"
}

# Creating AutoScaling Group
resource "aws_autoscaling_group" "test" {
  launch_configuration = "${aws_launch_configuration.test.id}"
  vpc_zone_identifier       = ["${aws_subnet.public-subnet.id}"]
  min_size = 2
  max_size = 10
  load_balancers = ["${aws_elb.app.name}"]
  health_check_type = "ELB"

  tags = {
    Name = "webserver"
  }

}

resource "aws_elb" "app" {
  /* Requiered for EC2 ELB only
    availability_zones = "${var.zones}"
  */
  name            = "test-elb"
  subnets         = ["${aws_subnet.public-subnet.id}"]
  security_groups = ["${aws_security_group.sgweb.id}"]
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "8080"
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:8080/"
  }
  cross_zone_load_balancing   = true
  idle_timeout                = 960  # set it higher than the conn. timeout of the backend servers
  connection_draining         = true
  connection_draining_timeout = 300
  tags = {
    Name = "test-elb-app"
    Type = "elb"
  }
}

resource "aws_security_group" "elb" {
    name = "test-elb"
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
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
    vpc_id = "${aws_vpc.main.id}"
    tags = {
        Name        = "test-elb-security-group"
    }
}
