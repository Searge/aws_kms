mock "tfplan/v2" {
  module {
    source = "../../mocks/mock-tfplan-fail-v2.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
