#!/usr/bin/env python3
"""
Simple AlertManager webhook receiver for testing alerts
This script receives alert notifications and logs them to console and file
"""

import json
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from logging.handlers import RotatingFileHandler

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Add file handler for alert logs
file_handler = RotatingFileHandler('alert_logs.log', maxBytes=1000000, backupCount=5)
file_handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

def log_alert(alert_data, alert_type="general"):
    """Log alert data to console and file"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    print(f"\n🚨 ALERT RECEIVED [{alert_type.upper()}] - {timestamp}")
    print("=" * 60)
    
    for alert in alert_data.get('alerts', []):
        status = alert.get('status', 'unknown')
        labels = alert.get('labels', {})
        annotations = alert.get('annotations', {})
        
        print(f"Status: {status}")
        print(f"Alert: {labels.get('alertname', 'Unknown')}")
        print(f"Severity: {labels.get('severity', 'unknown')}")
        print(f"Service: {labels.get('service', 'unknown')}")
        print(f"Summary: {annotations.get('summary', 'No summary')}")
        print(f"Description: {annotations.get('description', 'No description')}")
        print(f"Started: {alert.get('startsAt', 'Unknown')}")
        if alert.get('endsAt'):
            print(f"Ended: {alert.get('endsAt')}")
        print("-" * 60)
        
        # Log to file
        logger.info(f"ALERT [{alert_type}] - {labels.get('alertname')} - {annotations.get('summary')}")

@app.route('/', methods=['POST'])
def receive_alert():
    """Receive general alerts"""
    try:
        alert_data = request.get_json()
        log_alert(alert_data, "general")
        return jsonify({"status": "received"}), 200
    except Exception as e:
        logger.error(f"Error processing alert: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/critical', methods=['POST'])
def receive_critical_alert():
    """Receive critical alerts"""
    try:
        alert_data = request.get_json()
        log_alert(alert_data, "critical")
        return jsonify({"status": "critical alert received"}), 200
    except Exception as e:
        logger.error(f"Error processing critical alert: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/warning', methods=['POST'])
def receive_warning_alert():
    """Receive warning alerts"""
    try:
        alert_data = request.get_json()
        log_alert(alert_data, "warning")
        return jsonify({"status": "warning alert received"}), 200
    except Exception as e:
        logger.error(f"Error processing warning alert: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/quakewatch', methods=['POST'])
def receive_quakewatch_alert():
    """Receive QuakeWatch specific alerts"""
    try:
        alert_data = request.get_json()
        log_alert(alert_data, "quakewatch")
        return jsonify({"status": "quakewatch alert received"}), 200
    except Exception as e:
        logger.error(f"Error processing quakewatch alert: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "alert-webhook-receiver"}), 200

if __name__ == '__main__':
    print("🚨 AlertManager Webhook Receiver Starting...")
    print("📡 Listening for alerts on port 5001")
    print("🔗 Endpoints:")
    print("   - POST / - General alerts")
    print("   - POST /critical - Critical alerts")
    print("   - POST /warning - Warning alerts")
    print("   - POST /quakewatch - QuakeWatch alerts")
    print("   - GET /health - Health check")
    print("📝 Alert logs will be saved to alert_logs.log")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5001, debug=True)
