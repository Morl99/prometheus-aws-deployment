data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

module "ssh_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/ssh"
  version = "~> 3.0"

  vpc_id = aws_vpc.main.id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  name = "ssh"
}

module "node_exporter_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "node-exporter"
  description = "allow inbound access for 9100"
  vpc_id      = aws_vpc.main.id

  ingress_with_cidr_blocks  = [
    {
      from_port   = 9100
      to_port     = 9100
      protocol    = "tcp"
      description = "Prometheus Scraping port"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_instance" "my-test-instance" {
  ami             = data.aws_ami.amazon-linux-2.id
  instance_type   = "t2.micro"
  subnet_id = aws_subnet.public[0].id
  key_name = "carstenhoffmann"
  associate_public_ip_address = true
  vpc_security_group_ids = [module.node_exporter_sg.this_security_group_id, module.ssh_security_group.this_security_group_id]
  user_data = file("ec2/install_node_exporter.sh")
}