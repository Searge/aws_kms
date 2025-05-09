policy "ensure-policy-type" {
  source            = "./organization/ensure-policy-type.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "ensure-secure-kms-policy-dev" {
  source            = "./env/dev/ensure-secure-kms-policy-dev.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "ensure-secure-kms-policy-prod" {
  source            = "./env/dev/ensure-secure-kms-policy-prod.sentinel"
  enforcement_level = "hard-mandatory"
}
