terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#------------------------------------------------------------------------------
# Provider Configuration for us-east-1 (N. Virginia)
#------------------------------------------------------------------------------
provider "aws" {
  alias  = "aws_region_us"
  region = var.aws_region_us
}

#------------------------------------------------------------------------------
# Provider Configuration for eu-west-2 (London)
#------------------------------------------------------------------------------
provider "aws" {
  alias  = "aws_region_ap"
  region = var.aws_region_ap
}

#------------------------------------------------------------------------------
# Provider Configuration for ap-south-1 (Mumbai)
#------------------------------------------------------------------------------

provider "aws" {
  alias  = "aws_region_eu"
  region = "eu-west-2"
}

#------------------------------------------------------------------------------
# Common Variables
#------------------------------------------------------------------------------



# You might need to find the latest Amazon Linux 2 AMI ID in each region
# or use a data source to look it up dynamically.
# For simplicity, we'll use older but common AMI IDs.
# It's best practice to use a data source `aws_ami` for this.

data "aws_ami" "amazon_linux_us_east_1" {
  provider    = aws.aws_region_us
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = var.ami_owners
}

data "aws_ami" "amazon_linux_eu_west_2" {
  provider    = aws.aws_region_eu
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = var.ami_owners
}

data "aws_ami" "amazon_linux_ap_south_1" {
  provider    = aws.aws_region_ap
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = var.ami_owners
}


#------------------------------------------------------------------------------
# Resources for us-east-1 (N. Virginia)
#------------------------------------------------------------------------------
module "vpc_us_east_1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2" # Use the latest appropriate version

  name            = "app-vpc-us-east-1"
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"] # Adjust as needed
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"] # Adjust as needed
  enable_nat_gateway = false # Set to true if you need outbound internet from private subnets
  enable_dns_hostnames = true
  enable_dns_support   = true

  providers = {
    aws = aws.aws_region_us
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Region      = "us-east-1"
  }
}

module "sg_http_us_east_1" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0" # Use the latest appropriate version

  name        = "app-server-sg-http-us-east-1"
  description = "Allow HTTP inbound traffic"
  vpc_id      = module.vpc_us_east_1.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  egress_with_cidr_blocks = [ # Allow all outbound traffic
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  providers = {
    aws = aws.aws_region_us
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Region      = "us-east-1"
  }
}

module "app_server_us_east_1" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.0" # Use the latest appropriate version

  name                   = "app-server-us-east-1"
  ami                    = data.aws_ami.amazon_linux_us_east_1.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc_us_east_1.public_subnets[0] # Launch in the first public subnet
  vpc_security_group_ids = [module.sg_http_us_east_1.security_group_id]
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html
              EOF
  associate_public_ip_address = true

  providers = {
    aws = aws.aws_region_us
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "AppServer-USE1"
  }
}

#------------------------------------------------------------------------------
# Resources for eu-west-2 (London)
#------------------------------------------------------------------------------

module "vpc_eu_west_2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name            = "app-vpc-eu-west-2"
  cidr            = "10.1.0.0/16"
  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"] # Adjust as needed
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"] # Adjust as needed
  enable_nat_gateway = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  providers = {
    aws = aws.aws_region_eu
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Region      = "eu-west-2"
  }
}

module "sg_http_eu_west_2" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "app-server-sg-http-eu-west-2"
  description = "Allow HTTP inbound traffic"
  vpc_id      = module.vpc_eu_west_2.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  providers = {
    aws = aws.aws_region_eu
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Region      = "eu-west-2"
  }
}

module "app_server_eu_west_2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.0"

  name                   = "app-server-eu-west-2"
  ami                    = data.aws_ami.amazon_linux_eu_west_2.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc_eu_west_2.public_subnets[0]
  vpc_security_group_ids = [module.sg_http_eu_west_2.security_group_id]
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html
              EOF
  associate_public_ip_address = true

  providers = {
    aws = aws.aws_region_eu
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "AppServer-EUW2"
  }
}

#------------------------------------------------------------------------------
# Resources for ap-south-1 (Mumbai)
#------------------------------------------------------------------------------
module "vpc_ap_south_1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name            = "app-vpc-ap-southeast-1"
  cidr            = "10.2.0.0/16"
  azs             = ["ap-south-1a", "ap-south-1b", "ap-south-1c"] # Adjust as needed
  public_subnets  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"] # Adjust as needed
  enable_nat_gateway = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  providers = {
    aws = aws.aws_region_ap
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Region      = "ap-southeast-1"
  }
}

module "sg_http_ap_south_1" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "app-server-sg-http-ap-southeast-1"
  description = "Allow HTTP inbound traffic"
  vpc_id      = module.vpc_ap_south_1.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  providers = {
    aws = aws.aws_region_ap
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Region      = "ap-south-1"
  }
}

module "app_server_ap_south_1" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.0"

  name                   = "app-server-ap-southeast-1"
  ami                    = data.aws_ami.amazon_linux_ap_south_1.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc_ap_south_1.public_subnets[0]
  vpc_security_group_ids = [module.sg_http_ap_south_1.security_group_id]
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html
              EOF
  associate_public_ip_address = true

  providers = {
    aws = aws.aws_region_ap
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "AppServer-APSE1"
  }
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------
output "app_server_us_east_1_public_ip" {
  description = "Public IP address of the app server in us-east-1"
  value       = module.app_server_us_east_1.public_ip
}

output "app_server_us_east_1_http_url" {
  description = "URL to access the app server in us-east-1"
  value       = "http://${module.app_server_us_east_1.public_ip}"
}

output "app_server_eu_west_2_public_ip" {
  description = "Public IP address of the app server in eu-west-2"
  value       = module.app_server_eu_west_2.public_ip
}

output "app_server_eu_west_2_http_url" {
  description = "URL to access the app server in eu-west-2"
  value       = "http://${module.app_server_eu_west_2.public_ip}"
}

output "app_server_ap_south_1_public_ip" {
  description = "Public IP address of the app server in ap-southeast-1"
  value       = module.app_server_ap_south_1.public_ip
}

output "app_server_ap_south_1_http_url" {
  description = "URL to access the app server in ap-southeast-1"
  value       = "http://${module.app_server_ap_south_1.public_ip}"
}
