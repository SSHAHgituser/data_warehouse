# AI Analytics Assistant

Natural Language to SQL analytics powered by LLMs (OpenAI GPT-4 or Anthropic Claude).

## Features

- **Natural Language Queries**: Ask questions about your data in plain English
- **Smart SQL Generation**: Converts questions to optimized PostgreSQL queries
- **Auto-Visualization**: Automatically generates appropriate charts for results
- **Conversation Context**: Maintains context for follow-up questions
- **Safety First**: SQL validation prevents dangerous queries

## Setup

### 1. Install Dependencies

```bash
cd streamlit
pip install -r requirements.txt
```

### 2. Set API Key

Choose one provider and set the environment variable:

**Option A: OpenAI (GPT-4)**
```bash
export OPENAI_API_KEY="your-openai-api-key"
```

**Option B: Anthropic (Claude)**
```bash
export ANTHROPIC_API_KEY="your-anthropic-api-key"
```

You can also enter the API key directly in the Streamlit sidebar.

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
