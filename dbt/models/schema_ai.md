# AdventureWorks Data Warehouse Schema (AI Context)

> **Database:** data_warehouse | **Schema:** dbt | Tables can be queried without schema prefix.

## Quick Reference

**USE THESE TABLES** (pre-joined, no manual joins needed):
- `mart_sales` - Sales with customer, product, territory
- `mart_customer_analytics` - CLV, RFM, churn prediction
- `mart_product_analytics` - Product performance, inventory
- `mart_operations` - Purchase orders, work orders
- `mart_employee_territory_performance` - Quotas, performance
- `mart_metrics` - All metrics with names, categories (from dim_metric)

---

## mart_sales ⭐ (Primary table for most queries)

Sales transactions with all dimensions pre-joined. One row per line item.

| Column | Description |
|--------|-------------|
| salesorderid | Order ID |
| salesorderdetailid | Line item ID |
| order_date | Order date |
| order_year | Year (2011-2014) |
| order_month | Month (1-12) |
| order_season | Spring/Summer/Fall/Winter |
| customer_key | FK to customer |
| customer_name | Customer full name |
| customer_segment | High Value/Medium Value/Low Value |
| customer_status | Active/At Risk/Inactive |
| product_key | FK to product |
| product_name | Product name |
| category_name | Product category (Bikes, Components, Clothing, Accessories) |
| subcategory_name | Product subcategory |
| territory_key | FK to territory |
| territory_name | Territory (Northwest, Southwest, etc.) |
| countryregioncode | Country code (US, CA, GB, DE, FR, AU) |
| territory_group | North America/Europe/Pacific |
| employee_key | FK to salesperson |
| salesperson_name | Sales rep name |
| order_total | Total order amount ($) |
| net_line_amount | Line amount after discount ($) |
| total_profit | Profit ($) |
| orderqty | Quantity ordered |
| unitprice | Unit price ($) |
| unitpricediscount | Discount amount |
| has_discount | true/false |
| online_order_flag | true/false |
| shipping_speed_category | Fast/Normal/Slow |

**Common queries:**
```sql
-- Revenue by territory
SELECT territory_name, SUM(order_total) as revenue FROM mart_sales GROUP BY territory_name ORDER BY revenue DESC

-- Monthly trend
SELECT order_year, order_month, SUM(order_total) as revenue FROM mart_sales GROUP BY order_year, order_month ORDER BY order_year, order_month

-- Top products
SELECT product_name, SUM(net_line_amount) as revenue FROM mart_sales GROUP BY product_name ORDER BY revenue DESC LIMIT 10
```

---

## mart_customer_analytics

Customer-level analytics. One row per customer.

| Column | Description |
|--------|-------------|
| customerid | Customer ID (PK) |
| customer_name | Full name |
| email_address | Email |
| lifetime_value | Total revenue from customer ($) |
| order_count | Number of orders |
| avg_order_value | Average order ($) |
| first_order_date | First purchase date |
| last_order_date | Most recent purchase |
| days_since_last_order | Days since last order |
| customer_segment | High Value/Medium Value/Low Value |
| customer_status | Active/At Risk/Inactive |
| purchase_frequency | Frequent/Regular/Occasional |
| rfm_score | RFM score (1-5 each) |
| rfm_segment | Combined RFM |
| rfm_category | Champions/Loyal/At Risk/Lost/etc. |
| churn_risk | High/Medium/Low |
| cohort_period | First purchase year-month |

**Common queries:**
```sql
-- High value customers
SELECT customer_name, lifetime_value, order_count FROM mart_customer_analytics WHERE customer_segment = 'High Value' ORDER BY lifetime_value DESC

-- Churn risk
SELECT customer_name, lifetime_value, days_since_last_order, churn_risk FROM mart_customer_analytics WHERE churn_risk = 'High'

-- RFM segments
SELECT rfm_category, COUNT(*) as customers, AVG(lifetime_value) as avg_clv FROM mart_customer_analytics GROUP BY rfm_category
```

---

## mart_product_analytics

Product-level analytics. One row per product.

| Column | Description |
|--------|-------------|
| productid | Product ID (PK) |
| product_name | Product name |
| category_name | Category |
| subcategory_name | Subcategory |
| total_revenue | Total sales ($) |
| total_quantity_sold | Units sold |
| total_profit | Profit ($) |
| profit_margin_percent | Margin % |
| avg_unit_price | Avg selling price ($) |
| order_count | Number of orders |
| inventory_status | In Stock/Out of Stock/Low Stock |
| current_inventory | Current qty |
| safety_stock_level | Min stock level |
| monthly_sales_velocity | Avg monthly sales |
| inventory_turnover_ratio | Turnover rate |
| product_lifecycle_stage | Growth/Mature/Decline |
| top_related_product_id | Most co-purchased product |

---

## mart_operations

Purchase orders and work orders combined.

| Column | Description |
|--------|-------------|
| operation_type | 'purchase_order' or 'work_order' |
| operation_id | PO or WO ID |
| operation_date | Date |
| vendor_key | Vendor FK (for POs) |
| vendor_name | Vendor name |
| product_key | Product FK |
| product_name | Product name |
| total_amount | Total cost ($) |
| quantity_ordered | Qty ordered |
| quantity_received | Qty received |
| rejection_rate_percent | Rejection % |
| fulfillment_rate_percent | Fulfillment % |
| cost_variance | Actual - planned ($) |
| scrap_rate_percent | Scrap % (for WOs) |
| production_days | Days to complete |

---

## mart_employee_territory_performance

Employee and territory performance. Has two types of rows.

| Column | Description |
|--------|-------------|
| performance_type | 'employee' or 'territory' |
| performance_id | Employee or Territory ID |
| performance_name | Name |
| monthly_revenue | Monthly sales ($) |
| total_revenue | Total sales ($) |
| quota_amount | Sales quota ($) |
| quota_achievement_percent | % of quota achieved |
| quota_status | Achieved/Near Target/Below Target |
| order_count | Number of orders |
| customer_count | Customers served |
| territory_name | Territory (for employees) |
| territory_group | Region |

---

## Dimension Tables (for manual joins if needed)

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

### dim_customer
`customerid`, customer_name, email_address, lifetime_value, customer_segment, customer_status, purchase_frequency

### dim_product
`productid`, product_name, category_name, subcategory_name, listprice, standardcost, product_status

### dim_territory
`territoryid`, territory_name, countryregioncode, territory_group, total_revenue, performance_category

### dim_date
`date_key` (YYYYMMDD), date_day, year, quarter, month, day_of_week, day_name, month_name, season, is_weekend

### dim_employee
`employee_id`, first_name, last_name, jobtitle, department_name, hire_date, sales_year_to_date, quota_achievement_percent

### dim_vendor
`vendor_id`, vendor_name, credit_rating, active_flag, total_purchase_amount, avg_delivery_days

### dim_metric
`metric_key`, metric_name, metric_description, metric_category (Sales/Inventory/HR/etc.), metric_unit (USD/Count/Percent/Days)

---

## mart_metrics ⭐ (For metric queries)

Joins fact_global_metrics with dim_metric. **Use this for all metric-related queries.**

| Column | Description |
|--------|-------------|
| metric_record_id | Surrogate key |
| date_key | Date (YYYYMMDD) |
| metric_key | Metric identifier |
| metric_name | Human-readable name |
| metric_category | Sales/Inventory/HR/Operations |
| metric_unit | USD/Count/Percent/Days |
| metric_level | L1-L5 hierarchy |
| metric_value | The numeric value |
| customer_key, product_key, territory_key | Dimension FKs |

**Common queries:**
```sql
-- Total by metric category
SELECT metric_category, SUM(metric_value) as total FROM mart_metrics WHERE metric_unit = 'USD' GROUP BY metric_category

-- Specific metric trend
SELECT date_key, metric_value FROM mart_metrics WHERE metric_name = 'Sales Order Revenue' ORDER BY date_key
```

---

## Fact Tables (prefer marts instead)

### fact_global_metrics
Unified metrics in tall format. **Use mart_metrics instead** - it has metric names pre-joined.
- metric_key (FK to dim_metric), metric_value, date_key
- customer_key, product_key, employee_key, territory_key, vendor_key

### fact_sales_order / fact_sales_order_line
Raw sales data. **Use mart_sales instead.**

### fact_inventory
Product inventory by location.
- product_key, location_key, quantity, inventory_value, inventory_status

### fact_purchase_order / fact_work_order
Supply chain data. **Use mart_operations instead.**

---

## SQL Guidelines

1. **Always use mart tables** - they have everything pre-joined
2. Use `SUM()`, `AVG()`, `COUNT()` for aggregations
3. Include `ORDER BY` for sorted results
4. Use `LIMIT` for top-N (default 10-20)
5. Filter NULLs: `WHERE column IS NOT NULL`
6. Time filters: `WHERE order_year = 2014` or `WHERE order_date >= '2014-01-01'`

## Response Format

Return ONLY the SQL query. No explanations, no markdown formatting.
