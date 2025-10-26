#!/bin/bash
# Bastion Host User Data Script for QuakeWatch k3s Cluster

set -e

# Variables
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    jq \
    unzip \
    awscli \
    kubectl \
    helm

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install k3s CLI
curl -sfL https://get.k3s.io | sh -s - --help

# Create project directory
mkdir -p /opt/${PROJECT_NAME}
cd /opt/${PROJECT_NAME}

# Create SSH config for easier access to k3s nodes
cat > /home/ubuntu/.ssh/config << EOF
Host k3s-master-*
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host k3s-worker-*
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

chown ubuntu:ubuntu /home/ubuntu/.ssh/config
chmod 600 /home/ubuntu/.ssh/config

# Create useful aliases
cat >> /home/ubuntu/.bashrc << EOF

# QuakeWatch k3s aliases
alias k='kubectl'
alias k3s-status='systemctl status k3s'
alias k3s-logs='journalctl -u k3s -f'
alias k3s-restart='sudo systemctl restart k3s'
alias k3s-stop='sudo systemctl stop k3s'
alias k3s-start='sudo systemctl start k3s'

# Project aliases
alias cd-project='cd /opt/${PROJECT_NAME}'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# AWS aliases
alias aws-region='aws configure get region'
alias aws-account='aws sts get-caller-identity --query Account --output text'

# Kubernetes aliases
alias k-nodes='kubectl get nodes -o wide'
alias k-pods='kubectl get pods -A'
alias k-svc='kubectl get svc -A'
alias k-ingress='kubectl get ingress -A'
alias k-events='kubectl get events --sort-by=.metadata.creationTimestamp'

# QuakeWatch specific aliases
alias qw-pods='kubectl get pods -n quakewatch'
alias qw-svc='kubectl get svc -n quakewatch'
alias qw-logs='kubectl logs -n quakewatch -l app=quakewatch'
alias qw-describe='kubectl describe pod -n quakewatch -l app=quakewatch'

# Monitoring aliases
alias prom-status='kubectl get pods -n monitoring'
alias grafana-status='kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana'
alias prometheus-status='kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus'

EOF

# Create project README
cat > /opt/${PROJECT_NAME}/README.md << EOF
# QuakeWatch k3s Cluster

## Environment: ${ENVIRONMENT}
## Project: ${PROJECT_NAME}

## Quick Commands

### Cluster Management
- \`k3s-status\` - Check k3s service status
- \`k3s-logs\` - View k3s logs
- \`k3s-restart\` - Restart k3s service

### Kubernetes Management
- \`k-nodes\` - List all nodes
- \`k-pods\` - List all pods
- \`k-svc\` - List all services
- \`k-ingress\` - List all ingress

### QuakeWatch Application
- \`qw-pods\` - List QuakeWatch pods
- \`qw-svc\` - List QuakeWatch services
- \`qw-logs\` - View QuakeWatch logs
- \`qw-describe\` - Describe QuakeWatch pods

### Monitoring
- \`prom-status\` - Check Prometheus status
- \`grafana-status\` - Check Grafana status
- \`prometheus-status\` - Check Prometheus status

## Access Information

### SSH to k3s nodes
\`\`\`bash
# Master nodes
ssh ubuntu@<master-private-ip>

# Worker nodes  
ssh ubuntu@<worker-private-ip>
\`\`\`

### Port Forwarding
\`\`\`bash
# Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

# QuakeWatch
kubectl port-forward -n quakewatch svc/quakewatch 8080:80
\`\`\`

## Useful Files
- k3s config: /etc/rancher/k3s/k3s.yaml
- k3s logs: /var/log/syslog
- k3s data: /var/lib/rancher/k3s/

EOF

# Set proper permissions
chown -R ubuntu:ubuntu /opt/${PROJECT_NAME}
chmod -R 755 /opt/${PROJECT_NAME}

# Create log directory
mkdir -p /var/log/${PROJECT_NAME}
chown ubuntu:ubuntu /var/log/${PROJECT_NAME}

# Install additional tools
apt-get install -y \
    tree \
    ncdu \
    tmux \
    screen \
    rsync \
    netcat-openbsd \
    tcpdump \
    iotop \
    nethogs

# Create tmux configuration
cat > /home/ubuntu/.tmux.conf << EOF
# QuakeWatch k3s tmux configuration
set -g default-terminal "screen-256color"
set -g history-limit 10000
set -g mouse on

# Key bindings
bind-key C new-window
bind-key | split-window -h
bind-key - split-window -v
bind-key h select-pane -L
bind-key j select-pane -D
bind-key k select-pane -U
bind-key l select-pane -R

# Status bar
set -g status-bg colour235
set -g status-fg colour136
set -g status-left '#[fg=colour166]#(whoami)@#(hostname)'
set -g status-right '#[fg=colour166]%Y-%m-%d %H:%M:%S'
EOF

chown ubuntu:ubuntu /home/ubuntu/.tmux.conf

# Create screen configuration
cat > /home/ubuntu/.screenrc << EOF
# QuakeWatch k3s screen configuration
startup_message off
defscrollback 10000
hardstatus alwayslastline
hardstatus string '%{= kG}[ %{G}%H %{g}][%= %{= kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B} %m-%d %{W}%c %{g}]'
EOF

chown ubuntu:ubuntu /home/ubuntu/.screenrc

# Create useful scripts
cat > /opt/${PROJECT_NAME}/scripts/k3s-backup.sh << 'EOF'
#!/bin/bash
# k3s backup script

BACKUP_DIR="/opt/backups/k3s"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="k3s-backup-${DATE}.tar.gz"

mkdir -p ${BACKUP_DIR}

# Backup k3s data
tar -czf ${BACKUP_DIR}/${BACKUP_FILE} \
    /var/lib/rancher/k3s/server \
    /etc/rancher/k3s \
    /var/log/syslog

# Upload to S3 (if configured)
if [ ! -z "$S3_BUCKET" ]; then
    aws s3 cp ${BACKUP_DIR}/${BACKUP_FILE} s3://${S3_BUCKET}/k3s-backups/
fi

echo "Backup completed: ${BACKUP_DIR}/${BACKUP_FILE}"
EOF

chmod +x /opt/${PROJECT_NAME}/scripts/k3s-backup.sh

# Create monitoring script
cat > /opt/${PROJECT_NAME}/scripts/monitor-cluster.sh << 'EOF'
#!/bin/bash
# Cluster monitoring script

echo "=== QuakeWatch k3s Cluster Status ==="
echo "Date: $(date)"
echo ""

echo "1. k3s Service Status:"
systemctl status k3s --no-pager -l

echo ""
echo "2. Node Status:"
kubectl get nodes -o wide

echo ""
echo "3. Pod Status:"
kubectl get pods -A

echo ""
echo "4. Service Status:"
kubectl get svc -A

echo ""
echo "5. Resource Usage:"
kubectl top nodes 2>/dev/null || echo "Metrics server not available"

echo ""
echo "6. Recent Events:"
kubectl get events --sort-by=.metadata.creationTimestamp | tail -10
EOF

chmod +x /opt/${PROJECT_NAME}/scripts/monitor-cluster.sh

# Create troubleshooting script
cat > /opt/${PROJECT_NAME}/scripts/troubleshoot.sh << 'EOF'
#!/bin/bash
# Troubleshooting script

echo "=== QuakeWatch k3s Troubleshooting ==="
echo "Date: $(date)"
echo ""

echo "1. System Resources:"
echo "Memory:"
free -h
echo ""
echo "Disk:"
df -h
echo ""
echo "CPU:"
top -bn1 | grep "Cpu(s)"

echo ""
echo "2. k3s Logs (last 50 lines):"
journalctl -u k3s -n 50 --no-pager

echo ""
echo "3. Docker/Containerd Status:"
systemctl status containerd --no-pager -l

echo ""
echo "4. Network Connectivity:"
echo "Testing connectivity to k3s API server..."
curl -k https://localhost:6443/version 2>/dev/null || echo "k3s API server not responding"

echo ""
echo "5. k3s Configuration:"
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    echo "k3s config file exists"
    echo "k3s config permissions:"
    ls -la /etc/rancher/k3s/k3s.yaml
else
    echo "k3s config file not found"
fi
EOF

chmod +x /opt/${PROJECT_NAME}/scripts/troubleshoot.sh

# Set up log rotation
cat > /etc/logrotate.d/${PROJECT_NAME} << EOF
/var/log/${PROJECT_NAME}/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
}
EOF

# Create systemd service for monitoring
cat > /etc/systemd/system/${PROJECT_NAME}-monitor.service << EOF
[Unit]
Description=QuakeWatch k3s Cluster Monitor
After=network.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/${PROJECT_NAME}
ExecStart=/opt/${PROJECT_NAME}/scripts/monitor-cluster.sh
Restart=always
RestartSec=300

[Install]
WantedBy=multi-user.target
EOF

# Enable and start monitoring service
systemctl daemon-reload
systemctl enable ${PROJECT_NAME}-monitor.service
systemctl start ${PROJECT_NAME}-monitor.service

# Create cron job for backups
cat > /etc/cron.d/${PROJECT_NAME}-backup << EOF
# QuakeWatch k3s backup - daily at 2 AM
0 2 * * * ubuntu /opt/${PROJECT_NAME}/scripts/k3s-backup.sh >> /var/log/${PROJECT_NAME}/backup.log 2>&1
EOF

# Set up log monitoring
cat > /opt/${PROJECT_NAME}/scripts/log-monitor.sh << 'EOF'
#!/bin/bash
# Log monitoring script

LOG_FILE="/var/log/${PROJECT_NAME}/monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[${DATE}] Starting log monitoring..." >> ${LOG_FILE}

# Monitor k3s logs for errors
journalctl -u k3s -f --since "1 minute ago" | grep -i error >> ${LOG_FILE} 2>&1 &

# Monitor system logs for issues
tail -f /var/log/syslog | grep -i "k3s\|kubernetes\|quakewatch" >> ${LOG_FILE} 2>&1 &
EOF

chmod +x /opt/${PROJECT_NAME}/scripts/log-monitor.sh

# Final system update and cleanup
apt-get autoremove -y
apt-get autoclean

# Create welcome message
cat > /etc/motd << EOF
Welcome to QuakeWatch k3s Cluster Bastion Host!

Environment: ${ENVIRONMENT}
Project: ${PROJECT_NAME}

Quick Commands:
- k3s-status: Check k3s service status
- k3s-logs: View k3s logs
- k-nodes: List Kubernetes nodes
- k-pods: List all pods
- qw-pods: List QuakeWatch pods

Project Directory: /opt/${PROJECT_NAME}
Scripts: /opt/${PROJECT_NAME}/scripts/

For more information, see: /opt/${PROJECT_NAME}/README.md
EOF

echo "Bastion host setup completed successfully!"
