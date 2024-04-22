resource "aws_security_group" "ssh" {
  name   = "ssh"
  vpc_id = aws_vpc.main.id
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
