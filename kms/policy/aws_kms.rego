package kms.policy

# Check mandatory tags
deny contains msg if {
	# Iterate over all resources
	resource := input.resource_changes[_]

	# Перевіряємо, чи це ресурс aws_kms_key, який створюється
	resource.type == "aws_kms_key"
	resource.change.actions[_] == "create"

	# --- Логіка перевірки ---
	required_tags := {"environment", "owner", "data-classification"}
	provided_tags := object.get(resource.change.after, "tags", {})
	provided_keys := {key | provided_tags[key]}
	missing_tags := required_tags - provided_keys

	count(missing_tags) > 0
	msg := sprintf("KMS key '%s' is missing required tags: %v", [resource.address, missing_tags])
}

# Правило 2: Перевірка ротації ключів
deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_kms_key"
	resource.change.actions[_] == "create"

	# --- Логіка перевірки ---
	object.get(resource.change.after, "enable_key_rotation", null) != true
	msg := sprintf("KMS key '%s' must have key rotation enabled.", [resource.address])
}

# Правило 3: Перевірка періоду видалення
deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_kms_key"
	resource.change.actions[_] == "create"

	# --- Логіка перевірки ---
	deletion_window := object.get(resource.change.after, "deletion_window_in_days", null)

	# Якщо deletion_window не є числом АБО воно менше 30
	not is_number(deletion_window)
	deletion_window < 30
	msg := sprintf("KMS key '%s' deletion window must be at least 30 days, but is set to %v.", [resource.address, deletion_window])
}
