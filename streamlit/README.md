# Streamlit Dashboard

A simple standard Streamlit dashboard for the data warehouse project.

## Setup

### 1. Create and activate virtual environment

Run the setup script to create a virtual environment and install dependencies:

```bash
cd streamlit
chmod +x setup_venv.sh
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

### 2. Run the dashboard

Activate the virtual environment and run Streamlit:

```bash
cd streamlit
source venv/bin/activate
streamlit run app.py
```

The dashboard will open in your default web browser at `http://localhost:8501`

## Docker Deployment

### Option 1: Using Docker Compose (Recommended)

The Streamlit app is configured in the root `docker-compose.yml`. To run it:

```bash
# From the project root directory
docker-compose up -d streamlit
```

Or to run both PostgreSQL and Streamlit together:

```bash
docker-compose up -d
```

The Streamlit app will be available at `http://localhost:8501` (or the port specified in `STREAMLIT_PORT` environment variable).

### Option 2: Using Docker directly

Build and run the container:

```bash
cd streamlit
docker build -t data-warehouse-streamlit .
docker run -d -p 8501:8501 --name streamlit-app data-warehouse-streamlit
```

### Docker Commands

- **View logs**: `docker-compose logs -f streamlit` or `docker logs -f streamlit-app`
- **Stop container**: `docker-compose stop streamlit` or `docker stop streamlit-app`
- **Restart container**: `docker-compose restart streamlit` or `docker restart streamlit-app`
- **Remove container**: `docker-compose down streamlit` or `docker rm -f streamlit-app`
- **Rebuild after changes**: `docker-compose build streamlit` or `docker build -t data-warehouse-streamlit .`

### Environment Variables

You can customize the Streamlit port by setting the `STREAMLIT_PORT` environment variable:

```bash
STREAMLIT_PORT=8502 docker-compose up -d streamlit
```

## Dependencies

All package dependencies are tracked in `requirements.txt`:
- `streamlit` - The Streamlit framework
- `pandas` - Data manipulation and analysis
- `numpy` - Numerical computing

## Features

The dashboard includes:
- 📊 Key metrics cards
- 📈 Interactive charts (line and bar charts)
- 📋 Data tables with download functionality
- ⚙️ Sidebar configuration and filters
- 📅 Date range selectors

## Development

To add new dependencies:

1. Install the package in your virtual environment:
   ```bash
   source venv/bin/activate
   pip install <package-name>
   ```

2. Update `requirements.txt`:
   ```bash
   pip freeze > requirements.txt
   ```

Or manually add the package to `requirements.txt` with the version number.

