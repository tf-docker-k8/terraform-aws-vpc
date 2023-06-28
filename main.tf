resource "aws_vpc" "main" {
    cidr_block       = var.vpc_cidr
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = var.vpc_tags
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  #map
  tags = var.igw_tags
}

# [project-name]-public-1a/1b
resource "aws_subnet" "public" {
  #count = length(var.public_subnet_cidr) #count=2
  count = length(var.public_subnet_cidr)
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.public_subnet_tags,
    {
        Name = "${var.project_name}-public-${local.azs_labels[count.index]}"
    }
  )
}

# timing-public
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = merge(
        var.public_route_table_tags,
        {
            Name = "${var.project_name}-public"
        }
    )
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr) # this will fetch the length of public subnets
  subnet_id      = element(aws_subnet.public[*].id, count.index) # this will iterate and each time it gives single element
  route_table_id = aws_route_table.public.id
}

# elastic IP and NAT
resource "aws_eip" "nat" {
  domain   = "vpc"
  tags = merge(
    var.eip_tags,
    {
        Name = var.project_name
    }
  )
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public[0].id}"
  tags = merge(
    var.nat_gateway_tags,
    {
        Name = var.project_name
    }
  )
}

# [project-name]-private-1a/1b
resource "aws_subnet" "private" {
  #count = length(var.private_subnet_cidr) #count=2
  count = length(var.private_subnet_cidr)
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.private_subnet_tags,
    {
        Name = "${var.project_name}-private-${local.azs_labels[count.index]}"
    }
  )
}

# timing-private
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }

    tags = merge(
        var.private_route_table_tags,
        {
            Name = "${var.project_name}-private"
        }
    )
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr) # this will fetch the length of private subnets
  subnet_id      = element(aws_subnet.private[*].id, count.index) # this will iterate and each time it gives single element
  route_table_id = aws_route_table.private.id
}


# [project-name]-database-1a/1b
resource "aws_subnet" "database" {
  #count = length(var.database_subnet_cidr) #count=2
  count = length(var.database_subnet_cidr)
  vpc_id = aws_vpc.main.id
  cidr_block = var.database_subnet_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.database_subnet_tags,
    {
        Name = "${var.project_name}-database-${local.azs_labels[count.index]}"
    }
  )
}

# timing-private
resource "aws_route_table" "database" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }

    tags = merge(
        var.database_route_table_tags,
        {
            Name = "${var.project_name}-database"
        }
    )
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidr) # this will fetch the length of private subnets
  subnet_id      = element(aws_subnet.database[*].id, count.index) # this will iterate and each time it gives single element
  route_table_id = aws_route_table.database.id
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name = var.project_name
  subnet_ids = aws_subnet.database[*].id
  tags = var.db_subnet_group_tags
}