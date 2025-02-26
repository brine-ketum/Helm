# Output the public IP of the vPacketStack Management VM
output "vpacketstack_mgmt_public_ip" {
  value = aws_instance.vpacketstack_mgmt.public_ip
}

# Output the public IP of the vPacketStack Traffic VM
output "vpacketstack_traffic_public_ip" {
  value = aws_instance.vpacketstack_traffic.public_ip
}

# Output the public IP of the vPacketStack Tools VM
output "vpacketstack_tools_public_ip" {
  value = aws_instance.vpacketstack_tools.public_ip
}

# Output the VPC ID
output "vpc_id" {
  value = aws_vpc.main_vpc.id
}
