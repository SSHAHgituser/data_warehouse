# Streamlit Dashboard

A Streamlit dashboard for the data warehouse project.

## Quick Start

The Streamlit app is configured in the root `docker-compose.yml`. To start it:

```bash
# From project root - start all services
docker-compose up -d

# Or start just Streamlit (PostgreSQL must be running first)
docker-compose up -d streamlit
```

Access the dashboard at `http://localhost:8501` (or the port specified in `STREAMLIT_PORT` environment variable).

## Local Development

### Setup Virtual Environment

```bash
cd streamlit
./setup_venv.sh
```

Or manually:

```bash
cd streamlit
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Run Locally

```bash
cd streamlit
source venv/bin/activate
streamlit run app.py
```

## Docker Commands

- **View logs**: `docker-compose logs -f streamlit`
- **Stop**: `docker-compose stop streamlit`
- **Restart**: `docker-compose restart streamlit`
- **Rebuild**: `docker-compose build streamlit`

## Configuration

Customize the port using environment variables:

```bash
STREAMLIT_PORT=8502 docker-compose up -d streamlit
```

## Dependencies

See `requirements.txt` for package dependencies:
- `streamlit` - The Streamlit framework
- `pandas` - Data manipulation
- `numpy` - Numerical computing

## Features

- Key metrics cards
- Interactive charts
- Data tables with download functionality
- Sidebar configuration and filters
- Date range selectors

## Adding Dependencies

1. Install in virtual environment:
   ```bash
   source venv/bin/activate
   pip install <package-name>
   ```

2. Update `requirements.txt`:
   ```bash
   pip freeze > requirements.txt
   ```

For more information about the overall project setup, see the [main README](../README.md).
