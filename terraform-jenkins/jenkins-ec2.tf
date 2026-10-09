
# Find the latest Ubuntu Server 24.04 LTS AMI in Mumbai
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create the Jenkins EC2 instance
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  # Replace with the name of an existing EC2 key pair in ap-south-1
  key_name = "JenkinsKey"

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    apt-get update
    apt-get install -y fontconfig openjdk-21-jre git docker.io curl

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
      -o /etc/apt/keyrings/jenkins-keyring.asc
    chmod 0644 /etc/apt/keyrings/jenkins-keyring.asc

    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
      > /etc/apt/sources.list.d/jenkins.list

    apt-get update
    apt-get install -y jenkins
    systemctl enable --now jenkins
    systemctl enable --now docker
    usermod -aG docker jenkins
  EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "self-healing-jenkins"
    Project = "cloud-native-self-healing-platform"
  }
}

output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins web interface"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}
