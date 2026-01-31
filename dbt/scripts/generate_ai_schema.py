#!/usr/bin/env python3
"""
Generate AI Schema File
=======================
Reads all dbt _schema.yml files and generates:
1. schema_ai.md - Optimized schema context for LLM prompting
2. allowed_tables.json - Whitelist for SQL validator

This script is automatically run after `dbt run` to keep the AI context
in sync with your dbt models.

Usage:
    python scripts/generate_ai_schema.py

Output:
    models/schema_ai.md
    ../streamlit/ai/allowed_tables.json
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime

# Try to import yaml
try:
    import yaml
except ImportError:
    print("❌ PyYAML not installed. Run: pip install pyyaml")
    sys.exit(1)


def load_yaml_file(path: Path) -> dict:
    """Load a YAML file and return its contents."""
    try:
        with open(path, 'r') as f:
            return yaml.safe_load(f) or {}
    except Exception as e:
        print(f"⚠️  Warning: Could not load {path}: {e}")
        return {}


def load_dbt_profile(dbt_path: Path) -> dict:
    """Load database/schema info from profiles.yml."""
    profiles_path = dbt_path / 'profiles.yml'
    default = {'database': 'data_warehouse', 'schema': 'dbt'}
    
    if not profiles_path.exists():
        return default
    
    content = load_yaml_file(profiles_path)
    
    for profile_name, profile_config in content.items():
        if isinstance(profile_config, dict) and 'outputs' in profile_config:
            target = profile_config.get('target', 'dev')
            outputs = profile_config.get('outputs', {})
            target_config = outputs.get(target, {})
            return {
                'database': target_config.get('dbname', default['database']),
                'schema': target_config.get('schema', default['schema'])
            }
    
    return default


def load_all_schemas(models_path: Path) -> dict:
    """Load all _schema.yml files and return consolidated model info."""
    schemas = {}
    
    # Find all schema files
    schema_files = list(models_path.glob('**/*schema*.yml'))
    
    for schema_file in schema_files:
        content = load_yaml_file(schema_file)
        if 'models' in content:
            for model in content['models']:
                model_name = model.get('name', '')
                if model_name:
                    schemas[model_name] = {
                        'description': model.get('description', ''),
                        'columns': model.get('columns', []),
                        'source_file': str(schema_file)
                    }
    
    return schemas


def categorize_tables(schemas: dict) -> dict:
    """
    Auto-categorize tables into marts, dimensions, and facts based on naming convention.
    
    Returns dict with keys: 'marts', 'dimensions', 'facts', 'metrics', 'staging', 'other'
    """
    categories = {
        'marts': [],
        'dimensions': [],
        'facts': [],
        'metrics': [],
        'staging': [],
        'other': []
    }
    
    for table_name in schemas.keys():
        name_lower = table_name.lower()
        
        if name_lower.startswith('mart_'):
            categories['marts'].append(table_name)
        elif name_lower.startswith('dim_'):
            categories['dimensions'].append(table_name)
        elif name_lower.startswith('fact_'):
            categories['facts'].append(table_name)
        elif name_lower.startswith('metrics_'):
            categories['metrics'].append(table_name)
        elif name_lower.startswith('stg_'):
            categories['staging'].append(table_name)
        else:
            categories['other'].append(table_name)
    
    # Sort each category
    for key in categories:
        categories[key].sort()
    
    return categories


def get_allowed_tables(categories: dict) -> list:
    """Get list of tables allowed for AI queries (marts, dims, facts)."""
    allowed = []
    allowed.extend(categories['marts'])
    allowed.extend(categories['dimensions'])
    allowed.extend(categories['facts'])
    # Don't include staging or metrics intermediate tables
    return sorted(allowed)


def format_columns_table(columns: list, max_cols: int = 30) -> str:
    """Format columns as a markdown table."""
    if not columns:
        return ""
    
    lines = ["| Column | Description |", "|--------|-------------|"]
    
    for col in columns[:max_cols]:
        name = col.get('name', '')
        desc = col.get('description', '').replace('|', '\\|').replace('\n', ' ')
        # Truncate long descriptions
        if len(desc) > 60:
            desc = desc[:57] + "..."
        lines.append(f"| {name} | {desc} |")
    
    if len(columns) > max_cols:
        lines.append(f"| ... | ({len(columns) - max_cols} more columns) |")
    
    return '\n'.join(lines)


def generate_mart_quick_reference(marts: list, schemas: dict) -> str:
    """Generate quick reference for mart tables."""
    lines = ["**USE THESE TABLES** (pre-joined, no manual joins needed):"]
    
    # Define short descriptions for common marts
    mart_descriptions = {
        'mart_sales': 'Sales with customer, product, territory',
        'mart_customer_analytics': 'CLV, RFM, churn prediction',
        'mart_product_analytics': 'Product performance, inventory',
        'mart_operations': 'Purchase orders, work orders',
        'mart_employee_territory_performance': 'Quotas, performance',
        'mart_metrics': '⭐ **ALL METRICS** with definitions, targets, categories',
    }
    
    for mart in marts:
        if mart in schemas:
            # Use predefined description or generate from schema
            if mart in mart_descriptions:
                desc = mart_descriptions[mart]
            else:
                schema_desc = schemas[mart].get('description', '')
                desc = schema_desc.split('\n')[0][:50] if schema_desc else 'Pre-joined data mart'
            lines.append(f"- `{mart}` - {desc}")
    
    return '\n'.join(lines)


def generate_schema_md(dbt_path: Path, schemas: dict, categories: dict) -> str:
    """Generate the optimized schema_ai.md content."""
    profile = load_dbt_profile(dbt_path)
    
    # Build the markdown content
    content = f"""# AdventureWorks Data Warehouse Schema (AI Context)

> **Database:** {profile['database']} | **Schema:** {profile['schema']} | Tables can be queried without schema prefix.
> 
> *Auto-generated on {datetime.now().strftime('%Y-%m-%d %H:%M')} by generate_ai_schema.py*

## Quick Reference

{generate_mart_quick_reference(categories['marts'], schemas)}

---

## Mart Tables ⭐ (Preferred - Pre-joined)

"""
    
    # Add mart tables
    for table in categories['marts']:
        if table in schemas:
            schema = schemas[table]
            desc = schema['description'].split('\n')[0] if schema['description'] else ''
            content += f"### {table}\n\n{desc}\n\n"
            content += format_columns_table(schema['columns']) + "\n\n"
    
    # Add common queries section
    content += """---

## Common SQL Patterns

```sql
-- Revenue by territory
SELECT territory_name, SUM(order_total) as revenue 
FROM mart_sales GROUP BY territory_name ORDER BY revenue DESC

-- Monthly trend
SELECT order_year, order_month, SUM(order_total) as revenue 
FROM mart_sales GROUP BY order_year, order_month ORDER BY order_year, order_month

-- Top customers
SELECT customer_name, lifetime_value, churn_risk 
FROM mart_customer_analytics ORDER BY lifetime_value DESC LIMIT 10

-- Customer segments
SELECT customer_segment, COUNT(*) as count, AVG(lifetime_value) as avg_clv 
FROM mart_customer_analytics GROUP BY customer_segment

-- Product performance
SELECT product_name, total_revenue, profit_margin_percent 
FROM mart_product_analytics ORDER BY total_revenue DESC LIMIT 10

-- All metrics values (USE mart_metrics!)
SELECT metric_name, metric_category, metric_value, metric_unit, report_date
FROM mart_metrics ORDER BY metric_category, metric_name

-- Metrics by category
SELECT metric_category, COUNT(*) as metric_count, AVG(metric_value) as avg_value
FROM mart_metrics GROUP BY metric_category ORDER BY metric_count DESC
```

---

## Dimension Tables (Join Reference)

### Join Key Reference ⚠️

| Dimension | Primary Key | Join From Fact |
|-----------|-------------|----------------|
| dim_customer | `customerid` | customer_key |
| dim_product | `productid` | product_key |
| dim_territory | `territoryid` | territory_key |
| dim_employee | `employee_id` | employee_key |
| dim_vendor | `vendor_id` | vendor_key |
| dim_date | `date_key` | date_key |
| dim_metric | `metric_key` | metric_key |

**Example correct join:**
```sql
JOIN dim_customer dc ON fact.customer_key = dc.customerid  -- NOT dc.customer_key!
```

"""
    
    # Add dimension tables (condensed)
    for table in categories['dimensions']:
        if table in schemas:
            schema = schemas[table]
            cols = [c.get('name', '') for c in schema['columns'][:10]]
            content += f"### {table}\n`{', '.join(cols)}`\n\n"
    
    # Add fact tables reference
    content += """---

## Fact Tables (Use marts instead when possible)

"""
    
    for table in categories['facts']:
        if table in schemas:
            schema = schemas[table]
            desc = schema['description'].split('\n')[0] if schema['description'] else ''
            content += f"### {table}\n{desc}\n\n"
    
    # Add guidelines
    content += """---

## SQL Guidelines

1. **Always use mart tables** - they have everything pre-joined
2. **Use mart_metrics for any metric queries** - it has all metric definitions
3. Use `SUM()`, `AVG()`, `COUNT()` for aggregations
4. Include `ORDER BY` for sorted results
5. Use `LIMIT` for top-N (default 10-20)
6. Filter NULLs: `WHERE column IS NOT NULL`
7. Time filters: `WHERE order_year = 2014`

## Response Format

Return ONLY the SQL query. No explanations, no markdown formatting.
If the question cannot be answered, respond with: `-- ERROR: [reason]`
"""
    
    return content


def generate_allowed_tables_json(allowed_tables: list, output_path: Path):
    """Generate allowed_tables.json for SQL validator."""
    data = {
        "_comment": "Auto-generated by dbt/scripts/generate_ai_schema.py - DO NOT EDIT MANUALLY",
        "_generated": datetime.now().isoformat(),
        "allowed_tables": allowed_tables
    }
    
    with open(output_path, 'w') as f:
        json.dump(data, f, indent=2)
    
    return len(allowed_tables)


def main():
    """Main function to generate AI schema files."""
    # Get dbt directory (script is in dbt/scripts/)
    script_dir = Path(__file__).parent
    dbt_path = script_dir.parent
    models_path = dbt_path / 'models'
    output_md_path = models_path / 'schema_ai.md'
    
    # Path to streamlit AI module
    streamlit_ai_path = dbt_path.parent / 'streamlit' / 'ai'
    output_json_path = streamlit_ai_path / 'allowed_tables.json'
    
    print("🤖 Generating AI schema context...")
    print(f"   Source: {models_path}")
    
    # Load all schemas
    schemas = load_all_schemas(models_path)
    print(f"   Found {len(schemas)} models in schema files")
    
    # Categorize tables
    categories = categorize_tables(schemas)
    print(f"   Marts: {len(categories['marts'])}, Dims: {len(categories['dimensions'])}, Facts: {len(categories['facts'])}")
    
    # Generate schema_ai.md
    content = generate_schema_md(dbt_path, schemas, categories)
    with open(output_md_path, 'w') as f:
        f.write(content)
    
    # Count approximate tokens (rough estimate: 1 token ≈ 4 chars)
    token_estimate = len(content) // 4
    print(f"✅ Generated schema_ai.md ({len(content):,} chars, ~{token_estimate:,} tokens)")
    
    # Generate allowed_tables.json
    allowed_tables = get_allowed_tables(categories)
    if streamlit_ai_path.exists():
        table_count = generate_allowed_tables_json(allowed_tables, output_json_path)
        print(f"✅ Generated allowed_tables.json ({table_count} tables)")
    else:
        print(f"⚠️  Skipped allowed_tables.json (streamlit/ai/ not found)")
    
    print(f"💰 Estimated cost savings: ~30% vs YAML-based context")
    
    # Print summary of allowed tables
    print(f"\n📋 Allowed tables for AI queries:")
    for table in allowed_tables:
        print(f"   - {table}")


if __name__ == '__main__':
    main()
