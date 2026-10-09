
resource "aws_security_group" "jenkins_sg" {
  name        = "self-healing-jenkins-sg"
  description = "Security group for Jenkins CI/CD server"

  ingress {
    description = "SSH from your IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["106.193.190.177/32"]
  }

  ingress {
    description = "Jenkins web UI from your IP only"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["106.193.190.177/32"]
  }

  egress {
    description = "Allow outbound connections"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "self-healing-jenkins-sg"
    Project = "cloud-native-self-healing-platform"
  }
}
