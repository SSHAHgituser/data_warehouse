{{ config(materialized='view') }}

{#
    Work Order Metrics
    ==================
    Extracts metrics from fact_work_order (work order granularity)
    
    Metrics included:
    - WO_ORDER_QTY: Work order quantity
    - WO_GOOD_QTY: Good quantity produced
    - WO_SCRAPPED_QTY: Scrapped quantity
    - WO_SCRAP_RATE: Scrap rate percentage
    - WO_PLANNED_COST: Planned production cost
    - WO_ACTUAL_COST: Actual production cost
    - WO_COST_VARIANCE: Cost variance (actual - planned)
    - WO_COST_VARIANCE_PCT: Cost variance percentage
    - WO_PRODUCTION_DAYS: Days to complete production
    - WO_ACTUAL_HOURS: Actual production hours
    - WO_HOURS_PER_UNIT: Hours per unit produced
    
    Relevant dimensions: product, scrap_reason, delivery_status
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
    metric_name,
    metric_category,
    metric_value,
    metric_unit
from {{ ref('fact_work_order') }}
cross join lateral (
    values
        ('WO_ORDER_QTY', 'Work Order Quantity', 'Production', orderqty::numeric, 'Count'),
        ('WO_GOOD_QTY', 'Good Quantity Produced', 'Production', coalesce(good_quantity, 0)::numeric, 'Count'),
        ('WO_SCRAPPED_QTY', 'Scrapped Quantity', 'Production', coalesce(scrappedqty, 0)::numeric, 'Count'),
        ('WO_SCRAP_RATE', 'Scrap Rate', 'Production', coalesce(scrap_rate_percent, 0)::numeric, 'Percent'),
        ('WO_PLANNED_COST', 'Planned Cost', 'Production', coalesce(total_planned_cost, 0)::numeric, 'USD'),
        ('WO_ACTUAL_COST', 'Actual Cost', 'Production', coalesce(total_actual_cost, 0)::numeric, 'USD'),
        ('WO_COST_VARIANCE', 'Cost Variance', 'Production', coalesce(cost_variance, 0)::numeric, 'USD'),
        ('WO_COST_VARIANCE_PCT', 'Cost Variance Percent', 'Production', coalesce(cost_variance_percent, 0)::numeric, 'Percent'),
        ('WO_PRODUCTION_DAYS', 'Production Days', 'Production', coalesce(production_days, 0)::numeric, 'Days'),
        ('WO_ACTUAL_HOURS', 'Actual Production Hours', 'Production', coalesce(total_actual_hours, 0)::numeric, 'Hours'),
        ('WO_HOURS_PER_UNIT', 'Hours per Unit', 'Production', coalesce(hours_per_unit, 0)::numeric, 'Hours')
) as metrics(metric_key, metric_name, metric_category, metric_value, metric_unit)
where metric_value is not null
