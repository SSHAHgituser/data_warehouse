{{ config(materialized='view') }}

{#
    Purchase Order Metrics
    ======================
    Extracts metrics from fact_purchase_order (order-level granularity)
    
    Metrics included:
    - PO_AMOUNT: Total purchase order amount
    - PO_SUBTOTAL: Purchase order subtotal
    - PO_TAX: Tax amount
    - PO_FREIGHT: Freight charges
    - PO_QUANTITY: Total quantity ordered
    - PO_RECEIVED_QTY: Quantity received
    - PO_REJECTED_QTY: Quantity rejected
    - PO_REJECTION_RATE: Rejection rate percentage
    - PO_FULFILLMENT_RATE: Fulfillment rate percentage
    - PO_DAYS_TO_SHIP: Days from order to ship
    
    Relevant dimensions: vendor, employee, ship_method, order_status
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
    metric_name,
    metric_category,
    metric_value,
    metric_unit
from {{ ref('fact_purchase_order') }}
cross join lateral (
    values
        ('PO_AMOUNT', 'Purchase Order Amount', 'Procurement', totaldue::numeric, 'USD'),
        ('PO_SUBTOTAL', 'Purchase Order Subtotal', 'Procurement', subtotal::numeric, 'USD'),
        ('PO_TAX', 'Purchase Order Tax', 'Procurement', taxamt::numeric, 'USD'),
        ('PO_FREIGHT', 'Purchase Order Freight', 'Procurement', freight::numeric, 'USD'),
        ('PO_QUANTITY', 'Purchase Order Quantity', 'Procurement', coalesce(total_quantity, 0)::numeric, 'Count'),
        ('PO_RECEIVED_QTY', 'Received Quantity', 'Procurement', coalesce(total_received_quantity, 0)::numeric, 'Count'),
        ('PO_REJECTED_QTY', 'Rejected Quantity', 'Procurement', coalesce(total_rejected_quantity, 0)::numeric, 'Count'),
        ('PO_REJECTION_RATE', 'Rejection Rate', 'Procurement', coalesce(rejection_rate_percent, 0)::numeric, 'Percent'),
        ('PO_FULFILLMENT_RATE', 'Fulfillment Rate', 'Procurement', coalesce(fulfillment_rate_percent, 0)::numeric, 'Percent'),
        ('PO_DAYS_TO_SHIP', 'Purchase Days to Ship', 'Procurement', coalesce(days_to_ship, 0)::numeric, 'Days')
) as metrics(metric_key, metric_name, metric_category, metric_value, metric_unit)
where metric_value is not null
