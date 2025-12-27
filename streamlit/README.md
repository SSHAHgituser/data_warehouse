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

**IMPORTANT: Always activate the virtual environment before running Streamlit**

```bash
cd streamlit
source venv/bin/activate
streamlit run app.py
```

Or use the convenience script:

```bash
cd streamlit
./run.sh
```

## Troubleshooting

### Numpy Import Error

If you see an error like:
```
ImportError: Unable to import required dependencies:
numpy: Error importing numpy: you should not try to import numpy from
        its source directory
```

**Solution:**
1. Make sure you're using the virtual environment, not anaconda/base Python
2. Activate the venv: `source venv/bin/activate`
3. Verify you're using the venv Python: `which python` (should point to venv)
4. If the issue persists, reinstall numpy:
   ```bash
   source venv/bin/activate
   pip uninstall numpy -y
   pip install numpy
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
- `psycopg2-binary` - PostgreSQL database connector
- `plotly` - Interactive visualizations

## Features

- Multi-page analytics dashboard
- Sales & Revenue Analytics
- Product & Inventory Analytics
- Customer Analytics
- HR & Employee Performance
- Operations & Supply Chain
- Advanced Analytics (Time Series, Market Basket, Geographic, Price Elasticity)
- Interactive charts and visualizations
- Data tables with download functionality
- Sidebar configuration and filters

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
