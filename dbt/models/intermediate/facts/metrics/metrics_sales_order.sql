{{ config(materialized='view') }}

{#
    Sales Order Metrics
    ===================
    Extracts metrics from fact_sales_order (order-level granularity)
    
    Metrics included:
    - SO_REVENUE, SO_SUBTOTAL, SO_TAX, SO_FREIGHT
    - SO_QUANTITY, SO_LINE_ITEMS, SO_DISCOUNT, SO_DAYS_TO_SHIP
    
    Note: metric_name, metric_category, and metric_unit come from dim_metric (single source of truth)
#}

with report_date_calc as (
    select max(orderdate)::date as report_date
    from {{ ref('stg_salesorderheader') }}
)

select
    order_date_key as date_key,
    (select report_date from report_date_calc) as report_date,
    'sales_order' as source_table,
    salesorderid as source_record_id,
    
    -- Core dimension keys
    customer_key,
    employee_key,
    territory_key,
    
    -- Relevant dimension keys for this metric
    ship_method_key,
    credit_card_key,
    
    -- Relevant status columns
    case when onlineorderflag::text = 'true' then 'Online' else 'In-Store' end as online_order_flag,
    status::text as order_status,
    
    -- Metric columns
    metric_key,
    metric_value
from {{ ref('fact_sales_order') }}
cross join lateral (
    values
        ('SO_REVENUE', totaldue::numeric),
        ('SO_SUBTOTAL', subtotal::numeric),
        ('SO_TAX', taxamt::numeric),
        ('SO_FREIGHT', freight::numeric),
        ('SO_QUANTITY', total_quantity::numeric),
        ('SO_LINE_ITEMS', number_of_line_items::numeric),
        ('SO_DISCOUNT', coalesce(total_discount_amount, 0)::numeric),
        ('SO_DAYS_TO_SHIP', coalesce(days_to_ship, 0)::numeric)
) as metrics(metric_key, metric_value)
where metric_value is not null
