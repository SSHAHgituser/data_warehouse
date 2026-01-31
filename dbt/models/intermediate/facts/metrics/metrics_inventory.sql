{{ config(materialized='view') }}

{#
    Inventory Metrics
    =================
    Extracts metrics from fact_inventory (product/location granularity)
    
    Metrics included:
    - INV_QUANTITY, INV_VALUE, INV_ABOVE_SAFETY, INV_REORDER_PCT
    
    Note: metric_name, metric_category, and metric_unit come from dim_metric (single source of truth)
#}

with report_date_calc as (
    select max(orderdate)::date as report_date
    from {{ ref('stg_salesorderheader') }}
)

select
    cast(to_char((select report_date from report_date_calc), 'YYYYMMDD') as integer) as date_key,
    (select report_date from report_date_calc) as report_date,
    'inventory' as source_table,
    row_number() over (order by product_key, location_key) as source_record_id,
    
    -- Core dimension keys
    product_key,
    location_key,
    
    -- Relevant status columns
    inventory_status,
    location_name,
    
    -- Relevant context columns
    safetystocklevel as safety_stock_level,
    reorderpoint as reorder_point,
    
    -- Metric columns
    metric_key,
    metric_value
from {{ ref('fact_inventory') }}
cross join lateral (
    values
        ('INV_QUANTITY', quantity::numeric),
        ('INV_VALUE', coalesce(inventory_value, 0)::numeric),
        ('INV_ABOVE_SAFETY', coalesce(quantity_above_safety_stock, 0)::numeric),
        ('INV_REORDER_PCT', coalesce(reorder_point_percentage, 0)::numeric)
) as metrics(metric_key, metric_value)
where metric_value is not null
