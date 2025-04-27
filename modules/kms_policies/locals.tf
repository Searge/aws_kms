###############################
# Common
###############################
locals {
  name_prefix = "${var.project}-${var.environment_name}"
  type        = var.environment_name == "prod" ? "prod" : "dev"

  # KMS alias components
  key_function = var.key_function != "" ? var.key_function : "aws"
  key_team     = var.key_team != "" ? "${var.key_team}-" : ""
  key_purpose  = var.key_purpose != "" ? var.key_purpose : "cmk"

  # Full alias format
  key_alias = "alias/${var.environment_name}-${local.key_function}-${local.key_team}${local.key_purpose}"

  common_tags = merge(
    {
      "Type"      = local.type,
      "ManagedBy" = "terraform"
    },
    var.tags
  )
}
