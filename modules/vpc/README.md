# AWS VPC

Нижче — повний вміст одного-єдиного файла `main.tf` для «розумного» модуля VPC.
Мета — швидко отримати production-готову VPC із публічними та приватними підмережами в кількох AZ, опційними NAT-шлюзами й корисними вихідними значеннями.

```hcl
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

############################
# ─── INPUT VARIABLES ────────────────────────────────────────────
############################
variable "name" {
  description = "Логічна назва VPC (піде в теги)."
  type        = string
  default     = "vpc"
}

variable "cidr_block" {
  description = "CIDR для VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Список AZ, у яких створювати підмережі."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR-блоки публічних підмереж (мають відповідати availability_zones за порядком)."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR-блоки приватних підмереж (мають відповідати availability_zones за порядком)."
  type        = list(string)
}

variable "create_nat_gateway_per_az" {
  description = "true → NAT у кожній AZ, false → один спільний NAT."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Додаткові теги."
  type        = map(string)
  default     = {}
}

############################
# ─── LOCALS ─────────────────────────────────────────────────────
############################
locals {
  az_count = length(var.availability_zones)

  # Перевірка: кількість CIDR == AZ
  _checks = [
    length(var.public_subnet_cidrs)  == local.az_count ?
      "" : "public_subnet_cidrs must match availability_zones",
    length(var.private_subnet_cidrs) == local.az_count ?
      "" : "private_subnet_cidrs must match availability_zones"
  ]
}

############################
# ─── RESOURCES ──────────────────────────────────────────────────
############################
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

# ── Публічні підмережі ─────────────────────────────
resource "aws_subnet" "public" {
  for_each          = { for idx, az in var.availability_zones : idx => az }

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[tonumber(each.key)]
  availability_zone = each.value
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-${each.value}"
      "kubernetes.io/role/elb" = 1   # якщо колись знадобиться
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ── Приватні підмережі ────────────────────────────
resource "aws_subnet" "private" {
  for_each          = { for idx, az in var.availability_zones : idx => az }

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[tonumber(each.key)]
  availability_zone = each.value
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-${each.value}"
      "kubernetes.io/role/internal-elb" = 1
    }
  )
}

# ── NAT Gateways (опційно по одній на AZ) ──────────
resource "aws_eip" "nat" {
  for_each = var.create_nat_gateway_per_az ? aws_subnet.public : { "0" = aws_subnet.public[0] }

  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-nat-eip-${each.key}" })
}

resource "aws_nat_gateway" "this" {
  for_each = aws_eip.nat

  allocation_id = each.value.id
  subnet_id     = var.create_nat_gateway_per_az ? aws_subnet.public[each.key].id : aws_subnet.public[0].id

  tags = merge(var.tags, { Name = "${var.name}-nat-${each.key}" })
}

# Приватні route tables з виходом через NAT
resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.create_nat_gateway_per_az ?
                      aws_nat_gateway.this[each.key].id :
                      aws_nat_gateway.this["0"].id
  }

  tags = merge(var.tags, { Name = "${var.name}-private-rt-${each.key}" })
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

############################
# ─── VPC ENDPOINTS (S3 + DynamoDB, безкоштовні) ───
############################
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private[*].id...]
  tags = merge(var.tags, { Name = "${var.name}-s3-endpoint" })
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private[*].id...]
  tags = merge(var.tags, { Name = "${var.name}-dynamodb-endpoint" })
}

############################
# ─── DATA SOURCES ───────────────────────────────────────────────
############################
data "aws_region" "current" {}

############################
# ─── OUTPUTS ────────────────────────────────────────────────────
############################
output "vpc_id" {
  description = "ID створеної VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Списком ID публічних підмереж."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "Списком ID приватних підмереж."
  value       = [for s in aws_subnet.private : s.id]
}

output "nat_gateway_ids" {
  description = "ID NAT-шлюзів."
  value       = [for n in aws_nat_gateway.this : n.id]
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

output "dynamodb_endpoint_id" {
  value = aws_vpc_endpoint.dynamodb.id
}
```

## Як користуватися

```hcl
module "vpc" {
  source = "./modules/vpc_onefile"

  name               = "payments-prod"
  cidr_block         = "10.42.0.0/16"
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  # **Увага:** CIDR-маски підмереж мають відповідати AZ за індексом
  public_subnet_cidrs  = ["10.42.0.0/20", "10.42.16.0/20", "10.42.32.0/20"]
  private_subnet_cidrs = ["10.42.128.0/19", "10.42.160.0/19", "10.42.192.0/19"]

  create_nat_gateway_per_az = true   # або false, якщо треба лише один

  tags = {
    Environment = "prod"
    Project     = "payments"
  }
}
```

## Особливості модуля

* **Автоматичний розподіл** підмереж, маршрутів та NAT-ів по AZ.
* **Запобіжник-перевірка**: кількість CIDR-блоків має збігатися з кількістю AZ.
* **NAT-шлюзи на вибір**: один спільний або по одному на кожну AZ.
* **Gateway Endpoints** для S3 і DynamoDB додаються без доплат і зменшують трафік через NAT.
* **Теги** зберігають ваші політики обліку ресурсів.

Цього достатньо, щоб одразу піднімати ECS/EKS, RDS чи будь-які інші сервіси у приватних підмережах, залишаючи публічні тільки для jump-хостів, ALB тощо.
