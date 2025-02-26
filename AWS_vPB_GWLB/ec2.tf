# EC2 Instance for vPacketStack Management
resource "aws_instance" "vpacketstack_mgmt" {
  ami             = var.vm_image_id
  instance_type   = var.vm_instance_type
  subnet_id       = aws_subnet.mgmt_subnet.id
  key_name        = var.vm_key_name
  security_groups = [aws_security_group.instance_sg.name]

  tags = {
    Name = "vPacketStackMgmt-${var.env}"
    Env  = var.env
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              EOF
}

# EC2 Instance for Traffic Handling
resource "aws_instance" "vpacketstack_traffic" {
  ami             = var.vm_image_id
  instance_type   = var.vm_instance_type
  subnet_id       = aws_subnet.traffic_subnet.id
  key_name        = var.vm_key_name
  security_groups = [aws_security_group.instance_sg.name]

  tags = {
    Name = "vPacketStackTraffic-${var.env}"
    Env  = var.env
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              EOF
}

# EC2 Instance for Tools Management
resource "aws_instance" "vpacketstack_tools" {
  ami             = var.vm_image_id
  instance_type   = var.vm_instance_type
  subnet_id       = aws_subnet.tools_subnet.id
  key_name        = var.vm_key_name
  security_groups = [aws_security_group.instance_sg.name]

  tags = {
    Name = "vPacketStackTools-${var.env}"
    Env  = var.env
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              EOF
}
