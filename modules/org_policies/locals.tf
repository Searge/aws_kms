// Copyright Amazon.com, Inc. or its a:w:ffiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  policies_directory = var.policies_directory == null ? lower(var.policy_type) : var.policies_directory

  policy_ids = {
    for path, policy in aws_organizations_policy.this :
    trimprefix(trimsuffix(path, ".json"), "${local.policies_directory}/") => policy.id
  }

  policy_attachments = flatten([
    for ou, policies in var.ou_map : [
      for policy in policies : {
        id     = "${ou}-${policy}"
        ou     = ou
        policy = policy
      }
    ]
  ])
}