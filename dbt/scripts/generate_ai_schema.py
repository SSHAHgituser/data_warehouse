#!/usr/bin/env python3
"""
Generate AI Schema File
=======================
Reads all dbt _schema.yml files and generates an optimized schema_ai.md
file for the AI Analytics Assistant.

This script is automatically run after `dbt run` to keep the AI context
in sync with your dbt models.

Usage:
    python scripts/generate_ai_schema.py

Output:
    models/schema_ai.md
"""

import os
import sys
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
                        'columns': model.get('columns', [])
                    }
    
    return schemas


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


def generate_schema_md(dbt_path: Path) -> str:
    """Generate the optimized schema_ai.md content."""
    models_path = dbt_path / 'models'
    profile = load_dbt_profile(dbt_path)
    schemas = load_all_schemas(models_path)
    
    # Define which tables to include and their priority
    mart_tables = ['mart_sales', 'mart_customer_analytics', 'mart_product_analytics', 
                   'mart_operations', 'mart_employee_territory_performance']
    dim_tables = ['dim_customer', 'dim_product', 'dim_territory', 'dim_date', 
                  'dim_employee', 'dim_vendor', 'dim_metric']
    fact_tables = ['fact_global_metrics', 'fact_sales_order', 'fact_sales_order_line',
                   'fact_inventory', 'fact_purchase_order', 'fact_work_order', 'fact_employee_quota']
    
    # Build the markdown content
    content = f"""# AdventureWorks Data Warehouse Schema (AI Context)

> **Database:** {profile['database']} | **Schema:** {profile['schema']} | Tables can be queried without schema prefix.
> 
> *Auto-generated on {datetime.now().strftime('%Y-%m-%d %H:%M')} by generate_ai_schema.py*

## Quick Reference

**USE THESE TABLES** (pre-joined, no manual joins needed):
- `mart_sales` - Sales with customer, product, territory
- `mart_customer_analytics` - CLV, RFM, churn prediction
- `mart_product_analytics` - Product performance, inventory
- `mart_operations` - Purchase orders, work orders
- `mart_employee_territory_performance` - Quotas, performance

---

## Mart Tables ⭐ (Preferred - Pre-joined)

"""
    
    # Add mart tables
    for table in mart_tables:
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
    for table in dim_tables:
        if table in schemas:
            schema = schemas[table]
            cols = [c.get('name', '') for c in schema['columns'][:10]]
            content += f"### {table}\n`{', '.join(cols)}`\n\n"
    
    # Add fact tables reference
    content += """---

## Fact Tables (Use marts instead when possible)

"""
    
    for table in fact_tables:
        if table in schemas:
            schema = schemas[table]
            desc = schema['description'].split('\n')[0] if schema['description'] else ''
            content += f"### {table}\n{desc}\n\n"
    
    # Add guidelines
    content += """---

## SQL Guidelines

1. **Always use mart tables** - they have everything pre-joined
2. Use `SUM()`, `AVG()`, `COUNT()` for aggregations
3. Include `ORDER BY` for sorted results
4. Use `LIMIT` for top-N (default 10-20)
5. Filter NULLs: `WHERE column IS NOT NULL`
6. Time filters: `WHERE order_year = 2014`

## Response Format

Return ONLY the SQL query. No explanations, no markdown formatting.
If the question cannot be answered, respond with: `-- ERROR: [reason]`
"""
    
    return content


def main():
    """Main function to generate schema_ai.md."""
    # Get dbt directory (script is in dbt/scripts/)
    script_dir = Path(__file__).parent
    dbt_path = script_dir.parent
    models_path = dbt_path / 'models'
    output_path = models_path / 'schema_ai.md'
    
    print("🤖 Generating AI schema context...")
    print(f"   Source: {models_path}")
    print(f"   Output: {output_path}")
    
    # Generate content
    content = generate_schema_md(dbt_path)
    
    # Write to file
    with open(output_path, 'w') as f:
        f.write(content)
    
    # Count approximate tokens (rough estimate: 1 token ≈ 4 chars)
    token_estimate = len(content) // 4
    
    print(f"✅ Generated schema_ai.md ({len(content):,} chars, ~{token_estimate:,} tokens)")
    print(f"💰 Estimated cost savings: ~30% vs YAML-based context")


if __name__ == '__main__':
    main()
