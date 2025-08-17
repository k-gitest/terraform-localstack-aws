include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/foundation/rds"
}

inputs = {
  rds_configs = {
    main_postgres = {
      engine                  = "postgres"
      engine_version          = "14.7"
      instance_class          = "db.t3.small"
      storage                 = 20
      db_name                 = "maindb"
      username                = "appuser"
      port                    = 5432
      family                  = "postgres14"
      skip_snapshot           = true
      publicly_accessible     = false
      backup_retention        = 1
      backup_window           = "03:00-04:00"
      maintenance_window      = "sun:04:00-sun:05:00"
    }
  }
}
