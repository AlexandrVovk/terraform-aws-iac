data "aws_ssm_parameter" "ami-master" {
  provider = aws.region-master
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_ssm_parameter" "ami-worker" {
  provider = aws.region-worker
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_key_pair" "master-key" {
  provider   = aws.region-master
  key_name   = "mykey"
  public_key = var.mykey
}

resource "aws_key_pair" "worker-key" {
  provider   = aws.region-worker
  key_name   = "mykey"
  public_key = var.mykey
}

resource "aws_instance" "jenkins-master" {
  provider                    = aws.region-master
  ami                         = data.aws_ssm_parameter.ami-master.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg808022.id]
  subnet_id                   = aws_subnet.subnet_1.id

  tags = {
    Name = "jenkins_master"
  }

  depends_on = [aws_main_route_table_association.master-associate]
}

resource "aws_instance" "jenkins-worker" {
  provider                    = aws.region-worker
  count                       = var.workers-count
  ami                         = data.aws_ssm_parameter.ami-worker.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.worker-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg22.id]
  subnet_id                   = aws_subnet.subnet_1_worker.id

  tags = {
    Name = join("_", ["jenkins_worker", count.index + 1])
  }
  depends_on = [aws_main_route_table_association.worker-associate, aws_instance.jenkins-master]
}
