###############################
# Common
###############################
locals {
  name_prefix = "${var.project}-${var.environment_name}"
  type        = var.environment_name == "prod" ? "prod" : "dev"
  common_tags = merge(
    {
      "Type"      = local.type,
      "ManagedBy" = "terraform"
    },
    var.tags
  )
}
