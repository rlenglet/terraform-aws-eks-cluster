data "aws_iam_role" "eks-cluster" {
  name = var.cluster_role_name
}

data "aws_iam_role" "eks-node" {
  name = var.worker_node_role_name
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_subnet" "public" {
  for_each = var.availability_zones

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block        = each.value.public_cidr_block

  map_public_ip_on_launch = true

  tags = {
    Name                                    = "${var.cluster_name}-Public-${each.key}"
    "kubernetes.io/cluster/ServiceMeshDemo" = "shared"
    "kubernetes.io/role/elb"                = "1"
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_subnet" "private" {
  for_each = var.availability_zones

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block        = each.value.private_cidr_block

  tags = {
    Name                                    = "${var.cluster_name}-Private-${each.key}"
    "kubernetes.io/cluster/ServiceMeshDemo" = "shared"
    "kubernetes.io/role/internal-elb"       = "1"
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip" "nat-gw" {
  for_each = var.availability_zones

  vpc = true

  tags = {
    Name = "${var.cluster_name}-NATGateway-${each.key}"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  for_each = var.availability_zones

  allocation_id = aws_eip.nat-gw[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${var.cluster_name}-NATGateway-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.cluster_name}-Public"
  }
}

resource "aws_route" "public-default" {
  route_table_id = aws_route_table.public.id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table" "private" {
  for_each = var.availability_zones

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.cluster_name}-Private-${each.key}"
  }
}

resource "aws_route" "private-default" {
  for_each = var.availability_zones

  route_table_id = aws_route_table.private[each.key]

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gw[each.key].id
}

resource "aws_route_table_association" "public" {
  for_each = var.availability_zones

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = var.availability_zones

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_eks_cluster" "cluster" {
  name = var.cluster_name

  role_arn = data.aws_iam_role.eks-cluster.arn

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true

    subnet_ids = [for subnet in aws_subnet.private : subnet.id]
  }
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "Default"

  node_role_arn = data.aws_iam_role.eks-node.arn

  subnet_ids = [for subnet in aws_subnet.private : subnet.id]

  instance_types = var.node_group_instance_types

  scaling_config {
    min_size     = var.node_group_min_size
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
  }
}
