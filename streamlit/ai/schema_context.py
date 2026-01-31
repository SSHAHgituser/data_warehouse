"""
Schema Context Loader
=====================
Loads semantic context from the data warehouse for LLM prompting.
Uses dim_metric as the single source of truth for metric definitions.
Dynamically loads dbt model YAML files for comprehensive schema context.
"""

import os
import pandas as pd
from typing import Optional
from pathlib import Path

# Try to import yaml for loading dbt schema files
try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False


class SchemaContext:
    """Loads and manages schema context for the AI assistant."""
    
    def __init__(self, conn):
        """
        Initialize with database connection.
        
        Args:
            conn: psycopg2 database connection
        """
        self.conn = conn
        self._metrics_cache: Optional[pd.DataFrame] = None
        self._tables_cache: Optional[dict] = None
        self._yaml_schemas_cache: Optional[dict] = None
        
        # Path to dbt models directory (relative to streamlit/)
        self.dbt_models_path = Path(__file__).parent.parent.parent / 'dbt' / 'models'
    
    def get_metrics_catalog(self) -> pd.DataFrame:
        """
        Load all metrics from dim_metric with their definitions.
        
        Returns:
            DataFrame with metric metadata
        """
        if self._metrics_cache is not None:
            return self._metrics_cache
        
        query = """
        SELECT 
            metric_key,
            metric_name,
            metric_description,
            metric_category,
            metric_unit,
            metric_level,
            metric_parent,
            metric_target,
            recommended_actions
        FROM dim_metric
        ORDER BY metric_category, metric_level, metric_key
        """
        
        try:
            self._metrics_cache = pd.read_sql(query, self.conn)
            return self._metrics_cache
        except Exception as e:
            # Return empty DataFrame if table doesn't exist
            return pd.DataFrame()
    
    def load_yaml_schemas(self) -> dict:
        """
        Load all _schema.yml files from dbt models directory.
        
        Returns:
            Dictionary mapping model names to their schema definitions
        """
        if self._yaml_schemas_cache is not None:
            return self._yaml_schemas_cache
        
        if not YAML_AVAILABLE:
            return {}
        
        schemas = {}
        
        # Find all schema.yml files
        schema_files = [
            self.dbt_models_path / 'marts' / '_schema.yml',
            self.dbt_models_path / 'intermediate' / '_schema.yml',
            self.dbt_models_path / 'intermediate' / 'facts' / 'metrics' / '_metrics_schema.yml',
        ]
        
        for schema_file in schema_files:
            if schema_file.exists():
                try:
                    with open(schema_file, 'r') as f:
                        content = yaml.safe_load(f)
                        if content and 'models' in content:
                            for model in content['models']:
                                model_name = model.get('name', '')
                                if model_name:
                                    schemas[model_name] = {
                                        'description': model.get('description', ''),
                                        'columns': model.get('columns', [])
                                    }
                except Exception as e:
                    continue
        
        self._yaml_schemas_cache = schemas
        return schemas
    
    def get_table_schemas(self) -> dict:
        """
        Get comprehensive schema information from YAML files.
        
        Returns:
            Dictionary with table names and their column information
        """
        if self._tables_cache is not None:
            return self._tables_cache
        
        # Load YAML schemas
        yaml_schemas = self.load_yaml_schemas()
        
        tables = {}
        
        # Priority tables to include (marts and key dimensions/facts)
        priority_tables = [
            'mart_sales', 'mart_customer_analytics', 'mart_product_analytics',
            'mart_operations', 'mart_employee_territory_performance',
            'fact_global_metrics', 'fact_sales_order', 'fact_sales_order_line',
            'fact_inventory', 'fact_purchase_order', 'fact_work_order',
            'fact_employee_quota', 'dim_customer', 'dim_product', 'dim_date',
            'dim_employee', 'dim_territory', 'dim_vendor', 'dim_metric'
        ]
        
        for table_name in priority_tables:
            if table_name in yaml_schemas:
                schema = yaml_schemas[table_name]
                desc = schema['description']
                columns = schema['columns']
                
                # Build column descriptions
                col_desc = []
                for col in columns:
                    col_name = col.get('name', '')
                    col_description = col.get('description', '')
                    if col_name:
                        col_desc.append(f"  - {col_name}: {col_description}")
                
                tables[table_name] = f"""{desc}

Columns:
{chr(10).join(col_desc)}"""
            else:
                # Fallback for tables not in YAML
                tables[table_name] = self._get_fallback_schema(table_name)
        
        self._tables_cache = tables
        return tables
    
    def _get_fallback_schema(self, table_name: str) -> str:
        """Get fallback schema for tables not in YAML files."""
        fallback_schemas = {
            'mart_sales': """
                Main sales mart with all dimensions joined.
                Key columns: salesorderid, order_date, customer_key, product_key, territory_key, order_total, net_line_amount
            """,
            'mart_customer_analytics': """
                Customer analytics with CLV, RFM, and churn prediction.
                Key columns: customerid, customer_name, lifetime_value, customer_segment, churn_risk, rfm_category
            """,
            'mart_product_analytics': """
                Product analytics with profitability and inventory metrics.
                Key columns: productid, product_name, category_name, total_revenue, profit_margin_percent
            """,
        }
        return fallback_schemas.get(table_name, f"Table: {table_name}")
    
    def get_example_queries(self) -> list:
        """
        Get few-shot examples for SQL generation.
        
        Returns:
            List of (question, sql) tuples
        """
        return [
            (
                "What is our total revenue by territory?",
                """SELECT territory_name, SUM(order_total) as total_revenue
FROM mart_sales
WHERE territory_name IS NOT NULL
GROUP BY territory_name
ORDER BY total_revenue DESC"""
            ),
            (
                "Show me the top 10 customers by lifetime value",
                """SELECT customer_name, lifetime_value, customer_segment, order_count
FROM mart_customer_analytics
ORDER BY lifetime_value DESC
LIMIT 10"""
            ),
            (
                "What is our monthly revenue trend for 2014?",
                """SELECT order_year, order_month, SUM(order_total) as monthly_revenue
FROM mart_sales
WHERE order_year = 2014
GROUP BY order_year, order_month
ORDER BY order_month"""
            ),
            (
                "Which products have the highest profit margin?",
                """SELECT product_name, category_name, total_revenue, profit_margin_percent
FROM mart_product_analytics
WHERE profit_margin_percent IS NOT NULL
ORDER BY profit_margin_percent DESC
LIMIT 10"""
            ),
            (
                "Show me customers at risk of churning",
                """SELECT customer_name, lifetime_value, days_since_last_order, churn_risk, rfm_category
FROM mart_customer_analytics
WHERE churn_risk = 'High'
ORDER BY lifetime_value DESC"""
            ),
            (
                "What is the average order value by customer segment?",
                """SELECT customer_segment, 
       COUNT(DISTINCT salesorderid) as order_count,
       AVG(order_total) as avg_order_value,
       SUM(order_total) as total_revenue
FROM mart_sales
WHERE customer_segment IS NOT NULL
GROUP BY customer_segment
ORDER BY total_revenue DESC"""
            ),
            (
                "Show revenue by product category and year",
                """SELECT category_name, order_year, SUM(net_line_amount) as revenue
FROM mart_sales
WHERE category_name IS NOT NULL
GROUP BY category_name, order_year
ORDER BY category_name, order_year"""
            ),
            (
                "What are our top selling products?",
                """SELECT product_name, category_name, SUM(orderqty) as total_quantity, SUM(net_line_amount) as total_revenue
FROM mart_sales
WHERE product_name IS NOT NULL
GROUP BY product_name, category_name
ORDER BY total_revenue DESC
LIMIT 10"""
            ),
            (
                "Show employee quota achievement",
                """SELECT performance_name, quota_achievement_percent, quota_status, monthly_revenue
FROM mart_employee_territory_performance
WHERE performance_type = 'employee'
ORDER BY quota_achievement_percent DESC"""
            ),
            (
                "What is our inventory status by category?",
                """SELECT p.category_name, 
       SUM(i.quantity) as total_quantity,
       SUM(i.inventory_value) as total_value,
       COUNT(CASE WHEN i.inventory_status = 'Out of Stock' THEN 1 END) as out_of_stock_count
FROM fact_inventory i
JOIN dim_product p ON i.product_key = p.productid
GROUP BY p.category_name
ORDER BY total_value DESC"""
            )
        ]
    
    def build_system_prompt(self) -> str:
        """
        Build the complete system prompt for SQL generation.
        
        Returns:
            System prompt string with full context
        """
        metrics_df = self.get_metrics_catalog()
        tables = self.get_table_schemas()
        examples = self.get_example_queries()
        
        # Build metrics context
        metrics_context = ""
        if not metrics_df.empty:
            metrics_by_category = metrics_df.groupby('metric_category')
            for category, group in metrics_by_category:
                metrics_context += f"\n### {category} Metrics:\n"
                for _, row in group.iterrows():
                    desc = str(row['metric_description'])[:100] if row['metric_description'] else ''
                    metrics_context += f"- {row['metric_key']}: {row['metric_name']} ({row['metric_unit']}) - {desc}...\n"
        
        # Build table context with full column details
        tables_context = ""
        for table, desc in tables.items():
            tables_context += f"\n### {table}\n{desc.strip()}\n"
        
        # Build examples context
        examples_context = "\n\n".join([
            f"Question: {q}\nSQL:\n```sql\n{sql}\n```"
            for q, sql in examples
        ])
        
        return f"""You are a SQL expert for the AdventureWorks data warehouse running on PostgreSQL.
Your job is to convert natural language questions into accurate SQL queries.

## Database Schema (with column descriptions)
{tables_context}

## Available Metrics (from dim_metric):
{metrics_context}

## Important Rules:
1. ONLY generate SELECT queries - no INSERT, UPDATE, DELETE, DROP, or any DDL
2. Always use table aliases for clarity when joining tables
3. Use appropriate aggregations (SUM, AVG, COUNT, etc.) for metrics
4. Include ORDER BY for sorted results
5. Use LIMIT for top-N queries (default to 10-20 for large result sets)
6. Handle NULL values appropriately with COALESCE or WHERE filters
7. Use proper date filtering for time-based queries
8. Prefer using mart tables (mart_sales, mart_customer_analytics, etc.) which have pre-joined dimensions
9. Format column names to be human-readable in output using AS aliases
10. For time series queries, use order_year and order_month columns in mart_sales
11. Use customer_segment, customer_status, churn_risk columns for customer analysis
12. Use category_name, subcategory_name for product analysis

## Example Queries:
{examples_context}

## Response Format:
Return ONLY the SQL query without any explanation or markdown formatting.
If the question cannot be answered with the available data, respond with:
-- ERROR: [explanation of why the query cannot be generated]
"""
    
    def get_quick_context(self) -> str:
        """
        Get a condensed context for follow-up questions.
        
        Returns:
            Shortened context string
        """
        return """Available tables: mart_sales, mart_customer_analytics, mart_product_analytics, 
mart_operations, mart_employee_territory_performance, fact_global_metrics, 
dim_customer, dim_product, dim_territory, dim_date, dim_metric, dim_employee, dim_vendor,
fact_sales_order, fact_sales_order_line, fact_inventory, fact_purchase_order, fact_work_order.

Key fields in mart_sales:
- salesorderid, salesorderdetailid: Order identifiers
- order_date, order_year, order_month, order_season: Time dimensions  
- customer_key, customer_name, customer_segment, customer_status: Customer info
- product_key, product_name, category_name, subcategory_name: Product info
- territory_key, territory_name, countryregioncode, territory_group: Geography
- order_total, net_line_amount, total_profit: Financial metrics
- orderqty, unitprice, unitpricediscount: Line item details

Key fields in mart_customer_analytics:
- customerid, customer_name, lifetime_value, order_count, avg_order_value
- customer_segment, customer_status, churn_risk, rfm_category
- days_since_last_order, first_order_date, last_order_date

Key fields in mart_product_analytics:
- productid, product_name, category_name, total_revenue, profit_margin_percent
- inventory_status, monthly_sales_velocity, inventory_turnover_ratio

Return ONLY the SQL query, no explanations."""
