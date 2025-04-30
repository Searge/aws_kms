###############################
# Common
###############################
locals {
  type        = var.environment_name == "prod" ? "prod" : "dev"

  # KMS alias components
  key_function = var.key_function != "" ? var.key_function : "aws"
  key_team     = var.key_team != "" ? "${var.key_team}" : ""
  key_purpose  = var.key_purpose != "" ? var.key_purpose : "cmk"

  # Full alias format
  custom_key_store_id = join("-", [var.environment_name, local.key_function, local.key_team, local.key_purpose])
  key_alias = "alias/${local.custom_key_store_id}"

  common_tags = merge(
    {
      "Type"      = local.type,
      "ManagedBy" = "terraform"
    },
    var.tags
  )
}
