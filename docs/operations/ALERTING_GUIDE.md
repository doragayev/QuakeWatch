# Alerting Configuration Guide

## Overview

This guide provides comprehensive documentation for the QuakeWatch alerting system, including Prometheus alert rules, AlertManager configuration, and notification channels.

## Alert Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Prometheus    │    │  AlertManager   │    │  Notifications  │
│   (Alert Rules) │───▶│  (Routing)      │───▶│  (Channels)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Alert Rules   │    │   Grouping      │    │   Email         │
│   (Prometheus)  │    │   Deduplication │    │   Slack         │
└─────────────────┘    └─────────────────┘    │   Webhook       │
                                               │   PagerDuty     │
                                               └─────────────────┘
```

## Alert Categories

### 1. Critical Alerts
**Purpose**: Immediate attention required, service down or system failure

**Examples**:
- QuakeWatchDown
- KubernetesPodCrashLooping
- KubernetesNodeDown
- KubernetesDiskSpaceLow
- PrometheusDown

**Configuration**:
```yaml
- alert: QuakeWatchDown
  expr: up{job="quakewatch"} == 0
  for: 1m
  labels:
    severity: critical
    service: quakewatch
  annotations:
    summary: "QuakeWatch application is down"
    description: "QuakeWatch has been down for more than 1 minute"
    runbook_url: "https://docs.example.com/runbooks/quakewatch-down"
```

### 2. Warning Alerts
**Purpose**: Performance issues, resource constraints, attention needed

**Examples**:
- QuakeWatchHighErrorRate
- QuakeWatchHighResponseTime
- KubernetesHighCPUUsage
- KubernetesHighMemoryUsage
- KubernetesPodNotReady

**Configuration**:
```yaml
- alert: QuakeWatchHighErrorRate
  expr: rate(quakewatch_errors_total[5m]) > 0.1
  for: 2m
  labels:
    severity: warning
    service: quakewatch
  annotations:
    summary: "QuakeWatch high error rate detected"
    description: "Error rate is {{ $value }} errors/sec for more than 2 minutes"
```

### 3. Info Alerts
**Purpose**: Informational, high volume, business metrics

**Examples**:
- QuakeWatchHighEarthquakeVolume
- QuakeWatchDataProcessingStopped
- QuakeWatchAPICallFailure

**Configuration**:
```yaml
- alert: QuakeWatchHighEarthquakeVolume
  expr: rate(quakewatch_earthquakes_total[5m]) > 10
  for: 2m
  labels:
    severity: info
    service: quakewatch
  annotations:
    summary: "High earthquake volume detected"
    description: "Processing {{ $value }} earthquakes/sec"
```

## Prometheus Alert Rules

### Application Alerts

#### 1. Service Availability
```yaml
- alert: QuakeWatchDown
  expr: up{job="quakewatch"} == 0
  for: 1m
  labels:
    severity: critical
    service: quakewatch
  annotations:
    summary: "QuakeWatch application is down"
    description: "QuakeWatch has been down for more than 1 minute"
    runbook_url: "https://docs.example.com/runbooks/quakewatch-down"

- alert: QuakeWatchNoRequests
  expr: rate(quakewatch_requests_total[10m]) == 0
  for: 5m
  labels:
    severity: warning
    service: quakewatch
  annotations:
    summary: "QuakeWatch receiving no requests"
    description: "No requests received for more than 10 minutes"
```

#### 2. Performance Alerts
```yaml
- alert: QuakeWatchHighResponseTime
  expr: histogram_quantile(0.95, rate(quakewatch_request_duration_seconds_bucket[5m])) > 5
  for: 3m
  labels:
    severity: warning
    service: quakewatch
  annotations:
    summary: "QuakeWatch high response time"
    description: "95th percentile response time is {{ $value }}s"

- alert: QuakeWatchHighErrorRate
  expr: rate(quakewatch_errors_total[5m]) > 0.1
  for: 2m
  labels:
    severity: warning
    service: quakewatch
  annotations:
    summary: "QuakeWatch high error rate"
    description: "Error rate is {{ $value }} errors/sec"
```

#### 3. Resource Usage Alerts
```yaml
- alert: QuakeWatchHighMemoryUsage
  expr: (process_resident_memory_bytes{job="quakewatch"} / 1024 / 1024) > 500
  for: 5m
  labels:
    severity: warning
    service: quakewatch
  annotations:
    summary: "QuakeWatch high memory usage"
    description: "Memory usage is {{ $value }}MB"

- alert: QuakeWatchHighCPUUsage
  expr: rate(process_cpu_seconds_total{job="quakewatch"}[5m]) > 0.8
  for: 5m
  labels:
    severity: warning
    service: quakewatch
  annotations:
    summary: "QuakeWatch high CPU usage"
    description: "CPU usage is {{ $value }}"
```

#### 4. Business Logic Alerts
```yaml
- alert: QuakeWatchEarthquakeProcessingStopped
  expr: rate(quakewatch_earthquakes_total[10m]) == 0
  for: 10m
  labels:
    severity: warning
    service: quakewatch
  annotations:
    summary: "Earthquake processing stopped"
    description: "No earthquakes processed for more than 10 minutes"

- alert: QuakeWatchDataProcessingStopped
  expr: rate(quakewatch_data_points_processed_total[10m]) == 0
  for: 10m
  labels:
    severity: warning
    service: quakewatch
  annotations:
    summary: "Data processing stopped"
    description: "No data points processed for more than 10 minutes"
```

### Kubernetes Cluster Alerts

#### 1. Pod Health Alerts
```yaml
- alert: KubernetesPodCrashLooping
  expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
  for: 5m
  labels:
    severity: critical
    service: kubernetes
  annotations:
    summary: "Pod {{ $labels.pod }} is crash looping"
    description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is crash looping"

- alert: KubernetesPodNotReady
  expr: kube_pod_status_phase{phase!="Running",phase!="Succeeded"} > 0
  for: 5m
  labels:
    severity: warning
    service: kubernetes
  annotations:
    summary: "Pod {{ $labels.pod }} is not ready"
    description: "Pod {{ $labels.pod }} is in {{ $labels.phase }} phase"
```

#### 2. Resource Usage Alerts
```yaml
- alert: KubernetesHighCPUUsage
  expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
  for: 5m
  labels:
    severity: warning
    service: kubernetes
  annotations:
    summary: "High CPU usage on node {{ $labels.instance }}"
    description: "CPU usage is {{ $value }}% on node {{ $labels.instance }}"

- alert: KubernetesHighMemoryUsage
  expr: 100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) > 90
  for: 5m
  labels:
    severity: warning
    service: kubernetes
  annotations:
    summary: "High memory usage on node {{ $labels.instance }}"
    description: "Memory usage is {{ $value }}% on node {{ $labels.instance }}"
```

#### 3. Infrastructure Alerts
```yaml
- alert: KubernetesDiskSpaceLow
  expr: 100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100) > 90
  for: 5m
  labels:
    severity: critical
    service: kubernetes
  annotations:
    summary: "Low disk space on node {{ $labels.instance }}"
    description: "Disk usage is {{ $value }}% on node {{ $labels.instance }}"

- alert: KubernetesNodeDown
  expr: up{job="node-exporter"} == 0
  for: 1m
  labels:
    severity: critical
    service: kubernetes
  annotations:
    summary: "Node {{ $labels.instance }} is down"
    description: "Node {{ $labels.instance }} has been down for more than 1 minute"
```

## AlertManager Configuration

### 1. Routing Configuration

```yaml
route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
  routes:
  - match:
      severity: critical
    receiver: 'critical-alerts'
    group_wait: 5s
    repeat_interval: 5m
  - match:
      severity: warning
    receiver: 'warning-alerts'
    group_wait: 30s
    repeat_interval: 30m
  - match:
      service: quakewatch
    receiver: 'quakewatch-alerts'
    group_wait: 10s
    repeat_interval: 15m
```

### 2. Receiver Configuration

#### Webhook Receiver
```yaml
receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://localhost:5001/'
    send_resolved: true
```

#### Email Receiver
```yaml
- name: 'critical-alerts'
  email_configs:
  - to: 'admin@quakewatch.local'
    subject: 'CRITICAL ALERT: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      Severity: {{ .Labels.severity }}
      Service: {{ .Labels.service }}
      Time: {{ .StartsAt }}
      {{ end }}
```

#### Slack Receiver
```yaml
- name: 'slack-alerts'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    channel: '#alerts'
    title: 'Alert: {{ .GroupLabels.alertname }}'
    text: |
      {{ range .Alerts }}
      *Alert:* {{ .Annotations.summary }}
      *Description:* {{ .Annotations.description }}
      *Severity:* {{ .Labels.severity }}
      *Service:* {{ .Labels.service }}
      {{ end }}
```

#### PagerDuty Receiver
```yaml
- name: 'pagerduty-alerts'
  pagerduty_configs:
  - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
    description: '{{ .GroupLabels.alertname }}'
    details:
      summary: '{{ .Annotations.summary }}'
      description: '{{ .Annotations.description }}'
      severity: '{{ .Labels.severity }}'
```

### 3. Inhibition Rules

```yaml
inhibit_rules:
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  equal: ['alertname', 'cluster', 'service']
```

## Notification Channels

### 1. Email Configuration

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@quakewatch.local'
  smtp_auth_username: 'alerts@quakewatch.local'
  smtp_auth_password: 'your-app-password'

receivers:
- name: 'email-alerts'
  email_configs:
  - to: 'admin@quakewatch.local'
    subject: 'Alert: {{ .GroupLabels.alertname }}'
    html: |
      <h2>Alert Details</h2>
      <table border="1">
        <tr><td>Alert</td><td>{{ .GroupLabels.alertname }}</td></tr>
        <tr><td>Severity</td><td>{{ .Labels.severity }}</td></tr>
        <tr><td>Service</td><td>{{ .Labels.service }}</td></tr>
        <tr><td>Summary</td><td>{{ .Annotations.summary }}</td></tr>
        <tr><td>Description</td><td>{{ .Annotations.description }}</td></tr>
      </table>
```

### 2. Slack Integration

```yaml
receivers:
- name: 'slack-alerts'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    channel: '#alerts'
    title: '🚨 Alert: {{ .GroupLabels.alertname }}'
    text: |
      {{ range .Alerts }}
      *Alert:* {{ .Annotations.summary }}
      *Description:* {{ .Annotations.description }}
      *Severity:* {{ .Labels.severity }}
      *Service:* {{ .Labels.service }}
      *Time:* {{ .StartsAt }}
      {{ if .Annotations.runbook_url }}
      *Runbook:* {{ .Annotations.runbook_url }}
      {{ end }}
      {{ end }}
    send_resolved: true
```

### 3. Webhook Integration

```python
# alert-webhook-receiver.py
from flask import Flask, request, jsonify
import logging

app = Flask(__name__)

@app.route('/critical', methods=['POST'])
def receive_critical_alert():
    alert_data = request.get_json()
    # Process critical alert
    logging.critical(f"CRITICAL ALERT: {alert_data}")
    return jsonify({"status": "received"}), 200

@app.route('/warning', methods=['POST'])
def receive_warning_alert():
    alert_data = request.get_json()
    # Process warning alert
    logging.warning(f"WARNING ALERT: {alert_data}")
    return jsonify({"status": "received"}), 200
```

## Alert Testing

### 1. Manual Alert Testing

```bash
# Test QuakeWatch down alert
kubectl scale deployment quakewatch --replicas=0 -n quakewatch
# Wait 2 minutes, then scale back:
kubectl scale deployment quakewatch --replicas=1 -n quakewatch

# Test high CPU alert
yes > /dev/null &
# Stop with: pkill yes

# Test high memory alert
python3 -c "import time; [time.sleep(0.1) for _ in range(1000000)]" &
```

### 2. Alert Validation

```bash
# Check active alerts
curl -s 'http://localhost:9090/api/v1/alerts' | jq '.data.alerts[]'

# Check alert rules
curl -s 'http://localhost:9090/api/v1/rules' | jq '.data.groups[].rules[]'

# Test alert expression
curl "http://localhost:9090/api/v1/query?query=up{job=\"quakewatch\"}"
```

### 3. Webhook Testing

```bash
# Start webhook receiver
python3 alert-webhook-receiver.py

# Test webhook manually
curl -X POST http://localhost:5001/critical \
  -H "Content-Type: application/json" \
  -d '{"alerts":[{"labels":{"alertname":"TestAlert","severity":"critical"},"annotations":{"summary":"Test alert"}}]}'
```

## Alert Tuning

### 1. Threshold Adjustment

**Initial Thresholds**:
```yaml
# CPU Usage
expr: rate(process_cpu_seconds_total[5m]) > 0.8

# Memory Usage  
expr: (process_resident_memory_bytes / 1024 / 1024) > 500

# Error Rate
expr: rate(quakewatch_errors_total[5m]) > 0.1
```

**Tuned Thresholds** (based on historical data):
```yaml
# CPU Usage (adjusted based on normal usage)
expr: rate(process_cpu_seconds_total[5m]) > 0.9

# Memory Usage (adjusted based on normal usage)
expr: (process_resident_memory_bytes / 1024 / 1024) > 800

# Error Rate (adjusted based on normal error rate)
expr: rate(quakewatch_errors_total[5m]) > 0.05
```

### 2. Timing Adjustment

**Initial Timing**:
```yaml
for: 1m  # Alert after 1 minute
```

**Tuned Timing** (based on alert noise):
```yaml
for: 5m  # Alert after 5 minutes to reduce noise
```

### 3. Grouping and Deduplication

```yaml
route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s      # Wait 10s before sending first alert in group
  group_interval: 10s  # Wait 10s before sending updates
  repeat_interval: 1h  # Repeat alert every hour if not resolved
```

## Alert Maintenance

### 1. Regular Review

**Weekly Tasks**:
- Review alert frequency and noise
- Check for false positives
- Validate alert thresholds
- Update runbook URLs

**Monthly Tasks**:
- Analyze alert trends
- Adjust thresholds based on historical data
- Review and update notification channels
- Test alert scenarios

### 2. Alert Metrics

```promql
# Alert frequency by severity
sum(rate(ALERTS[1h])) by (severity)

# Alert duration
time() - ALERTS{state="firing"}

# Alert noise (frequent alerts)
count(ALERTS{state="firing"}) by (alertname)
```

### 3. Documentation Updates

**Runbook Maintenance**:
- Update runbook URLs in alert annotations
- Create runbooks for new alerts
- Review and update existing runbooks
- Test runbook procedures

## Troubleshooting Alerts

### Common Issues

#### 1. Alerts Not Firing
**Causes**:
- Incorrect expression syntax
- Metrics not available
- Threshold too high
- Timing issues

**Solutions**:
```bash
# Check expression syntax
curl "http://localhost:9090/api/v1/query?query=YOUR_EXPRESSION"

# Verify metrics exist
curl "http://localhost:9090/api/v1/query?query=up{job=\"quakewatch\"}"

# Check alert rules
curl -s 'http://localhost:9090/api/v1/rules' | jq '.data.groups[].rules[]'
```

#### 2. Too Many Alerts
**Causes**:
- Thresholds too low
- No grouping/deduplication
- Short repeat intervals
- No inhibition rules

**Solutions**:
- Adjust thresholds based on historical data
- Implement proper grouping
- Increase repeat intervals
- Add inhibition rules

#### 3. Missing Alerts
**Causes**:
- AlertManager not configured
- Notification channels not working
- Routing rules incorrect
- Receiver configuration issues

**Solutions**:
```bash
# Check AlertManager status
kubectl get pods -n monitoring | grep alertmanager

# Check AlertManager configuration
kubectl get secret alertmanager-main -n monitoring -o yaml

# Test notification channels
curl -X POST http://localhost:5001/test -d '{"test": "message"}'
```

## Best Practices

### 1. Alert Design
- Use meaningful alert names
- Include clear descriptions
- Set appropriate severity levels
- Provide runbook URLs
- Use consistent labeling

### 2. Threshold Setting
- Start with conservative thresholds
- Adjust based on historical data
- Consider seasonal patterns
- Account for maintenance windows
- Use multiple thresholds (warning/critical)

### 3. Notification Management
- Group related alerts
- Use appropriate channels for severity
- Implement escalation procedures
- Provide context in notifications
- Include resolution information

### 4. Maintenance
- Regular review and tuning
- Document alert rationale
- Test alert scenarios
- Update runbooks
- Monitor alert effectiveness

## Conclusion

This alerting configuration provides comprehensive monitoring for the QuakeWatch application and infrastructure. Regular maintenance and tuning ensure optimal alert effectiveness and minimal noise.

For additional alerting examples and configurations, refer to the Prometheus and AlertManager documentation.
