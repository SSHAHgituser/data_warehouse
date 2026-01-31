# AI Analytics Assistant

Natural Language to SQL analytics powered by LLMs (OpenAI GPT-4 or Anthropic Claude).

## Features

- **Natural Language Queries**: Ask questions about your data in plain English
- **Smart SQL Generation**: Converts questions to optimized PostgreSQL queries
- **Auto-Visualization**: Automatically generates appropriate charts for results
- **Conversation Context**: Maintains context for follow-up questions
- **Safety First**: SQL validation prevents dangerous queries

## Setup

### 1. Get an OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create an account or sign in
3. Click **"Create new secret key"**
4. Copy the key (starts with `sk-`)

### 2. Install Dependencies

```bash
cd streamlit
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Configure Your API Key

Create a `.env` file in the `streamlit/` directory:

```bash
# Create .env file with your API key
cat > .env << 'EOF'
OPENAI_API_KEY=sk-proj-your-actual-key-here
EOF
```

Or manually create `streamlit/.env`:

```env
# Required: Your OpenAI API key
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxx

# Optional: Use a different model (default: gpt-4o)
# OPENAI_MODEL=gpt-4o-mini  # Cheaper option
```

> ⚠️ **Security:** The `.env` file is in `.gitignore` and will NOT be committed to Git.

**Alternative: Anthropic Claude**
```env
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key
```

You can also enter the API key directly in the Streamlit sidebar if not using `.env`.

### 3. Run the Dashboard

```bash
streamlit run app.py
```

Navigate to "🤖 AI Assistant" in the sidebar.

## Architecture

```
ai/
├── __init__.py           # Module exports
├── schema_context.py     # Loads semantic context from dim_metric
├── sql_generator.py      # LLM-based SQL generation
├── sql_validator.py      # SQL safety validation
├── visualizer.py         # Auto-visualization for results
└── README.md             # This file
```

## How It Works

1. **Schema Context**: Loads metric definitions from `dim_metric` and table schemas
2. **Prompt Engineering**: Builds a comprehensive system prompt with:
   - Available tables and their columns
   - Metric definitions and business meanings
   - Few-shot SQL examples
3. **SQL Generation**: LLM converts natural language to SQL
4. **Validation**: SQL is validated for safety (SELECT only, no injection)
5. **Execution**: Query runs against PostgreSQL
6. **Visualization**: Results are analyzed and visualized appropriately

## Example Questions

- "What is our total revenue by territory?"
- "Show me the top 10 customers by lifetime value"
- "What is the monthly revenue trend for 2014?"
- "Which products have the highest profit margin?"
- "Show me customers at risk of churning"
- "What is the average order value by customer segment?"

## Security

The `SQLValidator` ensures:
- Only SELECT queries are executed
- No DDL (CREATE, DROP, ALTER, etc.)
- No DML (INSERT, UPDATE, DELETE)
- Whitelist of allowed tables
- Automatic LIMIT clause (prevents huge result sets)
- No SQL injection patterns

## Customization

### Adding Tables to Whitelist

Edit `sql_validator.py`:

```python
ALLOWED_TABLES = [
    'mart_sales',
    'your_new_table',  # Add here
    ...
]
```

### Adding Few-Shot Examples

Edit `schema_context.py`:

```python
def get_example_queries(self) -> list:
    return [
        ("Your question", "SELECT ..."),
        ...
    ]
```

### Changing LLM Model

Set environment variables:
```bash
export OPENAI_MODEL="gpt-4-turbo"  # Default: gpt-4o
export ANTHROPIC_MODEL="claude-3-opus-20240229"  # Default: claude-sonnet-4-20250514
```
