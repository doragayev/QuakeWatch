# QuakeWatch Monitoring Documentation

## 📚 Documentation Index

This repository contains comprehensive documentation for the QuakeWatch monitoring stack, including Prometheus, Grafana, and AlertManager configurations.

### 📖 Documentation Files

| Document | Description | Purpose |
|----------|-------------|---------|
| **[MONITORING_DOCUMENTATION.md](./MONITORING_DOCUMENTATION.md)** | Main documentation | Complete setup guide, architecture, and configuration |
| **[DASHBOARD_SAMPLES.md](./DASHBOARD_SAMPLES.md)** | Dashboard examples | Sample dashboards, configurations, and best practices |
| **[ALERTING_GUIDE.md](./ALERTING_GUIDE.md)** | Alerting configuration | Alert rules, notification channels, and testing |
| **[TROUBLESHOOTING_GUIDE.md](./TROUBLESHOOTING_GUIDE.md)** | Troubleshooting procedures | Common issues, maintenance, and optimization |

### 🚀 Quick Start

#### 1. Access Your Monitoring Stack
```bash
# Start port forwarding
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 &
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 &
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093 &
kubectl port-forward -n quakewatch svc/quakewatch 8080:80 &
```

#### 2. Access URLs
- **Grafana**: http://localhost:3000 (admin/prom-operator)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093
- **QuakeWatch**: http://localhost:8080
- **QuakeWatch Metrics**: http://localhost:8080/metrics

#### 3. Import Dashboards
1. Open Grafana → http://localhost:3000
2. Login with admin/prom-operator
3. Click `+` → `Import`
4. Upload JSON files:
   - `quakewatch-application-dashboard.json`
   - `cluster-health-dashboard.json`
   - `system-overview-dashboard.json`

### 📊 Dashboard Files

| Dashboard | File | Description |
|-----------|------|-------------|
| **QuakeWatch Application** | `quakewatch-application-dashboard.json` | Application metrics, performance, and business KPIs |
| **Cluster Health** | `cluster-health-dashboard.json` | Kubernetes infrastructure and resource monitoring |
| **System Overview** | `system-overview-dashboard.json` | High-level system health and service status |

### 🚨 Alerting Files

| File | Description |
|------|-------------|
| `prometheus-alerts.yaml` | Prometheus alert rules for QuakeWatch and Kubernetes |
| `alertmanager-config.yaml` | AlertManager routing and notification configuration |
| `alert-webhook-receiver.py` | Webhook receiver for testing alerts |
| `test-alerts.sh` | Alert testing and validation script |

### 🛠️ Configuration Files

| File | Description |
|------|-------------|
| `k8s/monitoring-servicemonitor.yaml` | ServiceMonitor for QuakeWatch metrics |
| `metrics.py` | Custom Prometheus metrics for QuakeWatch |
| `import-dashboards.sh` | Dashboard import helper script |

### 📋 Quick Commands

#### Health Checks
```bash
# Check all services
./test-alerts.sh

# Check metrics endpoint
curl http://localhost:8080/metrics

# Check active alerts
curl -s 'http://localhost:9090/api/v1/alerts' | jq '.data.alerts[]'

# Start alert webhook receiver
python3 alert-webhook-receiver.py
```

#### Maintenance
```bash
# Backup configurations
kubectl get prometheusrule -n monitoring -o yaml > prometheus-rules-backup.yaml
kubectl get secret alertmanager-main -n monitoring -o yaml > alertmanager-config-backup.yaml

# Restart services if needed
kubectl rollout restart deployment/quakewatch -n quakewatch
kubectl rollout restart deployment/monitoring-grafana -n monitoring
```

### 🎯 Key Features

#### ✅ **Application Monitoring**
- Request rates and response times
- Error tracking and success rates
- Earthquake processing statistics
- API call analytics
- Custom business metrics

#### ✅ **Infrastructure Monitoring**
- CPU and Memory usage across nodes
- Pod status and distribution
- Network and Disk I/O metrics
- Container restart tracking
- Storage usage monitoring

#### ✅ **Alerting System**
- Critical alerts for service failures
- Warning alerts for performance issues
- Info alerts for business metrics
- Multiple notification channels
- Smart grouping and deduplication

#### ✅ **Visualization**
- Real-time dashboards
- Historical trend analysis
- Performance threshold indicators
- Custom alerting integration
- Multi-service overview

### 🔧 Troubleshooting

#### Common Issues
1. **Services not accessible**: Check port forwarding and pod status
2. **No metrics**: Verify ServiceMonitor and metrics endpoint
3. **Dashboard shows "No Data"**: Check data source and time range
4. **Alerts not firing**: Verify alert rules and expressions

#### Quick Fixes
```bash
# Restart port forwarding
pkill -f "kubectl port-forward"
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 &

# Check service status
kubectl get pods -n monitoring
kubectl get pods -n quakewatch

# Test metrics
curl http://localhost:8080/metrics | head -10
```

### 📈 Monitoring Metrics

#### QuakeWatch Application Metrics
- `quakewatch_requests_total` - Total requests by method/endpoint/status
- `quakewatch_request_duration_seconds` - Request duration histogram
- `quakewatch_errors_total` - Error count by type
- `quakewatch_active_connections` - Current active connections
- `quakewatch_earthquakes_total` - Total earthquakes processed
- `quakewatch_earthquake_magnitude` - Earthquake magnitude distribution

#### Kubernetes Metrics
- `kube_pod_status_phase` - Pod status
- `kube_node_info` - Node information
- `node_cpu_seconds_total` - CPU usage
- `node_memory_MemAvailable_bytes` - Memory usage
- `kube_pod_container_status_restarts_total` - Container restarts

### 🚨 Alert Categories

#### Critical Alerts
- QuakeWatchDown
- KubernetesPodCrashLooping
- KubernetesNodeDown
- KubernetesDiskSpaceLow
- PrometheusDown

#### Warning Alerts
- QuakeWatchHighErrorRate
- QuakeWatchHighResponseTime
- KubernetesHighCPUUsage
- KubernetesHighMemoryUsage
- KubernetesPodNotReady

#### Info Alerts
- QuakeWatchHighEarthquakeVolume
- QuakeWatchDataProcessingStopped
- QuakeWatchAPICallFailure

### 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kubernetes Monitoring Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)
- [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)

### 🤝 Support

For issues or questions:
1. Check the troubleshooting guide
2. Review service logs
3. Test individual components
4. Refer to official documentation

### 📝 Maintenance Schedule

#### Daily
- Health checks
- Log review
- Service status verification

#### Weekly
- Dashboard performance review
- Alert tuning
- Storage management

#### Monthly
- Performance analysis
- Configuration updates
- Backup and recovery testing

---

**Last Updated**: October 2025  
**Version**: 1.0  
**Maintainer**: QuakeWatch Team
