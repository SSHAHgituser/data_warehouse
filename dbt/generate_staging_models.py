#!/usr/bin/env python3
"""
Generate staging dbt models and YAML schema files for all tables in public schema
"""
import subprocess
import os
import re

# Paths
STAGING_DIR = "models/staging"
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
STAGING_PATH = os.path.join(PROJECT_ROOT, STAGING_DIR)

# Create staging directory
os.makedirs(STAGING_PATH, exist_ok=True)

def get_tables():
    """Get list of all tables from public schema"""
    result = subprocess.run(
        [
            "docker", "exec", "data_warehouse_postgres",
            "psql", "-U", "postgres", "-d", "data_warehouse",
            "-tAc", 
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;"
        ],
        capture_output=True,
        text=True
    )
    tables = [line.strip() for line in result.stdout.strip().split('\n') if line.strip()]
    return tables

def get_columns(table_name):
    """Get column information for a table"""
    result = subprocess.run(
        [
            "docker", "exec", "data_warehouse_postgres",
            "psql", "-U", "postgres", "-d", "data_warehouse",
            "-tAc",
            f"SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = 'public' AND table_name = '{table_name}' AND column_name NOT LIKE '_airbyte%' ORDER BY ordinal_position;"
        ],
        capture_output=True,
        text=True
    )
    
    columns = []
    for line in result.stdout.strip().split('\n'):
        if line.strip():
            parts = [p.strip() for p in line.split('|')]
            if len(parts) >= 2:
                columns.append({
                    'name': parts[0],
                    'data_type': parts[1],
                    'nullable': parts[2] if len(parts) > 2 else 'YES'
                })
    return columns

def to_snake_case(name):
    """Convert table name to snake_case if needed"""
    # Insert underscore before capital letters
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

def is_reserved_keyword(word):
    """Check if a word is a PostgreSQL reserved keyword"""
    reserved = {
        'primary', 'key', 'order', 'group', 'select', 'from', 'where', 'user', 'table',
        'index', 'view', 'schema', 'database', 'column', 'table', 'as', 'on', 'join',
        'inner', 'outer', 'left', 'right', 'full', 'union', 'intersect', 'except',
        'distinct', 'all', 'case', 'when', 'then', 'else', 'end', 'and', 'or', 'not',
        'in', 'exists', 'like', 'ilike', 'similar', 'to', 'is', 'null', 'true', 'false',
        'between', 'over', 'partition', 'by', 'window', 'rows', 'range', 'preceding',
        'following', 'current', 'row', 'unbounded', 'rank', 'dense_rank', 'row_number',
        'lead', 'lag', 'first_value', 'last_value', 'count', 'sum', 'avg', 'min', 'max',
        'stddev', 'variance', 'array_agg', 'string_agg', 'json_agg', 'jsonb_agg'
    }
    return word.lower() in reserved

def needs_quotes(column_name):
    """Determine if a column name needs to be quoted"""
    # Quote if it's a reserved keyword
    if is_reserved_keyword(column_name):
        return True
    # Quote if it contains mixed case (has uppercase letters)
    if any(c.isupper() for c in column_name):
        return True
    # Quote if it starts with a number or special character
    if column_name and (column_name[0].isdigit() or column_name[0] in '_-'):
        return True
    return False

def generate_staging_model(table_name, columns):
    """Generate staging SQL model"""
    model_name = f"stg_{table_name}"
    
    # Build column list
    column_list = []
    for col in columns:
        col_name = col['name']
        # Quote column names that need it
        if needs_quotes(col_name):
            col_name = f'"{col_name}"'
        column_list.append(f"    {col_name}")
    
    column_str = ',\n'.join(column_list)
    sql_content = f"""{{{{ config(materialized='view') }}}}

select
{column_str}
from {{{{ source('raw', '{table_name}') }}}}
"""
    
    return model_name, sql_content

def generate_yaml_schema(table_name, columns):
    """Generate YAML schema file"""
    model_name = f"stg_{table_name}"
    
    yaml_content = f"""version: 2

models:
  - name: {model_name}
    description: "Staging model for {table_name} table from public schema"
    columns:
"""
    
    for col in columns:
        col_name = col['name']
        data_type = col['data_type']
        nullable = "nullable" if col['nullable'] == 'YES' else "not nullable"
        
        # Clean up column name for description if it has quotes
        desc_name = col_name.replace('"', '')
        
        yaml_content += f"""      - name: {col_name}
        description: "{desc_name} ({data_type}, {nullable})"
"""
    
    return yaml_content

def main():
    print("🚀 Generating staging models and YAML files...")
    print(f"📁 Staging directory: {STAGING_PATH}")
    
    tables = get_tables()
    print(f"📊 Found {len(tables)} tables")
    
    for i, table_name in enumerate(tables, 1):
        print(f"  [{i}/{len(tables)}] Processing {table_name}...")
        
        # Get columns
        columns = get_columns(table_name)
        
        if not columns:
            print(f"    ⚠️  No columns found (skipping)")
            continue
        
        # Generate staging model
        model_name, sql_content = generate_staging_model(table_name, columns)
        sql_file = os.path.join(STAGING_PATH, f"{model_name}.sql")
        with open(sql_file, 'w') as f:
            f.write(sql_content)
        
        # Generate YAML schema
        yaml_content = generate_yaml_schema(table_name, columns)
        yaml_file = os.path.join(STAGING_PATH, f"{model_name}.yml")
        with open(yaml_file, 'w') as f:
            f.write(yaml_content)
    
    print(f"\n✅ Generated {len(tables)} staging models and YAML files in {STAGING_DIR}/")
    print("\n⚠️  Note: You'll need to create a sources.yml file to define the 'raw' source.")

if __name__ == "__main__":
    main()

