"""
Schema Context Loader
=====================
Loads semantic context from the data warehouse for LLM prompting.
Uses dim_metric as the single source of truth for metric definitions.
"""

import pandas as pd
from typing import Optional


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
    
    def get_table_schemas(self) -> dict:
        """
        Get schema information for key tables.
        
        Returns:
            Dictionary with table names and their column information
        """
        if self._tables_cache is not None:
            return self._tables_cache
        
        tables = {
            'mart_sales': """
                Main sales mart with all dimensions joined.
                Key columns:
                - salesorderid, salesorderdetailid: Order identifiers
                - order_date, order_year, order_month, order_season: Time dimensions
                - customer_key, customer_name, customer_segment, customer_status: Customer info
                - product_key, product_name, category_name, subcategory_name: Product info
                - territory_key, territory_name, countryregioncode, territory_group: Geography
                - employee_key, salesperson_name: Sales rep info
                - order_total, net_line_amount, total_profit: Financial metrics
                - orderqty, unitprice, unitpricediscount: Line item details
                - has_discount, online_order_flag, shipping_speed_category: Order attributes
            """,
            'mart_customer_analytics': """
                Customer analytics with CLV, RFM, and churn prediction.
                Key columns:
                - customerid, customer_name, email_address: Customer identity
                - customer_segment (High/Medium/Low Value), customer_status (Active/At Risk/Inactive)
                - lifetime_value, order_count, avg_order_value: Purchase metrics
                - days_since_last_order, first_order_date, last_order_date: Recency
                - rfm_score, rfm_segment, rfm_category: RFM analysis
                - churn_risk (High/Medium/Low): Churn prediction
                - cohort_period: Customer acquisition cohort
            """,
            'mart_product_analytics': """
                Product analytics with profitability and inventory metrics.
                Key columns:
                - productid, product_name, category_name, subcategory_name: Product info
                - total_revenue, total_quantity_sold, profit_margin_percent: Sales metrics
                - inventory_status, current_inventory, safety_stock_level: Inventory
                - monthly_sales_velocity, inventory_turnover_ratio: Performance
                - top_related_product_id, co_purchase_count: Market basket
                - product_lifecycle_stage: Lifecycle analysis
            """,
            'mart_operations': """
                Operations mart combining purchase orders and work orders.
                Key columns:
                - operation_type (purchase_order/work_order): Operation category
                - operation_id, operation_date: Identifiers
                - vendor_key, vendor_name: Vendor info (for POs)
                - product_key, product_name: Product info
                - total_amount, cost_variance: Financial metrics
                - rejection_rate_percent, fulfillment_rate_percent: Quality metrics
                - scrap_rate_percent, production_days: Production metrics
            """,
            'mart_employee_territory_performance': """
                Employee and territory performance tracking.
                Key columns:
                - performance_type (employee/territory): Record type
                - performance_id, performance_name: Identifiers
                - monthly_revenue, total_revenue: Sales metrics
                - quota_amount, quota_achievement_percent, quota_status: Quota tracking
                - territory_name, territory_group: Territory info
            """,
            'fact_global_metrics': """
                Unified metrics fact table in "tall" format.
                Key columns:
                - metric_key: Links to dim_metric for metric definitions
                - metric_value: The numeric value
                - date_key, report_date: Time dimensions
                - customer_key, product_key, employee_key, territory_key, vendor_key: Dimension keys
                - metric_category, metric_unit, metric_level: From dim_metric
                Use this table for cross-domain metric analysis and time series.
            """,
            'dim_customer': """
                Customer dimension with segmentation.
                Key columns: customerid, customer_name, lifetime_value, customer_segment, customer_status
            """,
            'dim_product': """
                Product dimension with category hierarchy.
                Key columns: productid, product_name, category_name, subcategory_name, product_status
            """,
            'dim_territory': """
                Sales territory dimension.
                Key columns: territoryid, territory_name, countryregioncode, territory_group, total_revenue
            """,
            'dim_date': """
                Date dimension for time-based analysis.
                Key columns: date_key (YYYYMMDD), date_day, year, quarter, month, day_of_week, season
            """,
            'dim_metric': """
                Metrics catalog - single source of truth for all metric definitions.
                Key columns: metric_key, metric_name, metric_description, metric_category, metric_unit, metric_level
            """
        }
        
        self._tables_cache = tables
        return tables
    
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
                    metrics_context += f"- {row['metric_key']}: {row['metric_name']} ({row['metric_unit']}) - {row['metric_description'][:100]}...\n"
        
        # Build table context
        tables_context = "\n".join([
            f"### {table}\n{desc.strip()}\n"
            for table, desc in tables.items()
        ])
        
        # Build examples context
        examples_context = "\n\n".join([
            f"Question: {q}\nSQL:\n```sql\n{sql}\n```"
            for q, sql in examples
        ])
        
        return f"""You are a SQL expert for the AdventureWorks data warehouse running on PostgreSQL.
Your job is to convert natural language questions into accurate SQL queries.

## Database Schema

### Available Tables:
{tables_context}

## Available Metrics (from dim_metric):
{metrics_context}

## Important Rules:
1. ONLY generate SELECT queries - no INSERT, UPDATE, DELETE, DROP, or any DDL
2. Always use table aliases for clarity
3. Use appropriate aggregations (SUM, AVG, COUNT, etc.) for metrics
4. Include ORDER BY for sorted results
5. Use LIMIT for top-N queries (default to 10-20 for large result sets)
6. Handle NULL values appropriately with COALESCE or WHERE filters
7. Use proper date filtering for time-based queries
8. Join tables only when necessary - prefer using marts which are pre-joined
9. Format column names to be human-readable in output

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
dim_customer, dim_product, dim_territory, dim_date, dim_metric.

Key fields:
- Revenue/Sales: order_total, net_line_amount, total_revenue, lifetime_value
- Time: order_date, order_year, order_month, order_season, date_key
- Customer: customer_name, customer_segment, customer_status, churn_risk
- Product: product_name, category_name, subcategory_name
- Geography: territory_name, countryregioncode, territory_group

Return ONLY the SQL query, no explanations."""
