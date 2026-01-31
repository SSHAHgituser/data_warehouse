{{ config(materialized='view') }}

{#
    Sales Line Item Metrics
    =======================
    Extracts metrics from fact_sales_order_line (line-item granularity)
    
    Metrics included:
    - SOL_REVENUE, SOL_GROSS_AMOUNT, SOL_QUANTITY, SOL_PROFIT
    - SOL_PROFIT_MARGIN, SOL_DISCOUNT, SOL_UNIT_PRICE
    
    Note: metric_name, metric_category, and metric_unit come from dim_metric (single source of truth)
#}

with report_date_calc as (
    select max(orderdate)::date as report_date
    from {{ ref('stg_salesorderheader') }}
)

select
    order_date_key as date_key,
    (select report_date from report_date_calc) as report_date,
    'sales_order_line' as source_table,
    salesorderdetailid as source_record_id,
    
    -- Core dimension keys
    customer_key,
    product_key,
    employee_key,
    territory_key,
    
    -- Relevant dimension keys for this metric
    special_offer_key,
    salesorderid as parent_order_id,
    
    -- Relevant status columns
    case when has_discount then 'Yes' else 'No' end as has_discount,
    
    -- Metric columns
    metric_key,
    metric_value
from {{ ref('fact_sales_order_line') }}
cross join lateral (
    values
        ('SOL_REVENUE', net_line_amount::numeric),
        ('SOL_GROSS_AMOUNT', gross_line_amount::numeric),
        ('SOL_QUANTITY', orderqty::numeric),
        ('SOL_PROFIT', coalesce(total_profit, 0)::numeric),
        ('SOL_PROFIT_MARGIN', coalesce(profit_margin_percent, 0)::numeric),
        ('SOL_DISCOUNT', coalesce(discount_amount, 0)::numeric),
        ('SOL_UNIT_PRICE', unitprice::numeric)
) as metrics(metric_key, metric_value)
where metric_value is not null
