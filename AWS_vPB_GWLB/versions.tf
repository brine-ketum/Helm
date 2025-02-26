terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # Specify version as needed
    }
  }

  required_version = ">= 1.0"
}

# Store AWS credentials before deployment. These can be sourced from environment variables or IAM roles.
# You may want to set your AWS credentials environment variables as follows:
# export AWS_ACCESS_KEY_ID="your-access-key-id"
# export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
# export AWS_DEFAULT_REGION="us-east-1"

# Store EC2 Key Pair for SSH access to instances before deployment
# export TF_VAR_vm
