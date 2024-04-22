resource "aws_security_group" "ssh" {
  name   = "ssh"
  # In a real environment this wouldn't be
  # hard-coded but it is here for simplicity
  vpc_id = "vpc-0096bb341b29221b0"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ingress" {
  security_group_id = aws_security_group.ssh.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ssh_egress" {
  security_group_id = aws_security_group.ssh.id
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}
