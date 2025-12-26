# Intermediate Models - Dimensions and Facts

This directory contains the dimensional model (star schema) for AdventureWorks analytics. The models are organized into dimensions and facts to support comprehensive business intelligence and analytics.

## Model Structure

### Dimension Tables

Dimension tables contain descriptive attributes and are typically smaller, denormalized tables:

1. **dim_customer** - Customer information with demographics, sales history, and segmentation
2. **dim_product** - Product catalog with category hierarchy, pricing, and sales performance
3. **dim_date** - Date dimension for time-based analysis (2011-2014)
4. **dim_employee** - Employee information with HR data and sales performance
5. **dim_territory** - Sales territory information with performance metrics
6. **dim_vendor** - Vendor information with purchase history and performance

### Fact Tables

Fact tables contain measurable business events and metrics:

1. **fact_sales_order** - Sales orders (grain: one row per order)
2. **fact_sales_order_line** - Sales order line items (grain: one row per order line)
3. **fact_inventory** - Inventory levels (grain: one row per product/location)
4. **fact_purchase_order** - Purchase orders (grain: one row per purchase order)
5. **fact_work_order** - Manufacturing work orders (grain: one row per work order)
6. **fact_employee_quota** - Employee sales quotas (grain: one row per quota period)

## Analytics Use Cases Supported

### Sales & Revenue Analytics
- ✅ Customer Lifetime Value (CLV) - `dim_customer.lifetime_value`
- ✅ Sales performance by territory - `dim_territory` + `fact_sales_order`
- ✅ Product sales trends - `dim_product` + `fact_sales_order_line`
- ✅ Sales funnel analysis - `fact_sales_order` with date dimensions
- ✅ Customer segmentation - `dim_customer.customer_segment`

### Product & Inventory Analytics
- ✅ Product profitability - `dim_product.profit_margin_percent`
- ✅ Inventory optimization - `fact_inventory.inventory_status`
- ✅ Product recommendations - `fact_sales_order_line` for market basket analysis
- ✅ BOM cost analysis - `dim_product` with cost history

### Customer Analytics
- ✅ Customer churn prediction - `dim_customer.customer_status`
- ✅ Customer journey mapping - `fact_sales_order` with date keys
- ✅ RFM analysis - `dim_customer` fields support this

### Human Resources Analytics
- ✅ Employee performance - `dim_employee.quota_achievement_percent`
- ✅ Compensation analysis - `dim_employee` with pay history
- ✅ Workforce planning - `dim_employee` with department info

### Operations & Supply Chain
- ✅ Vendor performance - `dim_vendor` + `fact_purchase_order`
- ✅ Production efficiency - `fact_work_order` with cost variance
- ✅ Shipping & logistics - `fact_sales_order.days_to_ship`

### Advanced Analytics
- ✅ Time series forecasting - All facts have date keys
- ✅ Cohort analysis - `dim_customer` + date dimensions
- ✅ Market basket analysis - `fact_sales_order_line`
- ✅ Geographic analysis - `dim_territory` + `dim_customer`
- ✅ Price elasticity - `dim_product` + `fact_sales_order_line`

## Usage Examples

### Customer Lifetime Value Analysis
```sql
select
    customer_segment,
    customer_status,
    avg(lifetime_value) as avg_clv,
    count(*) as customer_count
from {{ ref('dim_customer') }}
group by customer_segment, customer_status
```

### Product Sales Performance
```sql
select
    p.category_name,
    p.product_name,
    sum(fsol.net_line_amount) as total_revenue,
    sum(fsol.total_profit) as total_profit
from {{ ref('fact_sales_order_line') }} fsol
join {{ ref('dim_product') }} p on fsol.product_key = p.productid
join {{ ref('dim_date') }} d on fsol.order_date_key = d.date_key
where d.year = 2013
group by p.category_name, p.product_name
order by total_revenue desc
```

### Territory Performance
```sql
select
    t.territory_name,
    t.countryregioncode,
    count(distinct fso.salesorderid) as order_count,
    sum(fso.totaldue) as total_revenue,
    avg(fso.totaldue) as avg_order_value
from {{ ref('fact_sales_order') }} fso
join {{ ref('dim_territory') }} t on fso.territory_key = t.territoryid
join {{ ref('dim_date') }} d on fso.order_date_key = d.date_key
where d.year = 2013
group by t.territory_name, t.countryregioncode
```

### Inventory Status
```sql
select
    p.product_name,
    p.category_name,
    fi.inventory_status,
    fi.quantity,
    fi.inventory_value
from {{ ref('fact_inventory') }} fi
join {{ ref('dim_product') }} p on fi.product_key = p.productid
where fi.inventory_status in ('Out of Stock', 'Below Safety Stock')
order by fi.inventory_value desc
```

## Model Dependencies

```
staging models
    ↓
intermediate/dimensions
    ↓
intermediate/facts (join dimensions)
```

## Materialization

- **Dimensions**: Materialized as `table` for better query performance
- **Facts**: Materialized as `table` for better query performance
- All models are tagged appropriately (`dimension` or `fact`)

## Running the Models

```bash
# Run all intermediate models
dbt run --models intermediate.*

# Run only dimensions
dbt run --models intermediate.dimensions.*

# Run only facts
dbt run --models intermediate.facts.*

# Run specific model
dbt run --models dim_customer
```

