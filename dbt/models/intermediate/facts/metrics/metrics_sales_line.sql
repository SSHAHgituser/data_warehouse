{{ config(materialized='view') }}

{#
    Sales Line Item Metrics
    =======================
    Extracts metrics from fact_sales_order_line (line-item granularity)
    
    Metrics included:
    - SOL_REVENUE: Line item net revenue
    - SOL_GROSS_AMOUNT: Line item gross amount
    - SOL_QUANTITY: Quantity ordered
    - SOL_PROFIT: Line item profit
    - SOL_PROFIT_MARGIN: Profit margin percentage
    - SOL_DISCOUNT: Discount amount
    - SOL_UNIT_PRICE: Unit price
    
    Relevant dimensions: customer, product, employee, territory, special_offer, has_discount
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
    metric_name,
    metric_category,
    metric_value,
    metric_unit
from {{ ref('fact_sales_order_line') }}
cross join lateral (
    values
        ('SOL_REVENUE', 'Line Item Revenue', 'Sales', net_line_amount::numeric, 'USD'),
        ('SOL_GROSS_AMOUNT', 'Line Item Gross Amount', 'Sales', gross_line_amount::numeric, 'USD'),
        ('SOL_QUANTITY', 'Line Item Quantity', 'Sales', orderqty::numeric, 'Count'),
        ('SOL_PROFIT', 'Line Item Profit', 'Sales', coalesce(total_profit, 0)::numeric, 'USD'),
        ('SOL_PROFIT_MARGIN', 'Line Item Profit Margin', 'Sales', coalesce(profit_margin_percent, 0)::numeric, 'Percent'),
        ('SOL_DISCOUNT', 'Line Item Discount', 'Sales', coalesce(discount_amount, 0)::numeric, 'USD'),
        ('SOL_UNIT_PRICE', 'Unit Price', 'Sales', unitprice::numeric, 'USD')
) as metrics(metric_key, metric_name, metric_category, metric_value, metric_unit)
where metric_value is not null
