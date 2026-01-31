{{ config(materialized='view') }}

{#
    Work Order Metrics
    ==================
    Extracts metrics from fact_work_order (work order granularity)
    
    Metrics included:
    - WO_ORDER_QTY, WO_GOOD_QTY, WO_SCRAPPED_QTY, WO_SCRAP_RATE
    - WO_PLANNED_COST, WO_ACTUAL_COST, WO_COST_VARIANCE, WO_COST_VARIANCE_PCT
    - WO_PRODUCTION_DAYS, WO_ACTUAL_HOURS, WO_HOURS_PER_UNIT
    
    Note: metric_name, metric_category, and metric_unit come from dim_metric (single source of truth)
#}

with report_date_calc as (
    select max(orderdate)::date as report_date
    from {{ ref('stg_salesorderheader') }}
)

select
    start_date_key as date_key,
    (select report_date from report_date_calc) as report_date,
    'work_order' as source_table,
    workorderid as source_record_id,
    
    -- Core dimension keys
    product_key,
    
    -- Relevant dimension keys for this metric
    scrap_reason_key,
    
    -- Relevant status columns
    delivery_status,
    coalesce(scrap_reason_name, 'None') as scrap_reason_name,
    
    -- Relevant context columns
    number_of_operations,
    
    -- Metric columns
    metric_key,
    metric_value
from {{ ref('fact_work_order') }}
cross join lateral (
    values
        ('WO_ORDER_QTY', orderqty::numeric),
        ('WO_GOOD_QTY', coalesce(good_quantity, 0)::numeric),
        ('WO_SCRAPPED_QTY', coalesce(scrappedqty, 0)::numeric),
        ('WO_SCRAP_RATE', coalesce(scrap_rate_percent, 0)::numeric),
        ('WO_PLANNED_COST', coalesce(total_planned_cost, 0)::numeric),
        ('WO_ACTUAL_COST', coalesce(total_actual_cost, 0)::numeric),
        ('WO_COST_VARIANCE', coalesce(cost_variance, 0)::numeric),
        ('WO_COST_VARIANCE_PCT', coalesce(cost_variance_percent, 0)::numeric),
        ('WO_PRODUCTION_DAYS', coalesce(production_days, 0)::numeric),
        ('WO_ACTUAL_HOURS', coalesce(total_actual_hours, 0)::numeric),
        ('WO_HOURS_PER_UNIT', coalesce(hours_per_unit, 0)::numeric)
) as metrics(metric_key, metric_value)
where metric_value is not null
