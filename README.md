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

Отлично. Тогда я сейчас полностью допишу:  
- Проверку на обязательные **теги**  
- Проверку, что политика **требует MFA** для операций удаления/отключения ключа  

И всё оформлю в едином, красивом **Markdown документе** с пояснениями.

---

# 🛡 Policy as Code для AWS KMS Keys

## 📁 Где создавать политики

Создайте папку:

```bash
mkdir -p policies/kms
```

Создайте файл:

```bash
touch policies/kms/kms_security.rego
```

---

## 📜 Полный Rego-файл `policies/kms/kms_security.rego`

```rego
package terraform.kms

default allow = false

############
# Базовые проверки
############

# Проверка: ротация ключей включена
rotation_enabled[key] {
  input.resource_changes[_].change.after.enable_key_rotation == true
  key := input.resource_changes[_].address
}

# Проверка: ключ имеет policy
has_policy[key] {
  input.resource_changes[_].change.after.policy != ""
  key := input.resource_changes[_].address
}

# Проверка: запрещён доступ всем кроме списка ролей
deny_all_except_listed[key] {
  some i
  policy := json.unmarshal(input.resource_changes[_].change.after.policy)
  statement := policy.Statement[i]
  statement.Effect == "Deny"
  statement.Condition.StringNotLike["aws:PrincipalArn"]
  key := input.resource_changes[_].address
}

############
# Проверка тегов
############

# Проверка: у ключа есть теги "Environment" и "Owner"
required_tags_present[key] {
  tags := input.resource_changes[_].change.after.tags
  tags["Environment"] != ""
  tags["Owner"] != ""
  key := input.resource_changes[_].address
}

############
# Проверка MFA
############

# Проверка: для удаления/отключения ключа требуется MFA
mfa_required_for_sensitive_actions[key] {
  some i
  policy := json.unmarshal(input.resource_changes[_].change.after.policy)
  statement := policy.Statement[i]
  statement.Effect == "Allow"
  statement.Action[_] == "kms:ScheduleKeyDeletion"
  statement.Condition.Bool["aws:MultiFactorAuthPresent"] == "true"
  key := input.resource_changes[_].address
}

############
# Финальное правило
############

allow {
  count(rotation_enabled) > 0
  count(has_policy) > 0
  count(deny_all_except_listed) > 0
  count(required_tags_present) > 0
  count(mfa_required_for_sensitive_actions) > 0
}
```

---

## 📦 Что проверяет политика

| Проверка                                              | Описание |
|:------------------------------------------------------|:---------|
| ✅ Включена ротация ключей                             | `enable_key_rotation = true` |
| ✅ Прописана собственная KMS policy                    | Без policy ключ считается небезопасным |
| ✅ В policy запрещён доступ всем, кроме нужных ролей   | Через `Deny` на `PrincipalArn` |
| ✅ Установлены обязательные теги `Environment`, `Owner` | Для управления и аудита |
| ✅ Требуется MFA для удаления ключа                    | Операция `ScheduleKeyDeletion` требует MFA |

---

## 🚀 Как использовать

1. **Создать план Terraform**:

```bash
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json
```

2. **Запустить проверку через conftest**:

```bash
conftest test plan.json --policy policies/kms
```

✅ Если все проверки пройдены — инфраструктуру можно деплоить.

❌ Если хотя бы одна проверка не пройдена — пайплайн CI/CD должен упасть.

---

## 📂 Расширение: Можно разделить политики

Если хочешь более чистую структуру, можешь создать несколько файлов:

| Файл | Проверка |
|:-----|:---------|
| `kms_rotation.rego` | Только проверка ротации |
| `kms_tags.rego` | Проверка тегов |
| `kms_mfa.rego` | Проверка MFA |
| `kms_policy_structure.rego` | Структура policy (Deny всем кроме разрешённых) |

Но сейчас всё собрано **в одном** для удобства.

---

## 📚 Полезные ссылки

- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/docs/latest/)
- [Conftest — Policy Testing for Terraform](https://www.conftest.dev/)
- [AWS KMS Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html)
- [AWS Condition Key: aws:MultiFactorAuthPresent](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-mfa)

---

# ✅ Итого

Ты теперь сможешь:
- Автоматически проверять безопасность KMS ключей
- Отлавливать неправильные policy до деплоя
- Требовать MFA для опасных операций
- Обеспечивать теги для учёта и отчётности

  ```json
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowRootAccountFullAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowUseFromAppRole",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/prod-app-role"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyUseOutsideRegion",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "kms:*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
  }
```

---

# ✅ Best Practices включены:
Enable key rotation: автоматически включено

Scoped IAM roles: каждая среда получает только нужный доступ

Region restriction: запрет использования за пределами нужного региона

Use of aliases: для безопасного обращения к ключу без key_id

Tagging: окружение и владелец
