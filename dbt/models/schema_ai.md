# AdventureWorks Data Warehouse Schema (AI Context)

> **Database:** data_warehouse | **Schema:** dbt | Tables can be queried without schema prefix.
> 
> *Auto-generated on 2026-01-31 13:54 by generate_ai_schema.py*

⚠️ **IMPORTANT: Use EXACT table names below. Names are SINGULAR (e.g., `dim_metric` NOT `dim_metrics`).**

## Quick Reference

**USE THESE TABLES** (pre-joined, no manual joins needed):
- `mart_customer_analytics` - CLV, RFM, churn prediction
- `mart_employee_territory_performance` - Quotas, performance
- `mart_metrics` - ⭐ **ALL METRICS** with definitions, targets, categories
- `mart_operations` - Purchase orders, work orders
- `mart_product_analytics` - Product performance, inventory
- `mart_sales` - Sales with customer, product, territory

---

## Mart Tables ⭐ (Preferred - Pre-joined)

### mart_customer_analytics

Customer analytics mart with CLV, segmentation, RFM analysis, churn prediction, and cohort analysis

| Column | Description |
|--------|-------------|
| customerid | Customer identifier |
| customer_segment | Customer value segment |
| customer_status | Customer activity status |
| lifetime_value | Customer lifetime value |
| rfm_segment | RFM score combination |
| rfm_category | RFM category (Champions/Loyal/New/At Risk/Lost) |
| churn_risk | Churn risk level (High/Medium/Low) |
| cohort_period | Customer cohort period |

### mart_employee_territory_performance

Employee and territory performance mart - supports employee performance tracking, territory analysis, and quota achievement

| Column | Description |
|--------|-------------|
| performance_type | Type (employee/territory) |
| performance_id | Employee or territory ID |
| monthly_revenue | Monthly revenue |
| quota_achievement_percent | Quota achievement percentage |
| quota_status | Quota status |
| territory_performance | Territory performance category |

### mart_metrics

Metrics mart - joins fact_global_metrics with dim_metric for complete metric information.

| Column | Type | Description |
|--------|------|-------------|
| metric_record_id | INT | Surrogate key |
| date_key | INT | Date key (YYYYMMDD) |
| report_date | DATE | Snapshot date |
| metric_key | TEXT | Metric identifier (FK to dim_metric) |
| metric_name | TEXT | Human-readable metric name |
| metric_description | TEXT | Business definition of the metric |
| metric_category | TEXT | Category: Sales, Inventory, HR, Operations |
| metric_unit | TEXT | Unit: USD, Count, Percent, Days |
| metric_level | TEXT | Hierarchy level: L1-L5 |
| metric_parent | TEXT | Parent metric key (for drill-down) |
| metric_target | TEXT ⚠️ | Target description (TEXT, not numeric - e.g. "YoY growth >= 10%") |
| alert_criteria | TEXT | Conditions for alerting (TEXT description) |
| recommended_actions | TEXT | Suggested actions (TEXT description) |
| **metric_value** | NUMERIC ✅ | **The numeric metric value - USE THIS for aggregations** |
| source_table | TEXT | Source fact table name |
| customer_key | INT | FK to dim_customer |
| product_key | INT | FK to dim_product |
| employee_key | INT | FK to dim_employee |
| territory_key | INT | FK to dim_territory |
| vendor_key | INT | FK to dim_vendor |

**⚠️ IMPORTANT**: Only `metric_value` is numeric! Do NOT use AVG/SUM on `metric_target`, `alert_criteria`, or `recommended_actions` - they are TEXT.

**📊 FORMAT VALUES BY `metric_unit`:**
| metric_unit | Format | Example |
|-------------|--------|---------|
| USD | Currency with $ and commas | $1,234,567.89 |
| Percent | Percentage with % | 85.5% |
| Count | Integer with commas | 1,234 |
| Days | Number + "days" | 5.2 days |
| Hours | Number + "hours" | 48 hours |
| Ratio | Decimal (2 places) | 1.25 |

### mart_operations

Operations mart combining purchase orders and work orders - supports vendor performance, production efficiency, and supply chain optimization

| Column | Description |
|--------|-------------|
| operation_type | Type of operation (purchase_order/work_order) |
| operation_id | Operation identifier |
| vendor_name | Vendor name |
| rejection_rate_percent | Rejection rate percentage |
| fulfillment_rate_percent | Fulfillment rate percentage |
| cost_variance | Cost variance (actual vs planned) |
| scrap_rate_percent | Scrap rate percentage |

### mart_product_analytics

Product analytics mart with profitability, sales trends, inventory optimization, and market basket analysis

| Column | Description |
|--------|-------------|
| productid | Product identifier |
| category_name | Product category |
| total_revenue | Total product revenue |
| profit_margin_percent | Profit margin percentage |
| inventory_status | Current inventory status |
| top_related_product_id | Most frequently co-purchased product |
| monthly_sales_velocity | Average monthly sales velocity |
| inventory_turnover_ratio | Inventory turnover ratio |
| product_lifecycle_stage | Product lifecycle stage |

### mart_sales

Consolidated sales mart with all dimensions - supports sales performance, customer analytics, product sales, territory analysis, employee performance, time series, and market basket analysis

| Column | Description |
|--------|-------------|
| salesorderid | Sales order ID |
| salesorderdetailid | Sales order detail ID |
| customer_segment | Customer value segment |
| customer_status | Customer activity status |
| product_status | Product status |
| order_total | Total order amount |
| net_line_amount | Net line item amount after discounts |
| total_profit | Profit for line item |
| shipping_speed_category | Shipping speed (Fast/Normal/Slow) |

---

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

-- All metrics with values and descriptions (USE mart_metrics!)
SELECT metric_name, metric_category, metric_value, metric_unit, metric_target, recommended_actions
FROM mart_metrics ORDER BY metric_category, metric_name

-- Metrics aggregated by category (ONLY aggregate metric_value, not text columns!)
SELECT metric_category, 
       COUNT(*) as metric_count, 
       AVG(metric_value) as avg_value,
       SUM(metric_value) as total_value
FROM mart_metrics GROUP BY metric_category ORDER BY metric_count DESC

-- Business performance summary (show metrics with their targets and actions)
SELECT metric_category, metric_name, metric_value, metric_unit, metric_target, recommended_actions
FROM mart_metrics WHERE metric_level IN ('L4_Strategic', 'L5_KPI')
ORDER BY metric_category, metric_name
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

### dim_customer
`customerid, lifetime_value, customer_segment, customer_status, purchase_frequency`

### dim_date
`date_key, date_day, year, quarter, month, season`

### dim_employee
`employee_id, jobtitle, department_name, sales_year_to_date, quota_achievement_percent`

### dim_metric
`metric_id, metric_key, metric_name, metric_category, metric_unit, metric_level, metric_parent, metric_children, metric_description, metric_target`

### dim_product
`productid, product_name, category_name, total_revenue, profit_margin_percent, product_status`

### dim_territory
`territoryid, territory_name, countryregioncode, total_revenue, performance_category`

### dim_vendor
`vendor_id, vendor_name, total_purchase_amount, avg_delivery_days, vendor_status`

---

## Fact Tables (Use marts instead when possible)

### fact_employee_quota
Employee quota fact - one row per quota period

### fact_global_metrics
Unified metrics fact table - "tall" format with one row per metric value.

### fact_inventory
Inventory fact - one row per product/location

### fact_purchase_order
Purchase order fact - one row per PO

### fact_sales_order
Sales order fact - one row per order

### fact_sales_order_line
Sales order line fact - one row per line item

### fact_work_order
Work order fact - one row per work order

---

## SQL Guidelines

1. **Use EXACT table names** - `dim_metric` NOT `dim_metrics`, `mart_sales` NOT `mart_sale`
2. **Always use mart tables** - they have everything pre-joined
3. **Use mart_metrics for any metric queries** - it has all metric definitions
4. Use `SUM()`, `AVG()`, `COUNT()` for aggregations (only on numeric columns!)
5. Include `ORDER BY` for sorted results
6. Use `LIMIT` for top-N (default 10-20)
7. Filter NULLs: `WHERE column IS NOT NULL`
8. Time filters: `WHERE order_year = 2014`

## Response Format

Return ONLY the SQL query. No explanations, no markdown formatting.
If the question cannot be answered, respond with: `-- ERROR: [reason]`
