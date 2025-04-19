// Copyright Amazon.com, Inc. or its a:w:ffiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_organizations_policy" "this" {
  for_each = fileset(path.root, "${local.policies_directory}/*.json")
  name     = trimprefix(trimsuffix(each.value, ".json"), "${local.policies_directory}/")
  content  = file(each.value)
  type     = var.policy_type
}

module "org_policy_attach" {
  depends_on              = [aws_organizations_policy.this]
  source                  = "../org_policy_attach"
  for_each                = var.ou_map
  ou                      = each.key
  policies                = each.value
  policy_id               = local.policy_ids
  policies_directory_name = local.policies_directory
}
