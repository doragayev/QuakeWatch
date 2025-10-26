#!/bin/bash
# k3s Worker Node User Data Script

set -e

# Variables
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"
K3S_TOKEN="${k3s_token}"
K3S_SERVER="${k3s_server}"

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget git vim htop jq

# Install k3s agent
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" sh -s - \
    --token=${K3S_TOKEN} \
    --server=https://${K3S_SERVER}:6443 \
    --kubelet-arg="cloud-provider=external" \
    --kubelet-arg="provider-id=aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

# Wait for k3s to start
sleep 30

# Create project directory
mkdir -p /opt/${PROJECT_NAME}

# Create useful aliases
cat >> /home/ubuntu/.bashrc << EOF
alias k='kubectl'
alias k3s-status='systemctl status k3s-agent'
alias k3s-logs='journalctl -u k3s-agent -f'
EOF

echo "k3s worker setup completed successfully!"
