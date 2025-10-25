"""
Prometheus metrics for QuakeWatch application
"""
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from flask import Response
import time

# Request metrics
REQUEST_COUNT = Counter('quakewatch_requests_total', 'Total number of requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('quakewatch_request_duration_seconds', 'Request duration in seconds', ['method', 'endpoint'])

# Application metrics
ACTIVE_CONNECTIONS = Gauge('quakewatch_active_connections', 'Number of active connections')
DATA_POINTS_PROCESSED = Counter('quakewatch_data_points_processed_total', 'Total number of data points processed')
API_CALLS = Counter('quakewatch_api_calls_total', 'Total number of API calls', ['api_name'])
ERROR_COUNT = Counter('quakewatch_errors_total', 'Total number of errors', ['error_type'])

# Custom metrics for earthquake data
EARTHQUAKE_COUNT = Counter('quakewatch_earthquakes_total', 'Total number of earthquakes processed')
EARTHQUAKE_MAGNITUDE = Histogram('quakewatch_earthquake_magnitude', 'Earthquake magnitude distribution', buckets=[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

def track_request_duration(f):
    """Decorator to track request duration"""
    def decorated_function(*args, **kwargs):
        start_time = time.time()
        try:
            result = f(*args, **kwargs)
            status = 'success'
            return result
        except Exception as e:
            status = 'error'
            raise
        finally:
            duration = time.time() - start_time
            REQUEST_DURATION.labels(method='GET', endpoint=f.__name__).observe(duration)
    return decorated_function

def get_metrics():
    """Return Prometheus metrics"""
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

def increment_request_count(method, endpoint, status):
    """Increment request counter"""
    REQUEST_COUNT.labels(method=method, endpoint=endpoint, status=status).inc()

def increment_api_calls(api_name):
    """Increment API calls counter"""
    API_CALLS.labels(api_name=api_name).inc()

def increment_error_count(error_type):
    """Increment error counter"""
    ERROR_COUNT.labels(error_type=error_type).inc()

def increment_earthquake_count():
    """Increment earthquake counter"""
    EARTHQUAKE_COUNT.inc()

def record_earthquake_magnitude(magnitude):
    """Record earthquake magnitude"""
    EARTHQUAKE_MAGNITUDE.observe(magnitude)

def set_active_connections(count):
    """Set active connections gauge"""
    ACTIVE_CONNECTIONS.set(count)

def increment_data_points_processed(count=1):
    """Increment data points processed counter"""
    DATA_POINTS_PROCESSED.inc(count)
