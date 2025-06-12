# CloudHSM

Нижче одразу весь вміст одного-єдиного файла `main.tf`.
Модуль свідомо лаконічний, але «розумний»:

* бере список приватних підмереж і автоматично розподіляє HSM-и по них;
* захищає кластер від випадкового знищення (`prevent_destroy = true`);
* дозволяє відновити кластер із бекапу;
* дає вихідні змінні, потрібні для подальшої автоматизації (сертифікати, ENI HSM-ів тощо).

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
  description = "Логічна назва кластера (піде в теги)."
  type        = string
  default     = "cloudhsm"
}

variable "subnet_ids" {
  description = "Список приватних підмереж у різних AZ, у яких треба створити HSM."
  type        = list(string)
}

variable "hsm_type" {
  description = "Тип апаратної моделі HSM."
  type        = string
  default     = "hsm1.medium"
}

variable "source_backup_id" {
  description = "Опціонально – ARN/ID бекапу, з якого відновлювати кластер."
  type        = string
  default     = null
}

variable "tags" {
  description = "Додаткові користувацькі теги."
  type        = map(string)
  default     = {}
}

############################
# ─── DATA SOURCES ───────────────────────────────────────────────
############################
data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}

############################
# ─── RESOURCES ──────────────────────────────────────────────────
############################
resource "aws_cloudhsm_v2_cluster" "this" {
  hsm_type                = var.hsm_type
  subnet_ids              = var.subnet_ids
  source_backup_identifier = var.source_backup_id

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  lifecycle {
    prevent_destroy = true          # Безпечний запобіжник
  }
}

resource "aws_cloudhsm_v2_hsm" "this" {
  for_each          = data.aws_subnet.selected

  cluster_id        = aws_cloudhsm_v2_cluster.this.cluster_id
  subnet_id         = each.value.id
  availability_zone = each.value.availability_zone

  # При необхідності можна передати власну статичну IP:
  # ip_address = ...

  depends_on = [aws_cloudhsm_v2_cluster.this]  # Явна залежність
}

############################
# ─── OUTPUTS ────────────────────────────────────────────────────
############################
output "cluster_id" {
  description = "Ідентифікатор кластера CloudHSM."
  value       = aws_cloudhsm_v2_cluster.this.cluster_id
}

output "cluster_certificates" {
  description = "Набір PEM-сертифікатів (CA, кластер, надійні вузли)."
  value       = aws_cloudhsm_v2_cluster.this.cluster_certificates
  sensitive   = true
}

output "hsm_eni_ids" {
  description = "Network Interface ID кожного HSM."
  value       = {
    for k, hsm in aws_cloudhsm_v2_hsm.this :
    k => hsm.eni_id
  }
}

output "hsm_ips" {
  description = "Приватні IP-адреси кожного HSM."
  value       = {
    for k, hsm in aws_cloudhsm_v2_hsm.this :
    k => hsm.eni_ip
  }
}
```

## Як використати модуль

```hcl
module "cloudhsm" {
  source     = "./modules/cloudhsm_onefile"   # шлях до цього main.tf
  name       = "payments-prod-hsm"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id,
  ]
  tags = {
    Environment = "prod"
    Project     = "payments"
  }
}
```

> ⚠️ **Порада:** перед тим як знімати `prevent_destroy`, переконайтесь, що у вас є актуальний backup кластера, і що видалення / відновлення – це саме те, чого ви хочете.
