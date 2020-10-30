provider "aws" {
  region = "${var.region}" 
  version = "2.59"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

provider "aws" { 
  region = "${var.region}" 
  version = "2.59"
} 

# # Key Pair
# # #######################################################
resource "aws_key_pair" "key" {
  key_name   = "BastionKey"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}


# # Auto Scaling Group
# # #######################################################

data "template_file" "init" {
  template = "${file("${path.module}/userdata.sh")}"
}

resource "aws_launch_template" "example" {
 name_prefix   = "example"
  image_id      = "${data.aws_ami.image.id}"
  instance_type = "t2.micro"
  user_data       = "${base64encode(data.template_file.init.rendered)}"
  vpc_security_group_ids = ["${aws_security_group.allow.id}"]
  #vpc_security_group_ids = ["sg-03ffb4fa277838623"]
  #key_name = "${aws_key_pair.key.key_name}"
}

resource "aws_autoscaling_group" "example" {
  name               = "ASG1"
  availability_zones = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c",
  ]

  desired_capacity = "${var.desired_capacity}"
  max_size         = "${var.max_size}"
  min_size         = "${var.min_size}"
  
launch_template  {
    id = "${aws_launch_template.example.id}"
    
    }
  }

# # VPC
# # #######################################################

resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  tags = "${var.tags}"
}

# # Security Group
# # #######################################################

resource "aws_security_group" "allow" {
  name        = "Patraallowit"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"


  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "TLS from VPC"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
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
    Name = "allow_tls"
  }
}

# # Variables
# # #######################################################

variable "access_key" {}
variable "secret_key" {}
#variable "aws_region" {}
variable "vpc_cidr" {}
variable "public1_cidr" {}
variable "public2_cidr" {}
variable "public3_cidr" {}
variable "route_table_cidr" {}
variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}
variable "region" {}
variable "region_name" {}
variable "image_owner" {}
variable "tags" {
    type = "map"
}


# # Public Subnets
# # #######################################################
resource "aws_subnet" "public1" {
    vpc_id     = "${aws_vpc.main.id}"
    cidr_block = "${var.public1_cidr}"
    availability_zone = "${var.region}a"
    map_public_ip_on_launch = true
    tags = "${var.tags}"
}
resource "aws_subnet" "public2" {
    vpc_id     = "${aws_vpc.main.id}"
    cidr_block = "${var.public2_cidr}"
    availability_zone = "${var.region}b"
    map_public_ip_on_launch = true
    tags = "${var.tags}"
}
resource "aws_subnet" "public3" {
    vpc_id     = "${aws_vpc.main.id}"
    cidr_block = "${var.public3_cidr}"
    availability_zone = "${var.region}c"
    map_public_ip_on_launch = true
    tags = "${var.tags}"
}

# # Elastic IP
# # #######################################################

resource "aws_eip" "nat" {
  vpc      = true
  tags = "${var.tags}"
}

# # Internet Gateway
# # #######################################################

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = "${var.tags}"
}

# # AMI Image
# # #######################################################

data "aws_ami" "image" {
  most_recent = true
  owners      = ["${var.image_owner}"]       
}

# # EC2 Instance
# # #######################################################

resource "aws_instance" "web" {
  ami      = "${data.aws_ami.image.id}"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name      =  "${aws_key_pair.us-east-1-key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow.id}"]
  subnet_id     = "${aws_subnet.public1.id}"
  source_dest_check = false
  availability_zone = "${var.region}${var.az1}"
  user_data       = "${file("userdata.sh")}"
  tags = "${var.tags}"
}

# # EC2 Outputs
# # #######################################################
output "vpc" {
    value = "${aws_vpc.main.id}"
}

output "public_subnet" {
    value = [
       "${aws_subnet.public1.id}    ${aws_subnet.public1.cidr_block}    ${aws_subnet.public1.availability_zone}",
       "${aws_subnet.public2.id}    ${aws_subnet.public2.cidr_block}    ${aws_subnet.public2.availability_zone}",
       "${aws_subnet.public3.id}    ${aws_subnet.public3.cidr_block}    ${aws_subnet.public3.availability_zone}"
    ]
    
}

output "aws_internet_gateway" {
    value = "${aws_internet_gateway.gw.id}"
}

output "region" {
    value = "${var.region}      ${var.region_name}"
}

output "Tags" {
    value = "${var.tags}"
}
output "instance_id" {
  value = "${aws_instance.web.id}"
}

output "elastic_ip" {
    value = "${aws_eip.nat.id}"
}

output "instance_key" {
  value = "${aws_key_pair.us-east-1-key.key_name}"
}

# # Route Table Associations
# # #######################################################

resource "aws_route_table_association" "b1" {
  subnet_id      = "${aws_subnet.public1.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_route_table_association" "b2" {
  subnet_id      = "${aws_subnet.public2.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_route_table_association" "b3" {
  subnet_id      = "${aws_subnet.public3.id}"
  route_table_id = "${aws_route_table.r.id}"
}

# # Route Table Associations
# # #######################################################

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "${var.route_table_cidr}"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = "${var.tags}"
}

# # Route Table Associations
# # #######################################################




