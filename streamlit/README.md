# Streamlit Dashboard

A Streamlit dashboard for visualizing and exploring data warehouse data.

## Quick Start

The Streamlit app is automatically started with `./start.sh` from the repository root. Access it at `http://localhost:8501`.

For manual startup, see the [main README](../README.md#step-by-step-setup).

## Local Development

### Quick Start

The easiest way to run the app locally is using the convenience script:

```bash
cd streamlit
./run.sh
```

This script will:
- Create a virtual environment if it doesn't exist
- Install/update all dependencies
- Start the Streamlit app

### Manual Setup (Optional)

If you prefer to set up manually:

```bash
cd streamlit
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
streamlit run app.py
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
- `openai` - OpenAI GPT API for AI Assistant
- `anthropic` - Anthropic Claude API (alternative to OpenAI)
- `python-dotenv` - Environment variable management

## Features

- Multi-page analytics dashboard
- **🤖 AI Analytics Assistant** - Natural language queries powered by GPT-4
- Sales & Revenue Analytics
- Product & Inventory Analytics
- Customer Analytics
- HR & Employee Performance
- Operations & Supply Chain
- Advanced Analytics (Time Series, Market Basket, Geographic, Price Elasticity)
- Interactive charts and visualizations
- Data tables with download functionality
- Sidebar configuration and filters

## AI Assistant Setup

The AI Analytics Assistant allows you to query your data using natural language (e.g., "What is our revenue by territory?").

### 1. Get an OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create an account or sign in
3. Click "Create new secret key"
4. Copy the key (starts with `sk-`)

### 2. Configure Your API Key

Create a `.env` file in the `streamlit/` directory:

```bash
cd streamlit
cat > .env << 'EOF'
OPENAI_API_KEY=sk-proj-your-actual-key-here
EOF
```

Or manually create `streamlit/.env`:

```env
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxx
```

> ⚠️ **Security Note:** The `.env` file is already in `.gitignore` and will NOT be committed to Git.

### 3. Install AI Dependencies

```bash
source venv/bin/activate
pip install -r requirements.txt
```

### 4. Use the AI Assistant

1. Start the dashboard: `streamlit run app.py`
2. Navigate to **🤖 AI Assistant** in the sidebar
3. Ask questions like:
   - "What is our total revenue by territory?"
   - "Show me top 10 customers by lifetime value"
   - "Which products have the highest profit margin?"

### Cost Estimate

Using GPT-4o (default): ~$0.007 per query (~$21/month for 100 queries/day)

To use a cheaper model, add to your `.env`:

```env
OPENAI_API_KEY=sk-proj-your-key
OPENAI_MODEL=gpt-4o-mini  # ~$0.0004 per query
```

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
