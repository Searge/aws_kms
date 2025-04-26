// Copyright Amazon.com, Inc. or its a:w:ffiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_organizations_policy" "this" {
  for_each = fileset(path.root, "${local.policies_directory}/*.json")
  name     = trimprefix(trimsuffix(each.value, ".json"), "${local.policies_directory}/")
  content  = file(each.value)
  type     = var.policy_type
}

resource "aws_organizations_policy_attachment" "this" {
  depends_on = [aws_organizations_policy.this]
  for_each   = { for entry in local.policy_attachments : entry.id => entry }

  policy_id = local.policy_ids[each.value.policy]
  target_id = each.value.ou
}
