{{ config(materialized='view') }}

{#
    Derived/Strategic Metrics
    =========================
    Calculates higher-level metrics (L3-L5) by aggregating from individual metrics tables.
    This ensures consistency - derived metrics use the same source as operational metrics.
    
    Metrics included:
    - TOTAL_REVENUE: Sum of SO_REVENUE from metrics_sales_order
    - GROSS_PROFIT: Sum of SOL_PROFIT from metrics_sales_line
    - GROSS_MARGIN: GROSS_PROFIT / TOTAL_REVENUE * 100
    - INVENTORY_TURNOVER: Estimated from inventory and purchase metrics
    - CUSTOMER_SATISFACTION: Based on SO_DAYS_TO_SHIP
    - PRODUCTION_EFFICIENCY: Based on WO_COST_VARIANCE_PCT
    - SUPPLIER_QUALITY: Based on PO_REJECTION_RATE
    - SUPPLIER_RELIABILITY: Based on PO_FULFILLMENT_RATE
    - SALES_PERFORMANCE: Based on EQ_ACHIEVEMENT_PCT
    
    Granularity: One row per metric (company-wide aggregates)
    
    Note: metric_name, metric_category, metric_unit come from dim_metric
#}

with report_date_calc as (
    select max(report_date) as report_date
    from {{ ref('metrics_sales_order') }}
),

-- Aggregate from metrics_sales_order
sales_order_agg as (
    select
        sum(case when metric_key = 'SO_REVENUE' then metric_value else 0 end) as total_revenue,
        avg(case when metric_key = 'SO_DAYS_TO_SHIP' then metric_value end) as avg_days_to_ship
    from {{ ref('metrics_sales_order') }}
),

-- Aggregate from metrics_sales_line
sales_line_agg as (
    select
        sum(case when metric_key = 'SOL_PROFIT' then metric_value else 0 end) as gross_profit,
        sum(case when metric_key = 'SOL_REVENUE' then metric_value else 0 end) as total_line_revenue
    from {{ ref('metrics_sales_line') }}
),

-- Aggregate from metrics_inventory
inventory_agg as (
    select
        sum(case when metric_key = 'INV_VALUE' then metric_value else 0 end) as total_inventory_value,
        avg(case when metric_key = 'INV_VALUE' then metric_value end) as avg_inventory_value
    from {{ ref('metrics_inventory') }}
),

-- Aggregate from metrics_purchase_order
purchase_agg as (
    select
        avg(case when metric_key = 'PO_REJECTION_RATE' then metric_value end) as avg_rejection_rate,
        avg(case when metric_key = 'PO_FULFILLMENT_RATE' then metric_value end) as avg_fulfillment_rate,
        sum(case when metric_key = 'PO_AMOUNT' then metric_value else 0 end) as total_purchase_amount
    from {{ ref('metrics_purchase_order') }}
),

-- Aggregate from metrics_work_order
work_order_agg as (
    select
        avg(case when metric_key = 'WO_COST_VARIANCE_PCT' then metric_value end) as avg_cost_variance_pct,
        avg(case when metric_key = 'WO_SCRAP_RATE' then metric_value end) as avg_scrap_rate
    from {{ ref('metrics_work_order') }}
),

-- Aggregate from metrics_employee_quota
quota_agg as (
    select
        avg(case when metric_key = 'EQ_ACHIEVEMENT_PCT' then metric_value end) as avg_quota_achievement
    from {{ ref('metrics_employee_quota') }}
),

-- Calculate derived metrics
derived_metrics as (
    select
        (select report_date from report_date_calc) as report_date,
        
        -- TOTAL_REVENUE: Sum of SO_REVENUE
        soa.total_revenue,
        
        -- GROSS_PROFIT: Sum of SOL_PROFIT
        sla.gross_profit,
        
        -- GROSS_MARGIN: Profit / Revenue * 100
        case 
            when soa.total_revenue > 0 
            then (sla.gross_profit / soa.total_revenue) * 100 
            else 0 
        end as gross_margin,
        
        -- INVENTORY_TURNOVER: Total purchases / avg inventory value
        case 
            when ia.avg_inventory_value > 0 
            then pa.total_purchase_amount / ia.avg_inventory_value 
            else 0 
        end as inventory_turnover,
        
        -- CUSTOMER_SATISFACTION: Score based on avg days to ship
        case 
            when soa.avg_days_to_ship <= 3 then 90
            when soa.avg_days_to_ship <= 5 then 75
            when soa.avg_days_to_ship <= 7 then 60
            else 50
        end as customer_satisfaction_score,
        
        -- PRODUCTION_EFFICIENCY: 100 - avg cost variance %
        greatest(0, 100 - abs(coalesce(woa.avg_cost_variance_pct, 0))) as production_efficiency,
        
        -- SUPPLIER_QUALITY: 100 - avg rejection rate
        100 - coalesce(pa.avg_rejection_rate, 0) as supplier_quality,
        
        -- SUPPLIER_RELIABILITY: Direct from avg fulfillment rate
        coalesce(pa.avg_fulfillment_rate, 0) as supplier_reliability,
        
        -- SALES_PERFORMANCE: Avg quota achievement
        coalesce(qa.avg_quota_achievement, 0) as sales_performance
        
    from sales_order_agg soa
    cross join sales_line_agg sla
    cross join inventory_agg ia
    cross join purchase_agg pa
    cross join work_order_agg woa
    cross join quota_agg qa
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
