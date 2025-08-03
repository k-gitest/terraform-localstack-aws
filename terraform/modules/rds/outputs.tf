output "db_instances" {
  description = "Database instance information"
  value = {
    for k, v in aws_db_instance.this : k => {
      endpoint               = v.endpoint
      port                  = v.port
      db_name               = v.db_name
      username              = v.username
      engine                = v.engine
      engine_version        = v.engine_version
      instance_class        = v.instance_class
      allocated_storage     = v.allocated_storage
      identifier            = v.identifier
      arn                   = v.arn
      availability_zone     = v.availability_zone
      backup_retention_period = v.backup_retention_period
      backup_window         = v.backup_window
      maintenance_window    = v.maintenance_window
    }
  }
  sensitive = false
}

output "db_security_group_ids" {
  description = "Database security group IDs"
  value = {
    for k, v in aws_security_group.db : k => v.id
  }
}

output "db_parameter_group_names" {
  description = "Database parameter group names"
  value = {
    for k, v in aws_db_parameter_group.this : k => v.name
  }
}

output "db_subnet_group_name" {
  description = "Database subnet group name"
  value = aws_db_subnet_group.this.name
}

output "db_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.rds_sg.id
}