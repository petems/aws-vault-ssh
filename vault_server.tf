# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A SINGLE EC2 INSTANCE
# This template uses runs a simple "Hello, World" web server on a single EC2 Instance
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = "eu-west-2"
}

resource "tls_private_key" "gen_ssh_key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "aws_vault_ssh_demo_keypair" {
  key_name   = "aws-vault-ssh-demo"
  public_key = "${tls_private_key.gen_ssh_key.public_key_openssh}"
}

resource "local_file" "aws_ssh_key_pem" {
  depends_on = ["tls_private_key.gen_ssh_key"]
  content    = "${tls_private_key.gen_ssh_key.private_key_pem}"
  filename   = "./keys/aws-vault-ssh-keypair.pem"
}

data "aws_ami" "xenial_ami" {
  most_recent = true

  filter {
    name = "owner-id"

    values = [
      "099720109477", # Canonical
    ]
  }

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04*",
    ]
  }
}

resource "aws_security_group" "allow_ssh" {
  name = "allow-ssh-from-world"

  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "vault_server" {

  ami = "${data.aws_ami.xenial_ami.image_id}"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]

  key_name = "${aws_key_pair.aws_vault_ssh_demo_keypair.key_name}"

  user_data = "${base64encode(file("./scripts/install_vault.sh"))}"

  tags {
    Name = "vault_server"
  }
}

output "vault_server_ip" {
  value = "${aws_instance.vault_server.public_ip}"
}

output "vault_server_userdata" {
  value = "${aws_instance.vault_server.user_data}"
}
