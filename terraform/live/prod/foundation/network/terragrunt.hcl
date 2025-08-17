include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/foundation/network"
}

inputs = {
  network_config = {
    vpc_cidr = "10.0.0.0/16"

    public_subnet_cidrs = [
      "10.0.1.0/24",
      "10.0.2.0/24",
      "10.0.3.0/24"
    ]

    private_subnet_cidrs = [
      "10.0.10.0/24",
      "10.0.20.0/24",
      "10.0.30.0/24"
    ]
  }
}
