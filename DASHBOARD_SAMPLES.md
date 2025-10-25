# Grafana Dashboard Samples

## Overview

This document provides sample Grafana dashboards and configurations for monitoring the QuakeWatch application and Kubernetes infrastructure.

## Dashboard Categories

### 1. Application Dashboards
- QuakeWatch Application Dashboard
- API Performance Dashboard
- Business Metrics Dashboard

### 2. Infrastructure Dashboards
- Kubernetes Cluster Health
- Node Resource Usage
- Network Performance

### 3. System Dashboards
- System Overview
- Service Status
- Alert Summary

## Sample Dashboard Configurations

### QuakeWatch Application Dashboard

**Purpose**: Monitor QuakeWatch application health, performance, and business metrics

**Key Panels**:
- Request Rate (stat)
- Response Time (graph)
- Error Rate (stat)
- Active Connections (stat)
- Earthquake Processing (stat)
- Request Duration Distribution (histogram)
- Error Types (pie chart)
- API Calls by Type (pie chart)

**Sample Panel Configuration**:
```json
{
  "id": 1,
  "title": "Request Rate",
  "type": "stat",
  "targets": [
    {
      "expr": "rate(quakewatch_requests_total[5m])",
      "legendFormat": "Requests/sec",
      "refId": "A"
    }
  ],
  "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
  "fieldConfig": {
    "defaults": {
      "color": {"mode": "thresholds"},
      "thresholds": {
        "steps": [
          {"color": "green", "value": null},
          {"color": "yellow", "value": 10},
          {"color": "red", "value": 50}
        ]
      }
    }
  }
}
```

**Metrics Used**:
- `quakewatch_requests_total` - Total requests by method/endpoint/status
- `quakewatch_request_duration_seconds` - Request duration histogram
- `quakewatch_errors_total` - Error count by type
- `quakewatch_active_connections` - Current active connections
- `quakewatch_earthquakes_total` - Total earthquakes processed
- `quakewatch_earthquake_magnitude` - Earthquake magnitude distribution

### Kubernetes Cluster Health Dashboard

**Purpose**: Monitor cluster infrastructure, resource usage, and pod health

**Key Panels**:
- Cluster CPU Usage (stat)
- Cluster Memory Usage (stat)
- Pod Count (stat)
- Node Count (stat)
- CPU Usage Over Time (graph)
- Memory Usage Over Time (graph)
- Pod Status Distribution (pie chart)
- Namespace Resource Usage (table)
- Network I/O (graph)
- Disk I/O (graph)
- Container Restarts (stat)
- Storage Usage (stat)

**Sample Panel Configuration**:
```json
{
  "id": 1,
  "title": "Cluster CPU Usage",
  "type": "stat",
  "targets": [
    {
      "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
      "legendFormat": "CPU Usage %",
      "refId": "A"
    }
  ],
  "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "color": {"mode": "thresholds"},
      "thresholds": {
        "steps": [
          {"color": "green", "value": null},
          {"color": "yellow", "value": 70},
          {"color": "red", "value": 90}
        ]
      }
    }
  }
}
```

**Metrics Used**:
- `node_cpu_seconds_total` - CPU usage by node
- `node_memory_MemAvailable_bytes` - Available memory
- `kube_pod_info` - Pod information
- `kube_node_info` - Node information
- `kube_pod_status_phase` - Pod status
- `node_network_receive_bytes_total` - Network receive
- `node_network_transmit_bytes_total` - Network transmit
- `node_disk_read_bytes_total` - Disk read
- `node_disk_written_bytes_total` - Disk write

### System Overview Dashboard

**Purpose**: High-level system health and service status monitoring

**Key Panels**:
- System Health Status (stat)
- Prometheus Status (stat)
- Grafana Status (stat)
- ArgoCD Status (stat)
- Overall System Health (stat)
- Active Services (stat)
- QuakeWatch Request Rate (graph)
- Cluster Resource Usage (graph)
- Service Status Timeline (graph)

**Sample Panel Configuration**:
```json
{
  "id": 1,
  "title": "System Health Status",
  "type": "stat",
  "targets": [
    {
      "expr": "up{job=\"quakewatch\"}",
      "legendFormat": "QuakeWatch Status",
      "refId": "A"
    }
  ],
  "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0},
  "fieldConfig": {
    "defaults": {
      "color": {"mode": "thresholds"},
      "thresholds": {
        "steps": [
          {"color": "red", "value": 0},
          {"color": "green", "value": 1}
        ]
      }
    }
  }
}
```

## Dashboard Import Process

### 1. Manual Import via Grafana UI

1. **Access Grafana**: http://localhost:3000
2. **Login**: admin / prom-operator
3. **Import Dashboard**:
   - Click `+` icon in left sidebar
   - Select `Import`
   - Choose JSON file or paste JSON content
   - Configure data source (should auto-detect Prometheus)
   - Click `Load` → `Import`

### 2. Programmatic Import via API

```bash
# Create dashboard via API
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d @quakewatch-application-dashboard.json \
  http://localhost:3000/api/dashboards/db
```

### 3. Dashboard Configuration via ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: monitoring
data:
  quakewatch-dashboard.json: |
    {
      "dashboard": {
        "title": "QuakeWatch Application Dashboard",
        "panels": [...]
      }
    }
```

## Custom Panel Types

### 1. Stat Panels
**Use Case**: Single value metrics with thresholds
```json
{
  "type": "stat",
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "color": {"mode": "thresholds"},
      "thresholds": {
        "steps": [
          {"color": "green", "value": null},
          {"color": "yellow", "value": 70},
          {"color": "red", "value": 90}
        ]
      }
    }
  }
}
```

### 2. Graph Panels
**Use Case**: Time series data visualization
```json
{
  "type": "graph",
  "yAxes": [
    {
      "label": "Requests/sec",
      "min": 0,
      "unit": "reqps"
    }
  ]
}
```

### 3. Table Panels
**Use Case**: Tabular data display
```json
{
  "type": "table",
  "transformations": [
    {
      "id": "organize",
      "options": {
        "excludeByName": {},
        "indexByName": {},
        "renameByName": {
          "Value #A": "CPU Requests",
          "Value #B": "Memory Requests"
        }
      }
    }
  ]
}
```

### 4. Pie Chart Panels
**Use Case**: Distribution visualization
```json
{
  "type": "piechart",
  "targets": [
    {
      "expr": "count by (phase) (kube_pod_status_phase)",
      "legendFormat": "{{phase}}",
      "refId": "A"
    }
  ]
}
```

## Advanced Dashboard Features

### 1. Variables and Templating

```json
{
  "templating": {
    "list": [
      {
        "name": "namespace",
        "type": "query",
        "query": "label_values(kube_pod_info, namespace)",
        "refresh": 1,
        "includeAll": true,
        "multi": true
      }
    ]
  }
}
```

### 2. Annotations

```json
{
  "annotations": {
    "list": [
      {
        "name": "Deployments",
        "datasource": "Prometheus",
        "expr": "kube_deployment_status_replicas_available",
        "iconColor": "rgba(0, 211, 255, 1)"
      }
    ]
  }
}
```

### 3. Alerting Integration

```json
{
  "alert": {
    "name": "High CPU Usage",
    "message": "CPU usage is above 80%",
    "frequency": "10s",
    "conditions": [
      {
        "evaluator": {
          "params": [80],
          "type": "gt"
        },
        "operator": {
          "type": "and"
        },
        "query": {
          "params": ["A", "5m", "now"]
        },
        "reducer": {
          "params": [],
          "type": "avg"
        },
        "type": "query"
      }
    ]
  }
}
```

## Dashboard Best Practices

### 1. Layout and Organization
- Use consistent panel sizes (6x8, 12x8, 24x8)
- Group related metrics together
- Use descriptive titles and descriptions
- Implement logical flow from top-level to detailed metrics

### 2. Color Coding
- Green: Healthy/Normal
- Yellow: Warning/Attention needed
- Red: Critical/Error
- Blue: Information/Neutral

### 3. Threshold Configuration
```json
"thresholds": {
  "steps": [
    {"color": "green", "value": null},
    {"color": "yellow", "value": 70},
    {"color": "red", "value": 90}
  ]
}
```

### 4. Refresh Rates
- Real-time dashboards: 5s
- Standard dashboards: 30s
- Historical dashboards: 1m
- Executive dashboards: 5m

### 5. Data Source Configuration
```json
{
  "datasource": {
    "type": "prometheus",
    "uid": "prometheus",
    "url": "http://prometheus:9090"
  }
}
```

## Troubleshooting Dashboard Issues

### Common Problems

#### 1. "No Data" in Panels
**Causes**:
- Incorrect metric names
- Wrong time range
- Data source not configured
- Metrics not being collected

**Solutions**:
```bash
# Check if metrics exist
curl "http://localhost:9090/api/v1/query?query=quakewatch_requests_total"

# Verify data source
# Check Grafana data source configuration

# Test query in Prometheus
curl "http://localhost:9090/api/v1/query_range?query=rate(quakewatch_requests_total[5m])&start=2023-01-01T00:00:00Z&end=2023-01-01T01:00:00Z&step=15s"
```

#### 2. Incorrect Values
**Causes**:
- Wrong aggregation functions
- Incorrect time ranges
- Unit conversion issues

**Solutions**:
- Review query syntax
- Check aggregation functions (sum, avg, rate, etc.)
- Verify time ranges and intervals

#### 3. Performance Issues
**Causes**:
- Complex queries
- High refresh rates
- Large time ranges

**Solutions**:
- Optimize queries
- Use recording rules
- Reduce refresh rates
- Limit time ranges

## Dashboard Maintenance

### Regular Tasks
1. **Review Performance**: Check query execution times
2. **Update Thresholds**: Adjust based on historical data
3. **Add New Metrics**: Include new application metrics
4. **Remove Unused Panels**: Clean up obsolete visualizations
5. **Test Queries**: Verify all queries work correctly

### Backup and Version Control
```bash
# Export dashboard
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3000/api/dashboards/uid/QUAKEWATCH_DASHBOARD_UID > quakewatch-dashboard-backup.json

# Version control
git add *.json
git commit -m "Update QuakeWatch dashboard configuration"
git push origin main
```

## Conclusion

These dashboard samples provide a comprehensive foundation for monitoring the QuakeWatch application and infrastructure. Customize them based on your specific requirements and monitoring needs.

For additional dashboard examples and configurations, refer to the Grafana community dashboards and the official Grafana documentation.
