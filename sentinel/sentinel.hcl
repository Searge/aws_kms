policy "ensure-policy-type" {
  source            = "./organization/ensure-policy-type.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "ensure-secure-kms-policy" {
  source            = "./env/dev/ensure-secure-kms-policy.sentinel"
  enforcement_level = "hard-mandatory"
}
