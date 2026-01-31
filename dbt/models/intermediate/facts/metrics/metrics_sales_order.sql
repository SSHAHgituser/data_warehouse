{{ config(materialized='view') }}

{#
    Sales Order Metrics
    ===================
    Extracts metrics from fact_sales_order (order-level granularity)
    
    Metrics included:
    - SO_REVENUE: Total order revenue
    - SO_SUBTOTAL: Order subtotal
    - SO_TAX: Tax amount
    - SO_FREIGHT: Freight charges
    - SO_QUANTITY: Total quantity ordered
    - SO_LINE_ITEMS: Number of line items
    - SO_DISCOUNT: Total discount amount
    - SO_DAYS_TO_SHIP: Days from order to ship
    
    Relevant dimensions: customer, employee, territory, ship_method, credit_card, online_order_flag, order_status
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
    metric_name,
    metric_category,
    metric_value,
    metric_unit
from {{ ref('fact_sales_order') }}
cross join lateral (
    values
        ('SO_REVENUE', 'Sales Order Revenue', 'Sales', totaldue::numeric, 'USD'),
        ('SO_SUBTOTAL', 'Sales Order Subtotal', 'Sales', subtotal::numeric, 'USD'),
        ('SO_TAX', 'Sales Order Tax', 'Sales', taxamt::numeric, 'USD'),
        ('SO_FREIGHT', 'Sales Order Freight', 'Sales', freight::numeric, 'USD'),
        ('SO_QUANTITY', 'Sales Order Quantity', 'Sales', total_quantity::numeric, 'Count'),
        ('SO_LINE_ITEMS', 'Sales Order Line Items', 'Sales', number_of_line_items::numeric, 'Count'),
        ('SO_DISCOUNT', 'Sales Order Discount', 'Sales', coalesce(total_discount_amount, 0)::numeric, 'USD'),
        ('SO_DAYS_TO_SHIP', 'Days to Ship', 'Sales', coalesce(days_to_ship, 0)::numeric, 'Days')
) as metrics(metric_key, metric_name, metric_category, metric_value, metric_unit)
where metric_value is not null
