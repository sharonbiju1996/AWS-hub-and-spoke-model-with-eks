# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-subnet-group"
    }
  )
}

# Security Group for RDS
resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-sg"
  description = "Security group for ${var.engine} RDS instance"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-sg"
    }
  )
}

# Security Group Rules - Ingress from CIDR blocks
resource "aws_security_group_rule" "ingress_cidr" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.this.id
  description       = "${var.engine} access from allowed CIDRs"
}

# Security Group Rules - Ingress from Security Groups
resource "aws_security_group_rule" "ingress_sg" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.this.id
  description              = "${var.engine} access from security group"
}

# Security Group Rule - Egress
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
}

# DB Parameter Group
resource "aws_db_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name        = "${var.name_prefix}-params"
  family      = var.parameter_group_family
  description = "Custom parameter group for ${var.engine} - ${var.name_prefix}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Instance
resource "aws_db_instance" "this" {
  identifier = var.identifier != null ? var.identifier : "${var.name_prefix}-db"

  # Engine configuration
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = var.storage_encrypted
  kms_key_id          = var.kms_key_id
  iops                = var.iops
  storage_throughput  = var.storage_throughput

  # Database configuration
  db_name  = var.db_name
  username = var.username
  password = var.rds_password
  port     = var.port

  # Parameter and option groups
  parameter_group_name = var.create_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  option_group_name    = var.option_group_name
  
  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = concat([aws_security_group.this.id], var.additional_security_group_ids)
  publicly_accessible    = var.publicly_accessible

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  # Monitoring
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id      = var.performance_insights_kms_key_id
  monitoring_interval                  = var.monitoring_interval
  monitoring_role_arn                  = var.monitoring_role_arn

  # High availability
  multi_az          = var.multi_az
  availability_zone = var.availability_zone

  # Deletion protection
  deletion_protection       = var.deletion_protection
  skip_final_snapshot      = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : (var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${var.name_prefix}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}")

  # Snapshot
  snapshot_identifier = var.snapshot_identifier

  # Updates
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately         = var.apply_immediately
  allow_major_version_upgrade = var.allow_major_version_upgrade

  # Copy tags to snapshots
  copy_tags_to_snapshot = true
  
  # CA certificate
  ca_cert_identifier = var.ca_cert_identifier

  # Replica configuration
  replicate_source_db = var.replicate_source_db

  tags = merge(
    var.tags,
    {
      Name = var.identifier != null ? var.identifier : "${var.name_prefix}-db"
    }
  )

  depends_on = [aws_db_parameter_group.this]

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      password
    ]
  }
}