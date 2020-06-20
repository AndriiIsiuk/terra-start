variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/terraform.pub
DESCRIPTION
  default = "/home/andrii/.ssh/id_rsa.pub"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "local_nginx_conf" {
  description = "Location of the nginx.conf file on local machine"
  default     = "files/nginx.conf"
}

variable "local_index_html" {
  description = "Location of the index.html file on local machine"
  default     = "files/index.html"
}

variable "local_creds_file" {
  description = "AWS credentials file"
  default     = "~/.aws/credentials"
}