# Mart Models - Consolidated Analytics Tables

This directory contains consolidated mart tables that combine dimensions and facts to support comprehensive analytics with minimal table joins.

## Mart Tables Overview

### 1. mart_sales
**Purpose**: Consolidated sales transactions with all dimensions  
**Grain**: One row per sales order line item  
**Supports**:
- Sales performance analysis
- Customer analytics
- Product sales trends
- Territory analysis
- Employee performance
- Time series forecasting
- Market basket analysis

**Key Features**:
- Combines `fact_sales_order` and `fact_sales_order_line`
- Includes customer, product, employee, territory, and date dimensions
- Pre-calculated metrics (profit, margins, shipping speed)
- Supports both order-level and line-item-level analysis

### 2. mart_customer_analytics
**Purpose**: Customer-level analytics and segmentation  
**Grain**: One row per customer  
**Supports**:
- Customer Lifetime Value (CLV)
- Customer segmentation
- Churn prediction
- RFM analysis
- Customer journey mapping
- Cohort analysis

**Key Features**:
- Pre-calculated RFM scores and categories
- Churn risk assessment
- Customer cohort identification
- Favorite product category
- Lifetime value and profitability metrics

### 3. mart_product_analytics
**Purpose**: Product-level analytics with inventory  
**Grain**: One row per product  
**Supports**:
- Product profitability analysis
- Sales trends and seasonality
- Inventory optimization
- Product recommendations (market basket)
- BOM cost analysis
- Product lifecycle tracking

**Key Features**:
- Inventory status and turnover ratios
- Market basket analysis (top related products)
- Sales velocity and lifecycle stage
- Profitability metrics
- Inventory optimization indicators

### 4. mart_operations
**Purpose**: Operations data (purchasing and manufacturing)  
**Grain**: One row per purchase order or work order  
**Supports**:
- Vendor performance analysis
- Production efficiency
- Inventory management
- Supply chain optimization
- Quality metrics (rejection rates, scrap rates)

**Key Features**:
- Combines purchase orders and work orders
- Vendor performance metrics
- Production cost variance analysis
- Quality metrics (rejection rates, fulfillment rates)
- Delivery performance

### 5. mart_employee_territory_performance
**Purpose**: Employee and territory performance tracking  
**Grain**: One row per employee/territory per time period  
**Supports**:
- Employee performance tracking
- Territory analysis
- Sales quota tracking
- Compensation analysis
- Workforce planning

**Key Features**:
- Monthly performance metrics
- Quota achievement tracking
- Territory performance comparison
- Employee tenure and experience

## Analytics Use Cases Supported

All 24 analytics use cases are supported by these 5 mart tables:

### Sales & Revenue Analytics ✅
- Customer Lifetime Value → `mart_customer_analytics.lifetime_value`
- Sales performance by territory → `mart_sales` + territory dimensions
- Product sales trends → `mart_product_analytics` or `mart_sales`
- Sales funnel analysis → `mart_sales` with date dimensions
- Customer segmentation → `mart_customer_analytics.customer_segment`

### Product & Inventory Analytics ✅
- Product profitability → `mart_product_analytics.profit_margin_percent`
- Inventory optimization → `mart_product_analytics.inventory_status`
- Product recommendations → `mart_product_analytics.top_related_product_id`
- BOM cost analysis → `mart_product_analytics` with cost data

### Customer Analytics ✅
- Customer churn prediction → `mart_customer_analytics.churn_risk`
- Customer journey mapping → `mart_sales` with date keys
- RFM analysis → `mart_customer_analytics` (RFM scores and categories)

### Human Resources Analytics ✅
- Employee performance → `mart_employee_territory_performance`
- Compensation analysis → `mart_employee_territory_performance`
- Workforce planning → `mart_employee_territory_performance`

### Operations & Supply Chain ✅
- Vendor performance → `mart_operations` (vendor metrics)
- Production efficiency → `mart_operations` (work order metrics)
- Shipping & logistics → `mart_sales.days_to_ship`

### Advanced Analytics ✅
- Time series forecasting → All marts have date dimensions
- Cohort analysis → `mart_customer_analytics.cohort_period`
- Market basket analysis → `mart_product_analytics.top_related_product_id`
- Geographic analysis → `mart_sales` with territory dimensions
- Price elasticity → `mart_sales` with pricing data

## Usage Examples

### Customer Lifetime Value Analysis
```sql
select
    customer_segment,
    customer_status,
    avg(lifetime_value) as avg_clv,
    count(*) as customer_count
from {{ ref('mart_customer_analytics') }}
group by customer_segment, customer_status
```

### Product Sales Performance
```sql
select
    category_name,
    product_name,
    sum(net_line_amount) as total_revenue,
    sum(total_profit) as total_profit,
    avg(profit_margin_percent) as avg_margin
from {{ ref('mart_sales') }}
where order_year = 2013
group by category_name, product_name
order by total_revenue desc
```

### Territory Performance
```sql
select
    territory_name,
    countryregioncode,
    sum(order_total) as total_revenue,
    count(distinct customer_key) as unique_customers,
    avg(order_total) as avg_order_value
from {{ ref('mart_sales') }}
where order_year = 2013
group by territory_name, countryregioncode
```

### Inventory Optimization
```sql
select
    product_name,
    category_name,
    inventory_status,
    total_inventory_quantity,
    monthly_sales_velocity,
    days_of_inventory
from {{ ref('mart_product_analytics') }}
where inventory_status in ('Out of Stock', 'Below Safety Stock')
order by total_inventory_value desc
```

### Vendor Performance
```sql
select
    vendor_name,
    vendor_type,
    count(distinct operation_id) as total_orders,
    avg(rejection_rate_percent) as avg_rejection_rate,
    avg(days_to_ship) as avg_delivery_days
from {{ ref('mart_operations') }}
where operation_type = 'purchase_order'
group by vendor_name, vendor_type
order by avg_rejection_rate
```

## Model Dependencies

```
intermediate/dimensions
    ↓
intermediate/facts
    ↓
marts (consolidated analytics tables)
```

## Materialization

All mart models are materialized as `table` for optimal query performance.

## Running the Models

```bash
# Run all mart models
dbt run --models marts.*

# Run specific mart
dbt run --models mart_sales
dbt run --models mart_customer_analytics
```

