# Streamlit Dashboard

A Streamlit dashboard for visualizing and exploring data warehouse data.

## Quick Start

The Streamlit app is automatically started with `./start.sh` from the repository root. Access it at `http://localhost:8501`.

For manual startup, see the [main README](../README.md#step-by-step-setup).

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

## Configuration

Customize the port using environment variables in `.env` or `docker-compose.yml`:

```bash
STREAMLIT_PORT=8502
```

For Docker commands, see the [main README](../README.md#stopping-services).

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
