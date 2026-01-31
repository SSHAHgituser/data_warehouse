{{ config(materialized='table') }}

{#
    Global Metrics Fact Table
    =========================
    Consolidates all metrics from individual metric building blocks into a single unified table.
    Uses a "tall" format where each row represents one metric value.
    
    This enables:
    - Flexible cross-domain analytics
    - Consistent metric definitions
    - Easy aggregation and comparison
    - Time-series analysis across all metrics
    
    Building blocks:
    - metrics_sales_order: Order-level sales metrics
    - metrics_sales_line: Line-item sales metrics
    - metrics_inventory: Inventory metrics
    - metrics_purchase_order: Procurement metrics
    - metrics_work_order: Production metrics
    - metrics_employee_quota: HR/quota metrics
#}

with all_metrics as (
    -- Sales Order Metrics (order-level)
    select * from {{ ref('metrics_sales_order') }}
    
    union all
    
    -- Sales Line Item Metrics (line-item level)
    select * from {{ ref('metrics_sales_line') }}
    
    union all
    
    -- Inventory Metrics (product/location level)
    select * from {{ ref('metrics_inventory') }}
    
    union all
    
    -- Purchase Order Metrics (order-level)
    select * from {{ ref('metrics_purchase_order') }}
    
    union all
    
    -- Work Order Metrics (work order level)
    select * from {{ ref('metrics_work_order') }}
    
    union all
    
    -- Employee Quota Metrics (employee/period level)
    select * from {{ ref('metrics_employee_quota') }}
)

select
    -- Surrogate key for the metrics table
    row_number() over (order by date_key, metric_key, source_record_id) as metric_record_id,
    
    -- Date columns
    date_key,
    report_date,
    
    -- Metric identification
    metric_key,
    metric_name,
    metric_category,
    source_table,
    source_record_id,
    
    -- Core granularity columns (lowest common denominator)
    customer_key,
    product_key,
    employee_key,
    territory_key,
    vendor_key,
    location_key,
    
    -- Additional dimensions (metric-specific context)
    additional_dimensions,
    
    -- The metric value and unit
    metric_value,
    metric_unit,
    
    -- Metadata
    current_timestamp as created_at

from all_metrics
where metric_value is not null
  and metric_value != 0  -- Exclude zero values to reduce table size
