include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/foundation/network"
}

inputs = {
  network_config = {
    vpc_cidr = "10.1.0.0/16"

    public_subnet_cidrs = [
      "10.1.1.0/24",
      "10.1.2.0/24"
    ]

    private_subnet_cidrs = [
      "10.1.10.0/24",
      "10.1.20.0/24"
    ]
  }
}
