provider "aws" {
  region = var.aws_region
}

module "scps" {
  source = "../modules/org_policies"
  policy_type = "SERVICE_CONTROL_POLICY"
  ou_map = {
    "r-t32n" = ["root", "allow_services"]
  }
}
module "rcps" {
  source = "../modules/org_policies"
  policy_type = "RESOURCE_CONTROL_POLICY"
  ou_map = {
    "r-t32n" = ["root"]
  }
}
