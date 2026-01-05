data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  default_for_az = true
  vpc_id         = data.aws_vpc.default.id
}

resource "aws_security_group" "monitoring_sg" {
  name   = "monitoring-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "cw_role" {
  name = "CloudWatchAgentRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.cw_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cw_profile" {
  name = "cw-instance-profile"
  role = aws_iam_role.cw_role.name
}

resource "aws_instance" "monitoring_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.cw_profile.name

  tags = {
    Name = "CloudWatch-Monitoring-Server"
  }
}
