# Troubleshooting and Maintenance Guide

## Overview

This guide provides comprehensive troubleshooting procedures and maintenance tasks for the QuakeWatch monitoring stack, including Prometheus, Grafana, AlertManager, and the QuakeWatch application.

## Quick Reference

### Service URLs
- **Grafana**: http://localhost:3000 (admin/prom-operator)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093
- **QuakeWatch**: http://localhost:8080
- **QuakeWatch Metrics**: http://localhost:8080/metrics

### Port Forwarding Commands
```bash
# Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 &

# Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 &

# AlertManager
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093 &

# QuakeWatch
kubectl port-forward -n quakewatch svc/quakewatch 8080:80 &
```

## Common Issues and Solutions

### 1. Service Access Issues

#### Problem: Cannot access Grafana/Prometheus/AlertManager
**Symptoms**:
- Connection refused errors
- Timeout errors
- 404 Not Found errors

**Diagnosis**:
```bash
# Check if services are running
kubectl get pods -n monitoring

# Check service endpoints
kubectl get svc -n monitoring

# Check port forwarding
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 &
```

**Solutions**:
1. **Restart port forwarding**:
   ```bash
   pkill -f "kubectl port-forward"
   kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 &
   ```

2. **Check service status**:
   ```bash
   kubectl get pods -n monitoring | grep -E "(grafana|prometheus|alertmanager)"
   ```

3. **Restart services if needed**:
   ```bash
   kubectl rollout restart deployment/monitoring-grafana -n monitoring
   kubectl rollout restart statefulset/monitoring-kube-prometheus-prometheus -n monitoring
   ```

#### Problem: QuakeWatch not accessible
**Symptoms**:
- Connection refused to localhost:8080
- 404 errors from QuakeWatch

**Diagnosis**:
```bash
# Check QuakeWatch pod status
kubectl get pods -n quakewatch

# Check QuakeWatch service
kubectl get svc -n quakewatch

# Check QuakeWatch logs
kubectl logs -n quakewatch deployment/quakewatch
```

**Solutions**:
1. **Restart QuakeWatch**:
   ```bash
   kubectl rollout restart deployment/quakewatch -n quakewatch
   ```

2. **Check port forwarding**:
   ```bash
   kubectl port-forward -n quakewatch svc/quakewatch 8080:80 &
   ```

3. **Verify image**:
   ```bash
   kubectl describe pod -n quakewatch -l app=quakewatch | grep Image
   ```

### 2. Metrics Collection Issues

#### Problem: No metrics in Prometheus
**Symptoms**:
- Empty metrics in Prometheus UI
- "No data" in Grafana dashboards
- Missing QuakeWatch metrics

**Diagnosis**:
```bash
# Check if metrics endpoint is working
curl http://localhost:8080/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check ServiceMonitor
kubectl get servicemonitor -n quakewatch
```

**Solutions**:
1. **Verify metrics endpoint**:
   ```bash
   curl -s http://localhost:8080/metrics | head -10
   ```

2. **Check ServiceMonitor configuration**:
   ```bash
   kubectl get servicemonitor quakewatch -n quakewatch -o yaml
   ```

3. **Restart Prometheus**:
   ```bash
   kubectl rollout restart statefulset/monitoring-kube-prometheus-prometheus -n monitoring
   ```

4. **Check Prometheus configuration**:
   ```bash
   kubectl get configmap -n monitoring | grep prometheus
   ```

#### Problem: Incorrect metrics values
**Symptoms**:
- Wrong values in dashboards
- Missing labels
- Incorrect aggregations

**Diagnosis**:
```bash
# Test specific metric query
curl "http://localhost:9090/api/v1/query?query=quakewatch_requests_total"

# Check metric labels
curl "http://localhost:9090/api/v1/query?query=quakewatch_requests_total[5m]"
```

**Solutions**:
1. **Verify metric names**:
   ```bash
   curl -s http://localhost:8080/metrics | grep quakewatch
   ```

2. **Check query syntax**:
   ```bash
   curl "http://localhost:9090/api/v1/query?query=rate(quakewatch_requests_total[5m])"
   ```

3. **Validate time ranges**:
   ```bash
   curl "http://localhost:9090/api/v1/query_range?query=quakewatch_requests_total&start=2023-01-01T00:00:00Z&end=2023-01-01T01:00:00Z&step=15s"
   ```

### 3. Dashboard Issues

#### Problem: "No Data" in Grafana dashboards
**Symptoms**:
- Empty panels in Grafana
- "No data" messages
- Missing time series

**Diagnosis**:
```bash
# Check data source configuration
# In Grafana: Configuration → Data Sources → Prometheus

# Test query in Prometheus
curl "http://localhost:9090/api/v1/query?query=up{job=\"quakewatch\"}"

# Check time range in Grafana
# In Grafana: Check time picker in top right
```

**Solutions**:
1. **Verify data source**:
   - Go to Grafana → Configuration → Data Sources
   - Check Prometheus URL: http://prometheus:9090
   - Test connection

2. **Check time range**:
   - Ensure time range includes data
   - Check for data in Prometheus first

3. **Validate queries**:
   - Test queries in Prometheus UI
   - Check for typos in metric names
   - Verify label values

#### Problem: Slow dashboard loading
**Symptoms**:
- Long loading times
- Timeout errors
- Poor performance

**Diagnosis**:
```bash
# Check Prometheus performance
curl "http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_series"

# Check query execution time
curl "http://localhost:9090/api/v1/query?query=rate(quakewatch_requests_total[1h])"
```

**Solutions**:
1. **Optimize queries**:
   - Use recording rules for complex queries
   - Reduce time ranges
   - Limit label selectors

2. **Adjust refresh rates**:
   - Increase dashboard refresh intervals
   - Use 30s or 1m instead of 5s

3. **Check resource usage**:
   ```bash
   kubectl top pods -n monitoring
   ```

### 4. Alerting Issues

#### Problem: Alerts not firing
**Symptoms**:
- No alerts in Prometheus
- Missing alert rules
- Alerts not triggering

**Diagnosis**:
```bash
# Check alert rules
curl -s 'http://localhost:9090/api/v1/rules' | jq '.data.groups[].rules[]'

# Check active alerts
curl -s 'http://localhost:9090/api/v1/alerts' | jq '.data.alerts[]'

# Test alert expression
curl "http://localhost:9090/api/v1/query?query=up{job=\"quakewatch\"}"
```

**Solutions**:
1. **Verify alert rules**:
   ```bash
   kubectl get prometheusrule -n monitoring
   kubectl describe prometheusrule quakewatch-alerts -n monitoring
   ```

2. **Check alert expressions**:
   ```bash
   curl "http://localhost:9090/api/v1/query?query=YOUR_ALERT_EXPRESSION"
   ```

3. **Test alert manually**:
   ```bash
   # Scale down QuakeWatch to trigger alert
   kubectl scale deployment quakewatch --replicas=0 -n quakewatch
   # Wait 2 minutes, then scale back
   kubectl scale deployment quakewatch --replicas=1 -n quakewatch
   ```

#### Problem: Too many alerts
**Symptoms**:
- Alert spam
- Frequent notifications
- Noise in alert channels

**Solutions**:
1. **Adjust thresholds**:
   ```yaml
   # Increase thresholds based on historical data
   expr: rate(quakewatch_errors_total[5m]) > 0.5  # Instead of 0.1
   ```

2. **Increase timing**:
   ```yaml
   for: 5m  # Instead of 1m
   ```

3. **Implement grouping**:
   ```yaml
   route:
     group_by: ['alertname', 'cluster', 'service']
     group_wait: 30s
     group_interval: 30s
     repeat_interval: 1h
   ```

#### Problem: Alerts not reaching notification channels
**Symptoms**:
- Alerts fire but no notifications
- Missing emails/Slack messages
- Webhook failures

**Diagnosis**:
```bash
# Check AlertManager status
kubectl get pods -n monitoring | grep alertmanager

# Check AlertManager configuration
kubectl get secret alertmanager-main -n monitoring -o yaml

# Check AlertManager logs
kubectl logs -n monitoring deployment/monitoring-kube-prometheus-alertmanager
```

**Solutions**:
1. **Verify AlertManager configuration**:
   ```bash
   kubectl get secret alertmanager-main -n monitoring -o yaml
   ```

2. **Test notification channels**:
   ```bash
   # Test webhook
   curl -X POST http://localhost:5001/test -d '{"test": "message"}'
   ```

3. **Check routing rules**:
   ```bash
   # Access AlertManager UI: http://localhost:9093
   # Check Status → Configuration
   ```

## Maintenance Procedures

### Daily Tasks

#### 1. Health Checks
```bash
#!/bin/bash
# daily-health-check.sh

echo "=== Daily Health Check ==="
echo "Date: $(date)"
echo ""

# Check service status
echo "1. Service Status:"
kubectl get pods -n monitoring | grep -E "(grafana|prometheus|alertmanager)"
kubectl get pods -n quakewatch

# Check metrics collection
echo ""
echo "2. Metrics Collection:"
curl -s http://localhost:8080/metrics | grep quakewatch_requests_total | head -1

# Check active alerts
echo ""
echo "3. Active Alerts:"
curl -s 'http://localhost:9090/api/v1/alerts' | jq '.data.alerts | length'

# Check resource usage
echo ""
echo "4. Resource Usage:"
kubectl top pods -n monitoring
kubectl top pods -n quakewatch
```

#### 2. Log Review
```bash
# Check for errors in logs
kubectl logs -n monitoring deployment/monitoring-grafana --since=24h | grep -i error
kubectl logs -n monitoring deployment/monitoring-kube-prometheus-prometheus --since=24h | grep -i error
kubectl logs -n quakewatch deployment/quakewatch --since=24h | grep -i error
```

### Weekly Tasks

#### 1. Dashboard Review
- Check dashboard performance
- Review query execution times
- Update thresholds based on trends
- Add new metrics if needed

#### 2. Alert Tuning
```bash
# Review alert frequency
curl -s 'http://localhost:9090/api/v1/alerts' | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state, severity: .labels.severity}'

# Check alert noise
curl -s 'http://localhost:9090/api/v1/query?query=count(ALERTS{state="firing"}) by (alertname)'
```

#### 3. Storage Management
```bash
# Check Prometheus storage usage
kubectl exec -n monitoring prometheus-0 -- df -h /prometheus

# Check retention settings
curl -s 'http://localhost:9090/api/v1/status/config' | jq '.data.storage.tsdb.retention'
```

### Monthly Tasks

#### 1. Performance Analysis
```bash
# Analyze query performance
curl -s 'http://localhost:9090/api/v1/query?query=prometheus_engine_query_duration_seconds'

# Check storage growth
kubectl exec -n monitoring prometheus-0 -- du -sh /prometheus
```

#### 2. Configuration Updates
- Review and update alert thresholds
- Update dashboard configurations
- Review and update notification channels
- Update runbook URLs

#### 3. Backup and Recovery
```bash
# Backup Prometheus rules
kubectl get prometheusrule -n monitoring -o yaml > prometheus-rules-backup-$(date +%Y%m%d).yaml

# Backup AlertManager configuration
kubectl get secret alertmanager-main -n monitoring -o yaml > alertmanager-config-backup-$(date +%Y%m%d).yaml

# Backup Grafana dashboards (via API)
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3000/api/dashboards/uid/QUAKEWATCH_DASHBOARD_UID > quakewatch-dashboard-backup-$(date +%Y%m%d).json
```

## Performance Optimization

### 1. Prometheus Optimization

#### Recording Rules
```yaml
groups:
- name: quakewatch.rules
  rules:
  - record: quakewatch:request_rate
    expr: rate(quakewatch_requests_total[5m])
  - record: quakewatch:error_rate
    expr: rate(quakewatch_errors_total[5m])
  - record: quakewatch:response_time_p95
    expr: histogram_quantile(0.95, rate(quakewatch_request_duration_seconds_bucket[5m]))
```

#### Scrape Configuration
```yaml
scrape_configs:
  - job_name: 'quakewatch'
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: '/metrics'
    static_configs:
      - targets: ['quakewatch.quakewatch.svc.cluster.local:80']
```

### 2. Grafana Optimization

#### Dashboard Performance
- Use appropriate refresh rates (30s for most dashboards)
- Limit time ranges for complex queries
- Use data source caching
- Optimize query performance

#### Query Optimization
```promql
# Instead of complex queries in dashboards
rate(quakewatch_requests_total[5m])

# Use recording rules
quakewatch:request_rate
```

### 3. Resource Management

#### Resource Limits
```yaml
resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi
```

#### Storage Management
```yaml
# Prometheus storage configuration
storage:
  tsdb:
    retention: 15d
    retentionSize: 10GB
```

## Security Considerations

### 1. Access Control
```yaml
# RBAC for Prometheus
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
```

### 2. Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: prometheus-netpol
  namespace: monitoring
spec:
  podSelector:
    matchLabels:
      app: prometheus
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
```

### 3. Data Privacy
- Avoid collecting sensitive data in metrics
- Implement data retention policies
- Use secure communication channels
- Regular security audits

## Backup and Recovery

### 1. Configuration Backup
```bash
#!/bin/bash
# backup-monitoring-config.sh

BACKUP_DIR="/backup/monitoring-$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup Prometheus rules
kubectl get prometheusrule -n monitoring -o yaml > $BACKUP_DIR/prometheus-rules.yaml

# Backup AlertManager config
kubectl get secret alertmanager-main -n monitoring -o yaml > $BACKUP_DIR/alertmanager-config.yaml

# Backup ServiceMonitors
kubectl get servicemonitor -n quakewatch -o yaml > $BACKUP_DIR/servicemonitors.yaml

# Backup Grafana dashboards
curl -H "Authorization: Bearer $GRAFANA_API_KEY" \
  http://localhost:3000/api/dashboards/home > $BACKUP_DIR/grafana-dashboards.json

echo "Backup completed: $BACKUP_DIR"
```

### 2. Data Backup
```bash
# Backup Prometheus data
kubectl exec -n monitoring prometheus-0 -- tar -czf /tmp/prometheus-data.tar.gz /prometheus
kubectl cp monitoring/prometheus-0:/tmp/prometheus-data.tar.gz ./prometheus-data-backup.tar.gz
```

### 3. Recovery Procedures
```bash
# Restore Prometheus rules
kubectl apply -f prometheus-rules-backup.yaml

# Restore AlertManager config
kubectl apply -f alertmanager-config-backup.yaml

# Restore Grafana dashboards
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GRAFANA_API_KEY" \
  -d @grafana-dashboards-backup.json \
  http://localhost:3000/api/dashboards/db
```

## Monitoring the Monitoring

### 1. Self-Monitoring
```yaml
# Monitor Prometheus itself
- alert: PrometheusDown
  expr: up{job="prometheus"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Prometheus is down"

- alert: PrometheusHighMemoryUsage
  expr: process_resident_memory_bytes{job="prometheus"} > 2e9
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Prometheus high memory usage"
```

### 2. Health Checks
```bash
# Automated health check script
#!/bin/bash
# monitoring-health-check.sh

# Check all services
SERVICES=("grafana:3000" "prometheus:9090" "alertmanager:9093" "quakewatch:8080")

for service in "${SERVICES[@]}"; do
  name=$(echo $service | cut -d: -f1)
  port=$(echo $service | cut -d: -f2)
  
  if curl -s http://localhost:$port > /dev/null; then
    echo "✅ $name: Healthy"
  else
    echo "❌ $name: Unhealthy"
    # Send alert notification
  fi
done
```

## Conclusion

This troubleshooting guide provides comprehensive procedures for maintaining and troubleshooting the QuakeWatch monitoring stack. Regular maintenance and proactive monitoring ensure optimal performance and reliability.

For additional support:
- Check service logs for detailed error information
- Use Prometheus and Grafana UIs for investigation
- Refer to official documentation for advanced troubleshooting
- Implement automated health checks and monitoring
