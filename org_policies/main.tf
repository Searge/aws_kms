provider "aws" {
  region = var.aws_region
}

module "scps" {
  source = "../modules/org_policies"
  policy_type = "SERVICE_CONTROL_POLICY"
  policies_directory = format("policies/%s", lower(var.policy_type))
  ou_map = {
    "r-t32n" = ["root"]
  }
}
# module "rcps" {
#   source = "../modules/org_policies"
#   policy_type = "RESOURCE_CONTROL_POLICY"
#   policies_directory = format("policies/%s", lower(var.policy_type))
#   ou_map = {
#     "r-t32n" = ["root"]
#   }
# }
