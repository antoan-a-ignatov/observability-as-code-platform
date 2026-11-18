# No inbound rules. GitHub's webhook rule is added later.
resource "aws_security_group" "ci" {
  name        = "oacp-ci"
  description = "CI machine"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "oacp-ci"
  }
}

# HTTPS for Session Manager, GitHub and downloads.
resource "aws_vpc_security_group_egress_rule" "ci_https" {
  security_group_id = aws_security_group.ci.id
  description       = "HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# HTTP for Ubuntu's apt mirrors; packages are verified by signature.
resource "aws_vpc_security_group_egress_rule" "ci_http" {
  security_group_id = aws_security_group.ci.id
  description       = "HTTP"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# Public address comes from the Elastic IP; the subnet does not assign one.
resource "aws_instance" "ci" {
  ami                    = var.ci_ami_id
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.public["a"].id
  vpc_security_group_ids = [aws_security_group.ci.id]
  iam_instance_profile   = aws_iam_instance_profile.ci.name

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "oacp-ci-root"
    }
  }

  tags = {
    Name = "oacp-ci"
  }
}

resource "aws_ebs_volume" "ci_data" {
  availability_zone = aws_subnet.public["a"].availability_zone
  size              = 30
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "oacp-ci-data"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "ci_data" {
  device_name                    = "/dev/sdf"
  volume_id                      = aws_ebs_volume.ci_data.id
  instance_id                    = aws_instance.ci.id
  stop_instance_before_detaching = true
}

resource "aws_eip" "ci" {
  domain = "vpc"

  tags = {
    Name = "oacp-ci"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip_association" "ci" {
  instance_id   = aws_instance.ci.id
  allocation_id = aws_eip.ci.id
}
