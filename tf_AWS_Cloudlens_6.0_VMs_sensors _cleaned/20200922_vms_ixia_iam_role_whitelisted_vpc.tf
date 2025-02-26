##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "aws_session_token" {
  default = ""
}

variable "vpc_id" {}
variable "subnet_id" {}

variable "private_key_path" {}
variable "key_name" {}
variable "iam_role" {}

variable "CL_project_key" {}
variable "CLMS_IP" {}

variable "billing_code_tag" {}
variable "environment_tag" {}
variable "owner_tag" {}
variable "options_tag" { default="WEEK" }
variable "tag_instance_type" {
  default = "db"
}

variable "num_web_srv" {
  default = 1
}
variable "num_db" {
  default = 1
}
variable "num_win_src" {
  default = 0
}
variable "num_tcpdump" {
  default = 1
}
variable "num_nosensor" {
  default = 0
}

variable "region_az" {
  type = map
  default = {
    us-east-1 = "us-east-1a"
    us-west-1 = "us-west-1a"
    eu-west-3 = "eu-west-3c"
  }
}


variable "my_aws_region" {
  default = "us-east-1"
}

variable "riverbed_ip" {
  default = "172.31.78.57"
}




##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key =  var.aws_access_key_id
  secret_key =  var.aws_secret_access_key
  token      =  var.aws_session_token
  region     =  var.my_aws_region
}


##################################################################################
# Find Data
##################################################################################

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "public_subnet1" { 
  id = var.subnet_id
}


##################################################################################
# Declare User Data templates
##################################################################################

data "template_file" "userdata_ubuntu_cl_sensor" {
  template = "${file("templates/ubuntu_cl_sensor.sh")}"
  vars = {
    cl_project_key   = "${var.CL_project_key}"
    clms_ip          = "${var.CLMS_IP}"
    custom_tags      = "sensor_owner=var.owner_tag sensor_type=web_srv sensor_BillingCode=${var.billing_code_tag}"
  }
}


data "template_file" "userdata_add_ntop" {
  template = "${file("templates/add_ntop.sh")}"
}

data "template_file" "userdata_ubuntu_add_tcpdump" {
  template = "${file("templates/ubuntu_add_tcpdump.sh")}"
}

data "template_file" "userdata_generate_http_dns" {
template = "${file("templates/generate_http_dns.sh")}"
}

data "template_file" "userdata_ami_cl_websrv" {
template = "${file("templates/ami_cl_sensor.sh")}"
  vars = {
        cl_project_key   = "${var.CL_project_key}"
        clms_ip          = "${var.CLMS_IP}"
        custom_tags      = "sensor_owner=var.owner_tag sensor_type=web_srv sensor_BillingCode=${var.billing_code_tag}"
  }
}

data "template_file" "userdata_ami_cl_db" {
template = "${file("templates/ami_cl_sensor.sh")}"
  vars = {
        cl_project_key   = "${var.CL_project_key}"
        clms_ip          = "${var.CLMS_IP}"
        custom_tags      = "sensor_owner=${var.owner_tag} sensor_type=db sensor_BillingCode=${var.billing_code_tag}"
  }
}

data "template_file" "userdata_ami_cl_tcpdump" {
template = "${file("templates/ami_cl_sensor.sh")}"
  vars = {
        cl_project_key   = "${var.CL_project_key}"
        clms_ip          = "${var.CLMS_IP}"
        custom_tags      = "sensor_owner=${var.owner_tag} sensor_type=tcpdump sensor_BillingCode=${var.billing_code_tag}"
  }
}

data "template_file" "userdata_ami_update" {
template = "${file("templates/ami_update.sh")}"
}

data "template_file" "userdata_ubuntu_add_gre" {
  template = "${file("templates/add_gre.sh")}"
  vars = {
    riverbed_ip   = "${var.riverbed_ip}"
  }
}

##################################################################################
# Mappings
##################################################################################

variable "region_Linux2AMI" {
  type = map(string)
default = {
    us-east-1      = "ami-c58c1dd3"
    us-west-2      = "ami-04590e7389a6e577c"
    eu-west-3      = "ami-00dd995cb6f0a5219"
  }
}
variable "region_ubuntu1604AMI" {
  type = map(string)
default = {
    us-east-1      = "ami-08bc77a2c7eb2b1da"
    us-west-2      = "ami-02d0ea44ae3fe9561"
    eu-west-3      = "ami-0dcc868923fc0d18d"    
  }
}


variable "region_Windows2016" {
  type = map(string)
default = {
    us-east-1      = "ami-032e26fff3bb717f3"
    us-west-2      = "ami-032e26fff3bb717f3"
    eu-west-3      = "ami-0180fdd511226931d"
  }
}

##################################################################################
# RESOURCES VMs
##################################################################################

resource "aws_instance" "web_srv" {
  count = var.num_web_srv

  subnet_id = data.aws_subnet.public_subnet1.id
  associate_public_ip_address = true

  #count = "${var.subnet_count}"
  #cidr_block = "${cidrsubnet(var.network_address_space, 8, count.index + 1)}"

  ami             = "${var.region_Linux2AMI["${var.my_aws_region}"]}"
  instance_type = "t2.micro"
  key_name        = var.key_name

  #iam_instance_profile = "${var.iam_role}"
  iam_instance_profile = "${aws_iam_instance_profile.TF_gustavo_ec2ReadOnly3.name}"
  vpc_security_group_ids = ["${aws_security_group.gustavo-cl-default-sg.id}"]

  availability_zone= var.region_az[var.my_aws_region]


  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
    host = self.public_ip
  }

  user_data = "${data.template_file.userdata_ami_cl_websrv.rendered} ${data.template_file.userdata_generate_http_dns.rendered} "

  tags = {
    Name = "${var.environment_tag}-web-srv${count.index}"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
    Type = "web_srv"
    Options = var.options_tag
    Owner = var.owner_tag
  }
}


resource "aws_instance" "db" {
  count = var.num_db

  subnet_id = data.aws_subnet.public_subnet1.id
  associate_public_ip_address = true

  ami           = "${var.region_Linux2AMI["${var.my_aws_region}"]}"
  instance_type = "t2.micro"
  key_name        = var.key_name

  #iam_instance_profile = "${var.iam_role}"
  iam_instance_profile = "${aws_iam_instance_profile.TF_gustavo_ec2ReadOnly3.name}"

  vpc_security_group_ids = ["${aws_security_group.gustavo-cl-default-sg.id}"]
  availability_zone= var.region_az[var.my_aws_region]

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
    host = self.public_ip
  }

  user_data = "${data.template_file.userdata_ami_cl_db.rendered}"

  tags = {
    Name = "${var.environment_tag}-db${count.index}"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
    Type = "db"
    Options = var.options_tag
    Owner = var.owner_tag
  }
}



resource "aws_instance" "tcpdump" {

  count = var.num_tcpdump

  subnet_id = data.aws_subnet.public_subnet1.id
  associate_public_ip_address = true

  ami             = "${var.region_Linux2AMI["${var.my_aws_region}"]}"
  instance_type = "t2.medium"
  key_name        = "${var.key_name}"

  #iam_instance_profile = "${var.iam_role}"
  iam_instance_profile = "${aws_iam_instance_profile.TF_gustavo_ec2ReadOnly3.name}"

  vpc_security_group_ids = ["${aws_security_group.gustavo-cl-default-sg.id}"]
  availability_zone= var.region_az[var.my_aws_region]

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
    host = self.public_ip
  }

  user_data = "${data.template_file.userdata_ami_cl_tcpdump.rendered}"
  #user_data = "${data.template_file.userdata_ami_cl_tcpdump.rendered} ${data.template_file.userdata_ubuntu_add_tcpdump.rendered} "


  tags = {
    Name = "${var.environment_tag}-tcpdump1"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
    Type = "tcpdump"
    Options = var.options_tag
    Owner = var.owner_tag
  }
}

resource "aws_instance" "nosensor" {

  count = var.num_nosensor

  subnet_id = data.aws_subnet.public_subnet1.id
  associate_public_ip_address = true

  ami             = "${var.region_Linux2AMI["${var.my_aws_region}"]}"
  instance_type = "t2.micro"
  key_name        = "${var.key_name}"

  #iam_instance_profile = "${var.iam_role}"
  iam_instance_profile = "${aws_iam_instance_profile.TF_gustavo_ec2ReadOnly3.name}"

  vpc_security_group_ids = ["${aws_security_group.gustavo-cl-default-sg.id}"]
  availability_zone= var.region_az[var.my_aws_region]

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
    host = self.public_ip
  }

  user_data = "${data.template_file.userdata_ami_update.rendered}"
  

  tags = {
    Name = "${var.environment_tag}-nosensor"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
    Type = "nosensor"
    Options = var.options_tag
    Owner = var.owner_tag
  }
}

#
# IAM EC2 read only.
# Just using predefined iam_instance_profile

resource "aws_iam_role" "TF_gustavo_ec2ReadOnly3" {
  name = "TF_gustavo_ec2ReadOnly3"
  assume_role_policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": "sts:AssumeRole",
              "Principal" : {
                "Service" : "ec2.amazonaws.com"
              },
              "Effect": "Allow"
          }
    ]
  }
EOF
}


resource "aws_iam_policy_attachment" "test-attach3" {
  name       = "test-attachment"
  roles      = ["${aws_iam_role.TF_gustavo_ec2ReadOnly3.name}"]
  #policy_arn = "${aws_iam_policy.policy.arn}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "TF_gustavo_ec2ReadOnly3" {
  name = "TFP_gustavo_ec2ReadOnly3"
  role = "${aws_iam_role.TF_gustavo_ec2ReadOnly3.name}"
}


##
# SECURITY GROUPS #
##

# Learn my public IP address
data "http" "myip" {
   url = "http://ipv4.icanhazip.com"
}

# default security group
resource "aws_security_group" "gustavo-cl-default-sg" {
  name        = "${var.environment_tag}-default-sg"
  vpc_id      = data.aws_vpc.selected.id

  # SSH access from my PC
  ingress {
    description = "SSH from my PC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }
  ingress {
    description = "SSH from my CloudlensManager"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.CLMS_IP}/32"]
  }
  # Allow all egress traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.environment_tag}-gustavo_ntop-sg"
    BillingCode        = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
    Options = var.options_tag
    Owner = var.owner_tag
  }
}

# windows VM security group
resource "aws_security_group" "gustavo-cl-windows-sg" {
  name        = "${var.environment_tag}-cl-windows-sg"
  vpc_id      = data.aws_vpc.selected.id

  # SSH access from my RDP
  ingress {
    description = "SSH from my PC"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }
  ingress {
    description = "SSH from my CloudlensManager"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.CLMS_IP}/32"]
  }
  # Allow all egress traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.environment_tag}-gustavo_windows-sg"
    BillingCode        = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
    Options = var.options_tag
    Owner = var.owner_tag
  }
}



##################################################################################
# OUTPUT
##################################################################################

output "AWS_details" {
  value = [ " AWS region ${var.my_aws_region}" ]
}

output "db" {
    value = [for name in aws_instance.db[*].public_ip:  " ssh -i ${var.private_key_path} ec2-user@${name}" ]
}

output "web_srv" {
    value = [for name in aws_instance.web_srv[*].public_ip:  " ssh -i ${var.private_key_path} ec2-user@${name}" ]
}

output "tcpdump" {
    value = [for name in aws_instance.tcpdump[*].public_ip:  " ssh -i ${var.private_key_path} ec2-user@${name}" ]
}


output "nosensor" {
    value = [for name in aws_instance.nosensor[*].public_ip:  " ssh -i ${var.private_key_path} ec2-user@${name}" ]
}


output "Z_This_zone" {
    value = [ "AWS zone ${var.my_aws_region}" ]
}

output "Z_Selected_VPC" {
  value = data.aws_vpc.selected.id
          
}
