{{ config(materialized='view') }}

{#
    Inventory Metrics
    =================
    Extracts metrics from fact_inventory (product/location granularity)
    
    Metrics included:
    - INV_QUANTITY: Current inventory quantity
    - INV_VALUE: Inventory value (quantity * cost)
    - INV_ABOVE_SAFETY: Quantity above safety stock level
    - INV_REORDER_PCT: Percentage of reorder point
    
    Relevant dimensions: product, location, inventory_status
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
    metric_name,
    metric_category,
    metric_value,
    metric_unit
from {{ ref('fact_inventory') }}
cross join lateral (
    values
        ('INV_QUANTITY', 'Inventory Quantity', 'Inventory', quantity::numeric, 'Count'),
        ('INV_VALUE', 'Inventory Value', 'Inventory', coalesce(inventory_value, 0)::numeric, 'USD'),
        ('INV_ABOVE_SAFETY', 'Quantity Above Safety Stock', 'Inventory', coalesce(quantity_above_safety_stock, 0)::numeric, 'Count'),
        ('INV_REORDER_PCT', 'Reorder Point Percentage', 'Inventory', coalesce(reorder_point_percentage, 0)::numeric, 'Percent')
) as metrics(metric_key, metric_name, metric_category, metric_value, metric_unit)
where metric_value is not null
