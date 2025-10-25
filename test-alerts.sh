#!/bin/bash

# Alert Testing Script for QuakeWatch Monitoring
# This script helps you test the alerting system

echo "🚨 QuakeWatch Alert Testing Script"
echo "=================================="
echo ""

# Check if services are running
echo "📊 Checking service status..."
echo "----------------------------"

# Check Prometheus
if curl -s http://localhost:9090/api/v1/query?query=up > /dev/null; then
    echo "✅ Prometheus: Running"
else
    echo "❌ Prometheus: Not accessible"
fi

# Check Grafana
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Grafana: Running"
else
    echo "❌ Grafana: Not accessible"
fi

# Check QuakeWatch
if curl -s http://localhost:8080/metrics > /dev/null; then
    echo "✅ QuakeWatch: Running"
else
    echo "❌ QuakeWatch: Not accessible"
fi

echo ""
echo "🔍 Checking alert rules..."
echo "-------------------------"

# Check if alert rules are loaded
ALERT_RULES=$(curl -s "http://localhost:9090/api/v1/rules" | jq '.data.groups | length' 2>/dev/null)
if [ "$ALERT_RULES" -gt 0 ]; then
    echo "✅ Alert rules loaded: $ALERT_RULES rule groups"
else
    echo "❌ No alert rules found"
fi

echo ""
echo "📋 Available Alert Rules:"
echo "-------------------------"

# List alert rules
curl -s "http://localhost:9090/api/v1/rules" | jq -r '.data.groups[].rules[] | select(.type=="alerting") | .alert' 2>/dev/null | head -10

echo ""
echo "🧪 Alert Testing Commands:"
echo "-------------------------"
echo ""
echo "1. Test QuakeWatch Down Alert:"
echo "   kubectl scale deployment quakewatch --replicas=0 -n quakewatch"
echo "   # Wait 2 minutes, then scale back:"
echo "   kubectl scale deployment quakewatch --replicas=1 -n quakewatch"
echo ""
echo "2. Test High CPU Alert:"
echo "   # Generate CPU load (run in background):"
echo "   yes > /dev/null &"
echo "   # Stop with: pkill yes"
echo ""
echo "3. Test High Memory Alert:"
echo "   # Generate memory load:"
echo "   python3 -c \"import time; [time.sleep(0.1) for _ in range(1000000)]\" &"
echo ""
echo "4. View Active Alerts:"
echo "   curl -s 'http://localhost:9090/api/v1/alerts' | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state, severity: .labels.severity}'"
echo ""
echo "5. Start Alert Webhook Receiver:"
echo "   python3 alert-webhook-receiver.py"
echo ""
echo "6. View Alert Logs:"
echo "   tail -f alert_logs.log"
echo ""
echo "🔗 Access URLs:"
echo "-------------"
echo "• Prometheus: http://localhost:9090"
echo "• Grafana: http://localhost:3000"
echo "• QuakeWatch: http://localhost:8080"
echo "• AlertManager: http://localhost:9093"
echo ""
echo "📊 Alert Severity Levels:"
echo "-----------------------"
echo "🔴 Critical: Service down, system failures"
echo "🟡 Warning: High resource usage, performance issues"
echo "🔵 Info: High volume, informational alerts"
echo ""
echo "🎯 Next Steps:"
echo "-------------"
echo "1. Start the webhook receiver: python3 alert-webhook-receiver.py"
echo "2. Test alerts using the commands above"
echo "3. Check Prometheus alerts: http://localhost:9090/alerts"
echo "4. Configure email/Slack notifications in AlertManager"
