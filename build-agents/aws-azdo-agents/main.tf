###############################################
# Security Group
###############################################

resource "aws_security_group" "azdo" {
  name        = "${var.name_prefix}-sg"
  description = "Azure DevOps agent SG"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { Name = "${var.name_prefix}-sg" },
    var.tags
  )
}

###############################################
# IAM + SSM Role
###############################################

resource "aws_iam_role" "ssm" {
  name = "${var.name_prefix}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow instance to read the PAT from Secrets Manager
data "aws_iam_policy_document" "secrets_read" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      var.azure_devops_pat_secret_arn
    ]
  }
}

resource "aws_iam_role_policy" "secrets_read" {
  name   = "${var.name_prefix}-secrets-read"
  role   = aws_iam_role.ssm.id
  policy = data.aws_iam_policy_document.secrets_read.json
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.name_prefix}-ssm-profile"
  role = aws_iam_role.ssm.name
}

###############################################
# Ubuntu AMI Lookup
###############################################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

###############################################
# USER DATA (INLINE)
# - DO NOT put PAT directly in TF vars/state
# - Fetch PAT from Secrets Manager at boot
###############################################

locals {
  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail

    export DEBIAN_FRONTEND=noninteractive

    apt-get update -y
    apt-get install -y curl jq git wget unzip ca-certificates

    # Ensure snapd exists (Ubuntu usually has it, but safe)
    apt-get install -y snapd || true

    # Install/enable SSM Agent (snap)
    snap install amazon-ssm-agent --classic || true
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
    systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent.service || true

    # Create agent user
    if ! id azdevops >/dev/null 2>&1; then
      useradd -m -s /bin/bash azdevops
    fi

    # Create agent directory
    mkdir -p /opt/azdo-agent
    chown -R azdevops:azdevops /opt/azdo-agent

    # Download and extract agent (only if not already)
    AGENT_VERSION="${var.azure_devops_agent_version}"
    AGENT_TGZ="vsts-agent-linux-x64-${var.azure_devops_agent_version}.tar.gz"
    AGENT_URL="https://download.agent.dev.azure.com/agent/${var.azure_devops_agent_version}/${AGENT_TGZ}"

    if [ ! -f "/opt/azdo-agent/config.sh" ]; then
      cd /opt/azdo-agent
      wget -q "${AGENT_URL}" -O "${AGENT_TGZ}"
      tar zxf "${AGENT_TGZ}"
      chown -R azdevops:azdevops /opt/azdo-agent

      # Install dependencies (script provided by agent)
      /opt/azdo-agent/bin/installdependencies.sh || true
    fi

    # Fetch PAT from Secrets Manager
    # Instance role must allow secretsmanager:GetSecretValue on the secret ARN.
    PAT=$(aws secretsmanager get-secret-value \
      --region "${var.aws_region}" \
      --secret-id "${var.azure_devops_pat_secret_arn}" \
      --query SecretString \
      --output text)

    # Configure agent as azdevops user (only once)
    su - azdevops -c "
      set -euo pipefail
      cd /opt/azdo-agent
      if [ ! -f .agent ]; then
        ./config.sh --unattended \
          --url '${var.azure_devops_org_url}' \
          --auth pat \
          --token '${PAT}' \
          --pool '${var.azure_devops_pool_name}' \
          --agent '${var.agent_name_prefix}-'\\\$(hostname) \
          --work '_work' \
          --acceptTeeEula \
          --replace
      fi
    "

    # Install and start service
    cd /opt/azdo-agent
    ./svc.sh install azdevops || true
    ./svc.sh start || true
  EOT
}

###############################################
# LAUNCH TEMPLATE
###############################################

resource "aws_launch_template" "azdo" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm.name
  }

  vpc_security_group_ids = [aws_security_group.azdo.id]

  user_data = base64encode(local.user_data)

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name  = var.name_prefix
        Role  = "ado-agent"
        Stack = "build"
      },
      var.tags
    )
  }
}

###############################################
# AUTO SCALING GROUP
###############################################

resource "aws_autoscaling_group" "azdo" {
  name                = "${var.name_prefix}-asg"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.azdo.id
    version = "$Latest"
  }

  # Propagate tags to instances
  tag {
    key                 = "Name"
    value               = var.name_prefix
    propagate_at_launch = true
  }
  tag {
    key                 = "Role"
    value               = "ado-agent"
    propagate_at_launch = true
  }
  tag {
    key                 = "Stack"
    value               = "build"
    propagate_at_launch = true
  }
}
