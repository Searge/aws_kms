package kms.policy

import input as tfplan
import rego.v1

# Rule 1: Check mandatory tags
deny contains msg if {
	# Iterate over all resources

	some resource in tfplan.resource_changes

	# Check it is a resource of type aws_kms_key
	resource.type == "aws_kms_key"
	"create" in resource.change.actions

	# --- Logic ---
	required_tags := {"environment", "owner", "data-classification"}
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
	some resource in tfplan.resource_changes
	resource.type == "aws_kms_key"
	"create" in resource.change.actions

	# --- Logic ---
	object.get(resource.change.after, "enable_key_rotation", null) != true
	msg := sprintf(
		"KMS key '%s' must have key rotation enabled.",
		[resource.address],
	)
}

# Rule 3: Check deletion window
deny contains msg if {
	some resource in tfplan.resource_changes
	resource.type == "aws_kms_key"
	"create" in resource.change.actions

	# --- Logic ---
	deletion_window := object.get(resource.change.after, "deletion_window_in_days", null)

	# If deletion_window less then 7 or not a number
	# not is_number(deletion_window)
	deletion_window < 30
	msg := sprintf(
		"KMS key '%s' deletion window must be at least 30 days, but is set to %v.",
		[resource.address, deletion_window],
	)
}
