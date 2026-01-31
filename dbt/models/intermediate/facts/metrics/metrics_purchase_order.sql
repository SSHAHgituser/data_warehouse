{{ config(materialized='view') }}

{#
    Purchase Order Metrics
    ======================
    Extracts metrics from fact_purchase_order (order-level granularity)
    
    Metrics included:
    - PO_AMOUNT, PO_SUBTOTAL, PO_TAX, PO_FREIGHT, PO_QUANTITY
    - PO_RECEIVED_QTY, PO_REJECTED_QTY, PO_REJECTION_RATE
    - PO_FULFILLMENT_RATE, PO_DAYS_TO_SHIP
    
    Note: metric_name, metric_category, and metric_unit come from dim_metric (single source of truth)
#}

with report_date_calc as (
    select max(orderdate)::date as report_date
    from {{ ref('stg_salesorderheader') }}
)

select
    order_date_key as date_key,
    (select report_date from report_date_calc) as report_date,
    'purchase_order' as source_table,
    purchaseorderid as source_record_id,
    
    -- Core dimension keys
    vendor_key,
    employee_key,
    
    -- Relevant dimension keys for this metric
    ship_method_key,
    
    -- Relevant status columns
    status::text as order_status,
    
    -- Metric columns
    metric_key,
    metric_value
from {{ ref('fact_purchase_order') }}
cross join lateral (
    values
        ('PO_AMOUNT', totaldue::numeric),
        ('PO_SUBTOTAL', subtotal::numeric),
        ('PO_TAX', taxamt::numeric),
        ('PO_FREIGHT', freight::numeric),
        ('PO_QUANTITY', coalesce(total_quantity, 0)::numeric),
        ('PO_RECEIVED_QTY', coalesce(total_received_quantity, 0)::numeric),
        ('PO_REJECTED_QTY', coalesce(total_rejected_quantity, 0)::numeric),
        ('PO_REJECTION_RATE', coalesce(rejection_rate_percent, 0)::numeric),
        ('PO_FULFILLMENT_RATE', coalesce(fulfillment_rate_percent, 0)::numeric),
        ('PO_DAYS_TO_SHIP', coalesce(days_to_ship, 0)::numeric)
) as metrics(metric_key, metric_value)
where metric_value is not null
