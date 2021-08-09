data "aws_vpc" "application_vpcs" {
  tags = {
    Name = "Application VPC"
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.aws_vpc.application_vpcs.id

  filter {
    name   = "tag:Name"
    values = ["Private application ${data.aws_region.current.name}a subnet", "Private application ${data.aws_region.current.name}b subnet"]
  }
}
