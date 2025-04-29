Вот улучшенный `README.md` в профессиональном markdown-формате, с заголовками, списками, блоками кода и читаемой структурой:

---

```markdown
# Terraform KMS Keys & Organization Policies

## 📁 Структура проекта

```text
.
├── modules/
│   ├── kms_key/                # Модуль создания и управления KMS ключами
│   └── org_policies/           # Модуль применения организационных политик
├── policies/
│   ├── kms/                    # JSON политики для KMS ключей
│   │   ├── restrict-key-use.json
│   │   └── enforce-labels.json
│   └── org/                    # JSON политики для Organization Policies
│       ├── enforce-domain.json
│       └── restrict-services.json
├── dev/
│   ├── main.tf
│   ├── backend.tf
│   └── dev.tfvars
├── prod/
│   ├── main.tf
│   ├── backend.tf
│   └── prod.tfvars
├── test/
│   ├── main.tf
│   ├── backend.tf
│   └── test.tfvars
└── README.md
```

---

## 🔧 Использование модулей

### Модуль: `kms_key`

```hcl
module "kms_key" {
  source         = "../modules/kms_key"
  key_name       = var.kms_key_name
  key_ring       = var.kms_key_ring
  location       = var.kms_location
  policy_path    = var.kms_policy_path   # Пример: "../policies/kms/restrict-key-use.json"
}
```

### Модуль: `org_policies`

```hcl
module "org_policies" {
  source         = "../modules/org_policies"
  policy_files   = var.org_policy_files  # Список путей к JSON-файлам
  target_id      = var.org_target_id     # ID папки или организации
}
```

---

## 🧪 Окружения

Каждое окружение (`dev/`, `prod/`, `test/`) содержит:

- `main.tf` — подключает модули
- `backend.tf` — определяет backend для хранения состояния
- `*.tfvars` — переменные окружения

---

## 🗂 Пример переменных (`dev.tfvars`)

```hcl
kms_key_name     = "dev-key"
kms_key_ring     = "dev-keyring"
kms_location     = "us-central1"
kms_policy_path  = "../policies/kms/restrict-key-use.json"

org_policy_files = [
  "../policies/org/enforce-domain.json",
  "../policies/org/restrict-services.json"
]

org_target_id = "folders/987654321098"
```

---

## ☁️ Пример `backend.tf`

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-state-dev"
    prefix = "kms-org-policies"
  }
}
```

---

## 🚀 Как использовать

```bash
# Инициализация окружения
terraform init -backend-config=backend.tf

# Планирование изменений
terraform plan -var-file=dev.tfvars

# Применение изменений
terraform apply -var-file=dev.tfvars
```

---

## 📌 Рекомендации

- Храните все JSON политики в `policies/`, и ссылку на них передавайте через переменные.
- Разделяйте окружения (`dev`, `prod`, `test`) строго — включая разные `backend` конфигурации.
- Используйте `terraform validate` и `terraform fmt` перед применением.
- Настройте CI/CD для проверки и деплоя изменений в политике.

---

Если нужно — могу сгенерировать шаблоны для `main.tf`, `kms_key` или `org_policies` модулей. Хочешь?
