module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-tf"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-018a7f01c6abc8b7d"] #replace your SG
  subnet_id = "subnet-01fec9beed5426f7a" #replace your Subnet
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins.sh")
  tags = {
    Name = "jenkins-tf"
  }
}

module "jenkins_agent" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-agent"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-018a7f01c6abc8b7d"]
  # convert StringList to list and get first element
  subnet_id = "subnet-01fec9beed5426f7a"
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins-agent.sh")
  tags = {
    Name = "jenkins-agent"
  }
}

resource "aws_key_pair" "tools" {
  key_name   = "tools"
  #you can paste the public key directly like this
  #public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwKNle9zduUFN4UxEqgmrh2cjjhlae3ehO4TTMq5n4z Lenovo@DESKTOP-JS3T24B"
  public_key = file("~/.ssh/tools.pub") #~ means windows home directory. my home directory is "/c/users/lenovo"
}


module "nexus" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "nexus"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-018a7f01c6abc8b7d"]
  # convert StringList to list and get first element
  subnet_id = "subnet-01fec9beed5426f7a"
  ami = data.aws_ami.nexus_ami_info.id
  key_name = aws_key_pair.tools.key_name
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 30
    }
  ]
  tags = {
    Name = "nexus"
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "jenkins"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins.public_ip
      ]
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins_agent.private_ip
      ]
    },
     {
      name    = "nexus"
      type    = "A"
      ttl     = 1
      allow_overwrite = true
      records = [
        module.nexus.private_ip
      ]
    }
  ]
}