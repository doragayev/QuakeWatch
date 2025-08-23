![Screenshot of QuakeWatch](static/experts-logo.svg)

# QuakeWatch

**QuakeWatch** is a Flask-based web application designed to display real-time and historical earthquake data. It visualizes earthquake statistics with interactive graphs and provides detailed information sourced from the USGS Earthquake API. Built using an object‑oriented design and modular structure, QuakeWatch separates templates, utility functions, and route definitions, making it both scalable and maintainable. The application is also containerized with Docker for easy deployment.


## Features

- **Real-Time & Historical Data:** Fetches earthquake data from the USGS API.
- **Interactive Graphs:** Displays earthquake counts over various time periods (e.g., last 30 days, 5-year view) using Matplotlib.
- **Top Earthquake Events:** Shows the top 5 worldwide earthquakes (last 30 days) by magnitude.
- **Recent Earthquake Details:** Highlights the most recent earthquake event.
- **RESTful Endpoints:** Provides endpoints for health checks, status, connectivity tests, and raw data.
- **Clean UI:** Built with Bootstrap 5, featuring a professional navigation bar with a logo.
- **Containerization:** Includes Dockerfile and docker-compose.yml for easy containerized deployment.

 
## Project Structure

```
QuakeWatch/
├── app.py                  # Application factory and entry point
├── dashboard.py            # Blueprint & route definitions using OOP style
├── utils.py                # Helper functions and custom Jinja2 filters
├── requirements.txt        # Python dependencies
├── static/
│   └── experts-logo.svg    # Logo file used in the UI
└── templates/              # Jinja2 HTML templates
    ├── base.html        # Base template with common layout and navigation
    ├── main_page.html      # Home page content
    └── graph_dashboard.h tml# Dashboard view with graphs and earthquake details
├── Dockerfile              # Docker image build instructions
├── docker-compose.yml      # Docker Compose configuration

```

## Installation

### Locally

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/yourusername/QuakeWatch.git
   cd QuakeWatch # Enter the project directory
   ```

2. **Set Up a Virtual Environment (optional but recommended):**

   Creating a virtual environment helps keep your project dependencies isolated from other Python projects on your system.

   ```bash
   python -m venv venv	      # Create a virtual environment named 'venv'	
   source venv/bin/activate   # Activate the virtual environment on macOS/Linux
   # On Windows, activate with:
   # venv\Scripts\activate
   ```

3. **Install Dependencies:**

   After activating the virtual environment, install the required Python packages using:

   ```bash
   pip install -r requirements.txt
   ```

## Running the Application Locally

1. **Start the Flask Application:**

   ```bash
   python app.py
   ```

2. **Access the Application:**

   Open your browser and visit [http://127.0.0.1:5000](http://127.0.0.1:5000) to view the dashboard.

   > **Note:** If you run the app on a different port, replace `5000` with the port you used.

## Custom Jinja2 Filter

The project includes a custom filter `timestamp_to_str` that converts epoch timestamps to human-readable strings. This filter is registered during application initialization and is used in the templates to format timestamps nicely.

For example, in the HTML templates, you might see:

```jinja
{{ earthquake.timestamp | timestamp_to_str }}
```

## Known Issues

- **SSL Warning:** You might see a warning about LibreSSL when using `urllib3`.  
  This is informational and does not affect the functionality of the application.

- **Matplotlib Backend:** The application forces Matplotlib to use the `Agg` backend  
  for headless rendering (e.g., when running in Docker or on a server without a GUI).  
  Make sure this setting is applied *before* any Matplotlib imports to avoid GUI-related errors.

> These issues are normal and expected. They do not impact how QuakeWatch functions.


## Running with Docker

You can also run the application inside a Docker container:

```bash
docker build -t quakewatch:latest .
docker run -p 8080:5000 quakewatch:latest
```

## Docker Support

This project includes:
- `Dockerfile`: instructions to build the Docker image
- `docker-compose.yml`: optional file to run multiple services together (if you add it)

These make it easier to deploy QuakeWatch in different environments.

## Docker Hub Image

You can also pull the prebuilt image:

```bash
docker pull yourusername/quakewatch:latest
```

## Running with Docker Compose

You can also run the application using Docker Compose, which builds the image and runs the container automatically:

```bash
docker-compose up --build
```

Once running, open your browser and go to:

http://localhost:8080


This is because the application inside the container listens on port 5000, but Docker Compose maps it to port 8080 on your local machine.

## Kubernetes Deployment

This project includes Kubernetes manifests to deploy QuakeWatch with:

- Deployment (2 replicas)
- NodePort Service exposing port 5000
- Horizontal Pod Autoscaler (HPA) based on CPU usage
- ConfigMap and Secret for config and sensitive data
- CronJob for periodic tasks

### Deploy on Minikube

1. Enable metrics-server addon (required for HPA):
```bash
minikube addons enable metrics-server
```
