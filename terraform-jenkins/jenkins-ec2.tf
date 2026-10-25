# Find the latest Ubuntu Server 24.04 AMI in Mumbai
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
  key_name               = "JenkinsKey"

  # Install Jenkins, Docker, and Trivy when the server starts
  user_data = <<-EOF
    #!/bin/bash
    set -eux

    # Install Java, Git, Docker, and required tools
    apt-get update
    apt-get install -y fontconfig openjdk-21-jre git docker.io curl wget gnupg

    # Install Trivy security scanner
    install -m 0755 -d /usr/share/keyrings

    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
      | gpg --dearmor -o /usr/share/keyrings/trivy.gpg

    chmod 644 /usr/share/keyrings/trivy.gpg

    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
      > /etc/apt/sources.list.d/trivy.list

    apt-get update
    apt-get install -y trivy

    # Install Jenkins
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
      -o /etc/apt/keyrings/jenkins-keyring.asc

    chmod 644 /etc/apt/keyrings/jenkins-keyring.asc

    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
      > /etc/apt/sources.list.d/jenkins.list

    apt-get update
    apt-get install -y jenkins

    # Start Jenkins and Docker automatically
    systemctl enable --now jenkins
    systemctl enable --now docker

    # Allow Jenkins to use Docker
    usermod -aG docker jenkins

    # Check that Trivy is installed
    trivy --version
  EOF

  # Create a 20 GB root disk
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  # Add project information to the instance
  tags = {
    Name    = "self-healing-jenkins"
    Project = "cloud-native-self-healing-platform"
  }
}

# Show the public IP address of Jenkins
output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

# Show the Jenkins web URL
output "jenkins_url" {
  description = "Jenkins web interface"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}
