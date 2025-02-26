# Replace with your values
aws_access_key_id="YOUR_KEY"
aws_secret_access_key="YOUR_KEY"
aws_session_token="YOUR_KEY"

my_aws_region = "eu-west-3"
#private_key_path = "C:\\Users\\amadorni.KEYSIGHT\\.ssh\\gustavo_aws_eu_paris_west3.pem"
private_key_path = "C:\\Users\\amadorni\\.ssh\\gustavo_aws_eu_paris_west3.pem"

key_name = "gustavo_aws_eu_paris_west3"

environment_tag = "gamadornieto-Cloudlens-6.9.1"
billing_code_tag = "NOCODE"
tag_instance_type = "src1"
owner_tag = "gustavo.amador-nieto@keysight.com"
iam_role ="ec2_metadata_access"

# Whitelisted VPC Id

#Demo_Terraform
CL_project_key = "c5ba65906fc3437bb902c5f310c0e2bb"
#CL_project_key = "f3a42bf5b429418796cb69b7566e0f77"
#CLMS_IP = " 52.47.172.79"
CLMS_IP = "13.38.183.239"
vpc_id = "vpc-055e5470322f0b140"
subnet_id= "subnet-0489ba44903fe8eef"

num_win_src = 1
# 2
num_web_srv = 1
num_db      = 0
# 1
num_tcpdump = 1
num_nosensor= 0

