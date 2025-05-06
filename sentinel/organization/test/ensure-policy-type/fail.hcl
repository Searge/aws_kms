mock "tfplan/v2" {
  module {
    source = "../../mocks/mock-tfplan-v2.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
