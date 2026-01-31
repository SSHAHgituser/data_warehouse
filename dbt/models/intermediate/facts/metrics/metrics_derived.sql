{{ config(materialized='view') }}

{#
    Derived/Strategic Metrics
    =========================
    Calculates higher-level metrics (L3-L5) by aggregating from operational data.
    These metrics complete the metrics hierarchy from operational to KPIs.
    
    Metrics included:
    - TOTAL_REVENUE: Sum of all sales order revenue
    - GROSS_PROFIT: Sum of all line item profits
    - GROSS_MARGIN: Gross profit as % of revenue
    - INVENTORY_TURNOVER: Estimated inventory turns
    - CUSTOMER_SATISFACTION: Composite delivery score
    - PRODUCTION_EFFICIENCY: Production cost efficiency
    - SUPPLIER_QUALITY: Average supplier rejection rate (inverted)
    - SUPPLIER_RELIABILITY: Average supplier fulfillment rate
    - SALES_PERFORMANCE: Average quota achievement across team
    
    Granularity: One row per metric (company-wide aggregates)
    
    Note: metric_name, metric_category, metric_unit come from dim_metric
#}

with report_date_calc as (
    select max(orderdate)::date as report_date
    from {{ ref('stg_salesorderheader') }}
),

-- Aggregate sales order data
sales_aggregates as (
    select
        sum(totaldue) as total_revenue,
        sum(subtotal) as total_subtotal,
        avg(coalesce(days_to_ship, 0)) as avg_days_to_ship,
        count(*) as order_count
    from {{ ref('fact_sales_order') }}
),

-- Aggregate sales line data
sales_line_aggregates as (
    select
        sum(coalesce(total_profit, 0)) as gross_profit,
        sum(net_line_amount) as total_line_revenue
    from {{ ref('fact_sales_order_line') }}
),

-- Aggregate inventory data
inventory_aggregates as (
    select
        sum(quantity) as total_inventory_qty,
        sum(coalesce(inventory_value, 0)) as total_inventory_value,
        avg(coalesce(inventory_value, 0)) as avg_inventory_value
    from {{ ref('fact_inventory') }}
),

-- Aggregate purchase order data
purchase_aggregates as (
    select
        avg(coalesce(rejection_rate_percent, 0)) as avg_rejection_rate,
        avg(coalesce(fulfillment_rate_percent, 0)) as avg_fulfillment_rate,
        sum(totaldue) as total_purchase_amount
    from {{ ref('fact_purchase_order') }}
),

-- Aggregate work order data
work_order_aggregates as (
    select
        sum(coalesce(total_planned_cost, 0)) as total_planned_cost,
        sum(coalesce(total_actual_cost, 0)) as total_actual_cost,
        avg(coalesce(cost_variance_percent, 0)) as avg_cost_variance_pct,
        avg(coalesce(scrap_rate_percent, 0)) as avg_scrap_rate
    from {{ ref('fact_work_order') }}
),

-- Aggregate employee quota data
quota_aggregates as (
    select
        avg(coalesce(quota_achievement_percent, 0)) as avg_quota_achievement,
        sum(salesquota) as total_quota,
        sum(coalesce(salesytd, 0)) as total_sales_ytd,
        count(*) as employee_count
    from {{ ref('fact_employee_quota') }}
),

-- Calculate derived metrics
derived_metrics as (
    select
        (select report_date from report_date_calc) as report_date,
        
        -- TOTAL_REVENUE: Sum of all sales
        sa.total_revenue,
        
        -- GROSS_PROFIT: Sum of line item profits
        sla.gross_profit,
        
        -- GROSS_MARGIN: Profit / Revenue * 100
        case 
            when sa.total_revenue > 0 
            then (sla.gross_profit / sa.total_revenue) * 100 
            else 0 
        end as gross_margin,
        
        -- INVENTORY_TURNOVER: Approximation using total purchases / avg inventory
        case 
            when ia.avg_inventory_value > 0 
            then pa.total_purchase_amount / ia.avg_inventory_value 
            else 0 
        end as inventory_turnover,
        
        -- CUSTOMER_SATISFACTION: Composite score (100 - normalized days to ship penalty)
        -- Lower days to ship = higher satisfaction
        case 
            when sa.avg_days_to_ship <= 3 then 90
            when sa.avg_days_to_ship <= 5 then 75
            when sa.avg_days_to_ship <= 7 then 60
            else 50
        end as customer_satisfaction_score,
        
        -- PRODUCTION_EFFICIENCY: 100 - avg cost variance (capped)
        greatest(0, 100 - abs(woa.avg_cost_variance_pct)) as production_efficiency,
        
        -- SUPPLIER_QUALITY: 100 - rejection rate
        100 - pa.avg_rejection_rate as supplier_quality,
        
        -- SUPPLIER_RELIABILITY: Direct fulfillment rate
        pa.avg_fulfillment_rate as supplier_reliability,
        
        -- SALES_PERFORMANCE: Average quota achievement
        qa.avg_quota_achievement as sales_performance
        
    from sales_aggregates sa
    cross join sales_line_aggregates sla
    cross join inventory_aggregates ia
    cross join purchase_aggregates pa
    cross join work_order_aggregates woa
    cross join quota_aggregates qa
)

-- Unpivot to tall format
select
    cast(to_char(report_date, 'YYYYMMDD') as integer) as date_key,
    report_date,
    'derived' as source_table,
    1::bigint as source_record_id,
    metric_key,
    metric_value
from derived_metrics
cross join lateral (
    values
        ('TOTAL_REVENUE', total_revenue::numeric),
        ('GROSS_PROFIT', gross_profit::numeric),
        ('GROSS_MARGIN', gross_margin::numeric),
        ('INVENTORY_TURNOVER', inventory_turnover::numeric),
        ('CUSTOMER_SATISFACTION', customer_satisfaction_score::numeric),
        ('PRODUCTION_EFFICIENCY', production_efficiency::numeric),
        ('SUPPLIER_QUALITY', supplier_quality::numeric),
        ('SUPPLIER_RELIABILITY', supplier_reliability::numeric),
        ('SALES_PERFORMANCE', sales_performance::numeric)
) as metrics(metric_key, metric_value)
where metric_value is not null
