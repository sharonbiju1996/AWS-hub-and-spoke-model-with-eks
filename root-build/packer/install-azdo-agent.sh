#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

AGENT_VERSION="4.266.2"

echo "=== Installing dependencies ==="
sudo apt-get update
sudo apt-get install -y -q curl libicu-dev jq unzip

echo "=== Checking AWS CLI ==="
if command -v aws &> /dev/null; then
    echo "AWS CLI already installed, skipping..."
else
    echo "Installing AWS CLI..."
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
fi

echo "=== Downloading Azure DevOps Agent ==="
if [ -d "/opt/azdo-agent" ] && [ -f "/opt/azdo-agent/config.sh" ]; then
    echo "Azure DevOps agent already installed, skipping..."
else
    sudo mkdir -p /opt/azdo-agent
    cd /opt/azdo-agent
    sudo curl -LsS https://download.agent.dev.azure.com/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz -o agent.tar.gz
    sudo tar zxf agent.tar.gz
    sudo rm agent.tar.gz
    sudo chown -R ubuntu:ubuntu /opt/azdo-agent
    sudo ./bin/installdependencies.sh
fi

echo "=== Creating first-boot script ==="
sudo tee /opt/azdo-agent/configure.sh > /dev/null << 'SCRIPT'
#!/bin/bash
set -e
cd /opt/azdo-agent
[ -f ".configured" ] && exit 0

SECRET_NAME="azdo/agent/config"

# IMDSv2 - Get token first
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Use token to get metadata
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

echo "Region: $REGION"
echo "Instance ID: $INSTANCE_ID"

# Validate region is not empty
if [ -z "$REGION" ]; then
    echo "ERROR: Failed to get region from metadata"
    exit 1
fi

SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query SecretString \
    --output text)

AZDO_URL=$(echo $SECRET | jq -r '.AZDO_URL')
AZDO_PAT=$(echo $SECRET | jq -r '.AZDO_PAT')
AGENT_POOL=$(echo $SECRET | jq -r '.AGENT_POOL')
AGENT_NAME="azdo-agent-${INSTANCE_ID##*-}"

echo "Configuring agent: $AGENT_NAME"
echo "Pool: $AGENT_POOL"
echo "URL: $AZDO_URL"

sudo -u ubuntu ./config.sh --unattended \
    --url "$AZDO_URL" \
    --auth pat \
    --token "$AZDO_PAT" \
    --pool "$AGENT_POOL" \
    --agent "$AGENT_NAME" \
    --acceptTeeEula \
    --replace

sudo ./svc.sh install ubuntu
sudo ./svc.sh start
touch .configured

echo "Azure DevOps Agent configured successfully!"
SCRIPT

sudo chmod +x /opt/azdo-agent/configure.sh

echo "=== Creating systemd service ==="
sudo tee /etc/systemd/system/azdo-agent-configure.service > /dev/null << 'SYSTEMD'
[Unit]
Description=Configure Azure DevOps Agent
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/azdo-agent/configure.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SYSTEMD

sudo systemctl daemon-reload
sudo systemctl enable azdo-agent-configure.service

echo "=== Azure DevOps Agent Setup Complete ==="
echo "Agent installed at /opt/azdo-agent"
echo "Will configure on first boot using secrets from AWS Secrets Manager"