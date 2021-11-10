resource "aws_vpc" "master-vpc" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags = {
    Name = "master-vpc"
  }
}

resource "aws_vpc" "worker-vpc" {
  provider             = aws.region-worker
  cidr_block           = "192.168.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags = {
    Name = "worker-vpc"
  }
}

resource "aws_internet_gateway" "igw-master" {
  provider = aws.region-master
  vpc_id   = aws_vpc.master-vpc.id
}

resource "aws_internet_gateway" "igw-worker" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.worker-vpc.id
}

data "aws_availability_zones" "azs-master" {
  provider = aws.region-master
  state    = "available"
}

resource "aws_subnet" "subnet_1" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs-master.names, 0)
  vpc_id            = aws_vpc.master-vpc.id
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "subnet_2" {
  provider          = aws.region-master
  vpc_id            = aws_vpc.master-vpc.id
  availability_zone = element(data.aws_availability_zones.azs-master.names, 1)
  cidr_block        = "10.0.2.0/24"
}

resource "aws_subnet" "subnet_1_worker" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.worker-vpc.id
  cidr_block = "192.168.1.0/24"
}


resource "aws_vpc_peering_connection" "useast1-uswest2" {
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.worker-vpc.id
  vpc_id      = aws_vpc.master-vpc.id
  peer_region = var.region-worker

}

resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  auto_accept               = true
}

resource "aws_route_table" "internet_route" {
  provider = aws.region-master
  vpc_id   = aws_vpc.master-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-master.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Route-to-worker"
  }
}

resource "aws_route_table" "internet_route_worker" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.worker-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-worker.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Route-to-master"
  }
}

resource "aws_main_route_table_association" "master-associate" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.master-vpc.id
  route_table_id = aws_route_table.internet_route.id
}

resource "aws_main_route_table_association" "worker-associate" {
  provider       = aws.region-worker
  vpc_id         = aws_vpc.worker-vpc.id
  route_table_id = aws_route_table.internet_route_worker.id
}
