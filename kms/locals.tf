locals {
  # Determine policy file to use
  policy_file_path = var.policy_file != "" ? "${path.module}/policies/kms/${var.policy_file}" : ""
  custom_policy    = local.policy_file_path != "" ? file(local.policy_file_path) : ""
}