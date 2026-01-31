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
#}

with report_date_calc as (
    select max(orderdate)::date as report_date
    from {{ ref('stg_salesorderheader') }}
)

select
    -- Inventory doesn't have a natural date, use report date
    cast(to_char((select report_date from report_date_calc), 'YYYYMMDD') as integer) as date_key,
    (select report_date from report_date_calc) as report_date,
    'inventory' as source_table,
    cast(null as bigint) as customer_key,
    product_key,
    cast(null as bigint) as employee_key,
    cast(null as bigint) as territory_key,
    cast(null as bigint) as vendor_key,
    location_key,
    -- Create a composite source record id
    row_number() over (order by product_key, location_key) as source_record_id,
    jsonb_build_object(
        'location_name', location_name,
        'inventory_status', inventory_status,
        'safety_stock_level', safetystocklevel,
        'reorder_point', reorderpoint
    ) as additional_dimensions,
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
