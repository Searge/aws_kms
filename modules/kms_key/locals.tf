###############################
# Common
###############################
locals {
  type = var.environment_name == "prod" ? "prod" : "dev"

  # KMS alias components
  key_function = var.key_function != "" ? var.key_function : "aws"
  key_team     = var.key_team != "" ? "${var.key_team}" : ""
  key_purpose  = var.key_purpose != "" ? var.key_purpose : "cmk"

  # Full alias format
  custom_key_store_id = join("-", [var.environment_name, local.key_function, local.key_team, local.key_purpose])
  key_alias           = "alias/${local.custom_key_store_id}"

  # Using absolute path
  policies_directory = "${path.module}/../../policies/aws_keys_policies"
  custom_policy = templatefile("${local.policies_directory}/${var.custom_policy}", {
      account_id = var.account_id,
      env        = var.environment_name
    })
}
