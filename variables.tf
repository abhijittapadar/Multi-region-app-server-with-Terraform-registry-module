variable "aws_region_us" {
  description = "The AWS region where resources will be created."
  type        = string
  default = "us-east-1"
}
variable "aws_region_ap" {
  description = "The AWS region where resources will be created."
  type        = string
  default = "ap-south-1"
}
variable "aws_region_eu" {
  description = "The AWS region where resources will be created."
  type        = string
  default = "eu-west-2"
}
variable "instance_type" {
  description = "EC2 instance type for the app servers"
  type        = string
  default     = "t2.micro" # Choose an appropriate instance type
}
variable "ami_owners" {
  description = "Owner of the AMIs (e.g., amazon, self, etc.)"
  type        = list(string)
  default     = ["amazon"]
}
# User data script to install a simple web server (e.g., Apache)
variable "user_data_script" {
  description = "User data script to install a web server"
  type        = string
  default     = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html
              EOF
}
