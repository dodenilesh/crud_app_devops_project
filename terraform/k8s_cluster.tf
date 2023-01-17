resource "aws_security_group" "TerraformSG" {
  name   = "TerraformSG"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = "${var.environment_tag}"
    Name        = "TerraformSG"
  }

}

data "template_file" "userdata_k8s" {
  template = file("scripts/copying_keys.sh")

}

data "template_file" "ansible_userdata" {
  template = file("scripts/ansible_userdata.sh")

}


resource "aws_instance" "ansible_controller" {
  ami           = "ami-061dbd1209944525c"
  instance_type = "t2.micro"

  availability_zone      = element(var.az, 0)
  subnet_id              = aws_subnet.public_subnet1.id
  vpc_security_group_ids = [aws_security_group.TerraformSG.id]
  key_name               = aws_key_pair.jenkins_server.key_name
  user_data              = "${data.template_file.ansible_userdata.rendered}"
  tags = {
    Environment = var.environment_tag
    Name        = var.os_names[0]

  }
}

resource "aws_instance" "k8s_master" {
  ami           = "ami-061dbd1209944525c"
  instance_type = "t3.medium"

  availability_zone      = element(var.az, 0)
  subnet_id              = aws_subnet.public_subnet1.id
  vpc_security_group_ids = [aws_security_group.TerraformSG.id]
  key_name               = aws_key_pair.jenkins_server.key_name
  user_data              = "${data.template_file.userdata_k8s.rendered}"
  tags = {
    Environment = var.environment_tag
    Name        = var.os_names[1]

  }
}

resource "aws_instance" "k8s_slave1" {
  ami           = "ami-061dbd1209944525c"
  instance_type = "t2.micro"

  availability_zone      = element(var.az, 0)
  subnet_id              = aws_subnet.public_subnet1.id
  vpc_security_group_ids = [aws_security_group.TerraformSG.id]
  key_name               = aws_key_pair.jenkins_server.key_name
  user_data              = "${data.template_file.userdata_k8s.rendered}"
  tags = {
    Environment = var.environment_tag
    Name        = var.os_names[2]

  }
}

resource "aws_instance" "k8s_slave2" {
  ami           = "ami-061dbd1209944525c"
  instance_type = "t2.micro"

  availability_zone      = element(var.az, 0)
  subnet_id              = aws_subnet.public_subnet1.id
  vpc_security_group_ids = [aws_security_group.TerraformSG.id]
  key_name               = aws_key_pair.jenkins_server.key_name
  user_data              = "${data.template_file.userdata_k8s.rendered}"
  tags = {
    Environment = var.environment_tag
    Name        = var.os_names[3]

  }
}


output "k8s_master_public_ip" {
  value = "${aws_instance.k8s_master.public_ip}"
}

output "k8s_master_private_ip" {
  value = "${aws_instance.k8s_master.private_ip}"
}

output "k8s_slave1_public_ip" {
  value = "${aws_instance.k8s_slave1.public_ip}"
}

output "k8s_slave1_private_ip" {
  value = "${aws_instance.k8s_slave1.private_ip}"
}

output "k8s_slave2_public_ip" {
  value = "${aws_instance.k8s_slave2.public_ip}"
}

output "k8s_slave2_private_ip" {
  value = "${aws_instance.k8s_slave2.private_ip}"
}

output "ansible_controller_public_ip" {
  value = "${aws_instance.ansible_controller.public_ip}"
}

output "ansible_controller_private_ip" {
  value = "${aws_instance.ansible_controller.private_ip}"
}

# resource "null_resource" "run_playbook" {
# 	provisioner "local-exec" {
# 	    command = "sudo  ansible-playbook   /root/Ansible_ws/mainplaybook.yml"
# 	}
# }