package kms.policy

import rego.v1

# Global variables
required_tags := {"environment", "owner", "data-classification"}
max_del_days := 30

# Helper function to get KMS keys being created
kms_keys_created contains resource if {
	some resource in input.resource_changes
	resource.type == "aws_kms_key"
	"create" in resource.change.actions
}

# Rule 1: Check mandatory tags
deny contains msg if {
	some resource in kms_keys_created

	# Get provided tags safely
	provided_tags := object.get(resource.change.after, "tags", {})
	provided_keys := object.keys(provided_tags)
	missing_tags := required_tags - provided_keys

	count(missing_tags) > 0
	msg := sprintf(
		"KMS key '%s' is missing required tags: %v",
		[resource.address, missing_tags],
	)
}

# Rule 2: Check key rotation
deny contains msg if {
	some resource in kms_keys_created

	enable_rotation := object.get(resource.change.after, "enable_key_rotation", null)
	enable_rotation != true

	msg := sprintf(
		"KMS key '%s' must have key rotation enabled.",
		[resource.address],
	)
}

# Rule 3: Check deletion window
deny contains msg if {
	some resource in kms_keys_created

	deletion_window := object.get(resource.change.after, "deletion_window_in_days", null)
	deletion_window != null
	deletion_window < max_del_days

	msg := sprintf(
		"KMS key '%s' deletion window must be at least 30 days, but is set to %v.",
		[resource.address, deletion_window],
	)
}
