# module-aws-firewall-endpoints/main.tf

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

# Create Network Firewall
resource "aws_networkfirewall_firewall" "this" {
  name                = "${var.name_prefix}-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this.arn
  vpc_id              = var.vpc_id
  
  subnet_mapping {
    subnet_id = var.firewall_subnet_ids[0]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-firewall"
  })
}

# Create firewall policy (SINGLE DEFINITION)
resource "aws_networkfirewall_firewall_policy" "this" {
  name = "${var.name_prefix}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = var.policy_stateless_default_actions
    stateless_fragment_default_actions = var.policy_stateless_fragment_default_actions
    
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful.arn
    }
    
    stateless_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.stateless.arn
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-firewall-policy"
  })
}

# Create stateful rule group
resource "aws_networkfirewall_rule_group" "stateful" {
  capacity = 100
  name     = "${var.name_prefix}-stateful-rule-group"
  type     = "STATEFUL"
  
  rule_group {
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          protocol         = "IP"
          direction        = "FORWARD"
          source_port      = "ANY"
          source           = "ANY"
        }
        rule_option {
          keyword = "sid:1"
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-stateful-rule-group"
  })
}

# Create stateless rule group
resource "aws_networkfirewall_rule_group" "stateless" {
  capacity = var.rule_capacity
  name     = "${var.name_prefix}-stateless-rule-group"
  type     = "STATELESS"
  
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-stateless-rule-group"
  })
}