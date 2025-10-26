# QuakeWatch Monitoring Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation & Setup](#installation--setup)
4. [Prometheus Configuration](#prometheus-configuration)
5. [Grafana Dashboards](#grafana-dashboards)
6. [Alerting System](#alerting-system)
7. [Sample Configurations](#sample-configurations)
8. [Troubleshooting](#troubleshooting)
9. [Maintenance](#maintenance)

## Overview

This document provides comprehensive documentation for the QuakeWatch monitoring stack, including Prometheus metrics collection, Grafana visualization, and AlertManager notification system.

### Monitoring Stack Components
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **AlertManager**: Alert routing and notifications
- **QuakeWatch Application**: Custom metrics endpoint
- **Kubernetes**: Cluster and pod monitoring

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   QuakeWatch    │    │   Kubernetes    │    │   Node          │
│   Application   │───▶│   Cluster       │───▶│   Exporter      │
│   (/metrics)    │    │   (kube-state)  │    │   (cAdvisor)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────────────┐
                    │      Prometheus         │
                    │   (Metrics Storage)     │
                    └─────────────────────────┘
                                 │
                    ┌────────────┼────────────┐
                    ▼            ▼            ▼
            ┌─────────────┐ ┌─────────┐ ┌─────────────┐
            │   Grafana   │ │AlertMgr │ │  Webhooks   │
            │(Dashboards) │ │(Alerts) │ │(Notifications)│
            └─────────────┘ └─────────┘ └─────────────┘
```

## Installation & Setup

### Prerequisites
- Kubernetes cluster (minikube, GKE, EKS, etc.)
- kubectl configured
- Helm 3.x installed

### 1. Install Prometheus Stack

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install kube-prometheus-stack
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false
```

### 2. Configure QuakeWatch Metrics

#### Application Metrics Endpoint
The QuakeWatch application exposes metrics at `/metrics` endpoint:

```python
# metrics.py - Custom Prometheus metrics
from prometheus_client import Counter, Histogram, Gauge, generate_latest

# Request metrics
REQUEST_COUNT = Counter('quakewatch_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('quakewatch_request_duration_seconds', 'Request duration', ['method', 'endpoint'])

# Application metrics
ACTIVE_CONNECTIONS = Gauge('quakewatch_active_connections', 'Active connections')
EARTHQUAKE_COUNT = Counter('quakewatch_earthquakes_total', 'Total earthquakes processed')
```

#### ServiceMonitor Configuration
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: quakewatch
  namespace: quakewatch
  labels:
    release: monitoring
spec:
  selector:
    matchLabels:
      app: quakewatch
  endpoints:
    - port: http
      path: /metrics
      interval: 15s
```

### 3. Access Services

```bash
# Port forwarding for local access
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 &
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 &
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093 &
kubectl port-forward -n quakewatch svc/quakewatch 8080:80 &
```

**Access URLs:**
- Grafana: http://localhost:3000 (admin/prom-operator)
- Prometheus: http://localhost:9090
- AlertManager: http://localhost:9093
- QuakeWatch: http://localhost:8080

## Prometheus Configuration

### Data Sources
Prometheus automatically discovers and scrapes:
- QuakeWatch application metrics
- Kubernetes cluster metrics
- Node exporter metrics
- cAdvisor container metrics
- kube-state-metrics

### Scrape Configuration
```yaml
scrape_configs:
  - job_name: 'quakewatch'
    static_configs:
      - targets: ['quakewatch.quakewatch.svc.cluster.local:80']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

### Recording Rules
```yaml
groups:
- name: quakewatch.rules
  rules:
  - record: quakewatch:request_rate
    expr: rate(quakewatch_requests_total[5m])
  - record: quakewatch:error_rate
    expr: rate(quakewatch_errors_total[5m])
```

## Grafana Dashboards

### 1. QuakeWatch Application Dashboard

**Purpose**: Monitor QuakeWatch application health and performance

**Key Metrics:**
- Request rate and duration
- Error rates and types
- Earthquake processing statistics
- Active connections
- API call analytics

**Dashboard Features:**
- Real-time metrics visualization
- Historical trend analysis
- Performance threshold indicators
- Custom alerting integration

### 2. Kubernetes Cluster Health Dashboard

**Purpose**: Monitor cluster infrastructure and resource usage

**Key Metrics:**
- CPU and Memory usage across nodes
- Pod status distribution
- Network and Disk I/O
- Container restart tracking
- Storage usage monitoring

**Dashboard Features:**
- Multi-node resource comparison
- Pod lifecycle tracking
- Storage capacity monitoring
- Network performance metrics

### 3. System Overview Dashboard

**Purpose**: High-level system health and service status

**Key Metrics:**
- Service availability status
- Overall system health percentage
- Resource usage trends
- Service status timeline

**Dashboard Features:**
- Service status indicators
- Health score calculation
- Trend analysis
- Quick issue identification

### Dashboard Import Process

1. **Access Grafana**: http://localhost:3000
2. **Login**: admin / prom-operator
3. **Import Dashboard**:
   - Click `+` → `Import`
   - Upload JSON files:
     - `quakewatch-application-dashboard.json`
     - `cluster-health-dashboard.json`
     - `system-overview-dashboard.json`
   - Click `Load` → `Import`

## Alerting System

### Alert Categories

#### Critical Alerts
- **QuakeWatchDown**: Application is down
- **KubernetesPodCrashLooping**: Pod crash loops
- **KubernetesNodeDown**: Node is down
- **KubernetesDiskSpaceLow**: Low disk space
- **PrometheusDown**: Prometheus is down

#### Warning Alerts
- **QuakeWatchHighErrorRate**: High error rate
- **QuakeWatchHighResponseTime**: Slow responses
- **KubernetesHighCPUUsage**: High CPU usage
- **KubernetesHighMemoryUsage**: High memory usage
- **KubernetesPodNotReady**: Pod not ready

#### Info Alerts
- **QuakeWatchHighEarthquakeVolume**: High earthquake volume
- **QuakeWatchDataProcessingStopped**: Data processing stopped

### Alert Configuration

#### Alert Rules
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
```

#### AlertManager Routing
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
    repeat_interval: 5m
```

### Notification Channels

#### Webhook Receiver
```python
@app.route('/critical', methods=['POST'])
def receive_critical_alert():
    alert_data = request.get_json()
    log_alert(alert_data, "critical")
    return jsonify({"status": "received"}), 200
```

#### Email Configuration
```yaml
receivers:
- name: 'critical-alerts'
  email_configs:
  - to: 'admin@quakewatch.local'
    subject: 'CRITICAL ALERT: {{ .GroupLabels.alertname }}'
    body: |
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
```

## Sample Configurations

### 1. ServiceMonitor for Custom Application

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: custom-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: custom-app
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
```

### 2. PrometheusRule for Custom Alerts

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-alerts
  namespace: monitoring
spec:
  groups:
  - name: custom.rules
    rules:
    - alert: CustomAppDown
      expr: up{job="custom-app"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Custom application is down"
```

### 3. Grafana Dashboard JSON

```json
{
  "dashboard": {
    "title": "Custom Dashboard",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(requests_total[5m])",
            "legendFormat": "Requests/sec"
          }
        ]
      }
    ]
  }
}
```

## Troubleshooting

### Common Issues

#### 1. Metrics Not Appearing
**Symptoms**: No metrics in Prometheus or Grafana
**Solutions**:
```bash
# Check if ServiceMonitor is applied
kubectl get servicemonitor -n quakewatch

# Verify metrics endpoint
curl http://localhost:8080/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
```

#### 2. Alerts Not Firing
**Symptoms**: Alerts configured but not triggering
**Solutions**:
```bash
# Check alert rules
curl http://localhost:9090/api/v1/rules

# Verify AlertManager configuration
kubectl get secret alertmanager-main -n monitoring -o yaml

# Test alert expression
curl "http://localhost:9090/api/v1/query?query=up{job=\"quakewatch\"}"
```

#### 3. Grafana Dashboard Issues
**Symptoms**: Dashboard shows "No Data"
**Solutions**:
- Verify Prometheus data source
- Check time range settings
- Validate metric names and labels
- Ensure metrics are being collected

### Debugging Commands

```bash
# Check Prometheus status
kubectl get pods -n monitoring | grep prometheus

# View Prometheus logs
kubectl logs -n monitoring deployment/monitoring-kube-prometheus-prometheus

# Check AlertManager status
kubectl get pods -n monitoring | grep alertmanager

# View Grafana logs
kubectl logs -n monitoring deployment/monitoring-grafana

# Test metrics endpoint
curl -s http://localhost:8080/metrics | head -20

# Check active alerts
curl -s 'http://localhost:9090/api/v1/alerts' | jq '.data.alerts[]'
```

## Maintenance

### Regular Tasks

#### 1. Dashboard Updates
- Review dashboard performance monthly
- Update alert thresholds based on historical data
- Add new metrics as application evolves

#### 2. Alert Tuning
- Review alert frequency and adjust thresholds
- Update notification channels as needed
- Test alert scenarios regularly

#### 3. Storage Management
- Monitor Prometheus storage usage
- Configure retention policies
- Clean up old metrics data

### Backup and Recovery

#### 1. Configuration Backup
```bash
# Backup Prometheus rules
kubectl get prometheusrule -n monitoring -o yaml > prometheus-rules-backup.yaml

# Backup AlertManager config
kubectl get secret alertmanager-main -n monitoring -o yaml > alertmanager-config-backup.yaml

# Backup Grafana dashboards
# Export from Grafana UI or use API
```

#### 2. Data Backup
```bash
# Backup Prometheus data (if using persistent storage)
kubectl exec -n monitoring prometheus-0 -- tar -czf /tmp/prometheus-data.tar.gz /prometheus
kubectl cp monitoring/prometheus-0:/tmp/prometheus-data.tar.gz ./prometheus-data-backup.tar.gz
```

### Performance Optimization

#### 1. Prometheus Optimization
- Configure appropriate scrape intervals
- Use recording rules for complex queries
- Implement metric relabeling for efficiency

#### 2. Grafana Optimization
- Limit dashboard refresh rates
- Use data source caching
- Optimize query performance

### Security Considerations

#### 1. Access Control
- Implement RBAC for Prometheus and Grafana
- Use network policies for service isolation
- Enable authentication and authorization

#### 2. Data Privacy
- Avoid collecting sensitive data in metrics
- Implement data retention policies
- Use secure communication channels

## Conclusion

This monitoring setup provides comprehensive observability for the QuakeWatch application and Kubernetes infrastructure. Regular maintenance and updates ensure optimal performance and reliability.

For additional support or questions, refer to:
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kubernetes Monitoring Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)
