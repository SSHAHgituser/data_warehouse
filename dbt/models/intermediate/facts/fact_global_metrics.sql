{{ config(materialized='table') }}

{#
    Global Metrics Fact Table
    =========================
    Consolidates all metrics from individual metric building blocks into a single unified table.
    Uses a "tall" format where each row represents one metric value.
    
    Each UNION ALL section explicitly maps columns from source metrics models,
    using 'All' for dimension columns not applicable to that metric type.
    
    This enables:
    - Flexible cross-domain analytics
    - Consistent metric definitions
    - Easy filtering (WHERE column = 'value' OR column = 'All')
    - Time-series analysis across all metrics
#}

with all_metrics as (
    
    -- ============================================
    -- SALES ORDER METRICS
    -- ============================================
    select
        date_key,
        report_date,
        source_table,
        source_record_id,
        -- Core dimension keys
        customer_key,
        cast(null as bigint) as product_key,
        employee_key,
        territory_key,
        cast(null as bigint) as vendor_key,
        cast(null as bigint) as location_key,
        -- Additional dimension keys
        ship_method_key,
        credit_card_key,
        cast(null as bigint) as special_offer_key,
        cast(null as bigint) as scrap_reason_key,
        source_record_id as parent_order_id,
        -- Status columns ('All' for non-applicable)
        online_order_flag,
        'All' as has_discount,
        'All' as inventory_status,
        order_status,
        'All' as delivery_status,
        'All' as quota_status,
        -- Context columns
        'All' as location_name,
        'All' as scrap_reason_name,
        cast(null as numeric) as safety_stock_level,
        cast(null as numeric) as reorder_point,
        cast(null as numeric) as number_of_operations,
        cast(null as numeric) as commission_pct,
        -- Metric columns
        metric_key,
        metric_name,
        metric_category,
        metric_value,
        metric_unit
    from {{ ref('metrics_sales_order') }}
    
    union all
    
    -- ============================================
    -- SALES LINE ITEM METRICS
    -- ============================================
    select
        date_key,
        report_date,
        source_table,
        source_record_id,
        -- Core dimension keys
        customer_key,
        product_key,
        employee_key,
        territory_key,
        cast(null as bigint) as vendor_key,
        cast(null as bigint) as location_key,
        -- Additional dimension keys
        cast(null as bigint) as ship_method_key,
        cast(null as bigint) as credit_card_key,
        special_offer_key,
        cast(null as bigint) as scrap_reason_key,
        parent_order_id,
        -- Status columns ('All' for non-applicable)
        'All' as online_order_flag,
        has_discount,
        'All' as inventory_status,
        'All' as order_status,
        'All' as delivery_status,
        'All' as quota_status,
        -- Context columns
        'All' as location_name,
        'All' as scrap_reason_name,
        cast(null as numeric) as safety_stock_level,
        cast(null as numeric) as reorder_point,
        cast(null as numeric) as number_of_operations,
        cast(null as numeric) as commission_pct,
        -- Metric columns
        metric_key,
        metric_name,
        metric_category,
        metric_value,
        metric_unit
    from {{ ref('metrics_sales_line') }}
    
    union all
    
    -- ============================================
    -- INVENTORY METRICS
    -- ============================================
    select
        date_key,
        report_date,
        source_table,
        source_record_id,
        -- Core dimension keys
        cast(null as bigint) as customer_key,
        product_key,
        cast(null as bigint) as employee_key,
        cast(null as bigint) as territory_key,
        cast(null as bigint) as vendor_key,
        location_key,
        -- Additional dimension keys
        cast(null as bigint) as ship_method_key,
        cast(null as bigint) as credit_card_key,
        cast(null as bigint) as special_offer_key,
        cast(null as bigint) as scrap_reason_key,
        cast(null as bigint) as parent_order_id,
        -- Status columns ('All' for non-applicable)
        'All' as online_order_flag,
        'All' as has_discount,
        inventory_status,
        'All' as order_status,
        'All' as delivery_status,
        'All' as quota_status,
        -- Context columns
        location_name,
        'All' as scrap_reason_name,
        safety_stock_level,
        reorder_point,
        cast(null as numeric) as number_of_operations,
        cast(null as numeric) as commission_pct,
        -- Metric columns
        metric_key,
        metric_name,
        metric_category,
        metric_value,
        metric_unit
    from {{ ref('metrics_inventory') }}
    
    union all
    
    -- ============================================
    -- PURCHASE ORDER METRICS
    -- ============================================
    select
        date_key,
        report_date,
        source_table,
        source_record_id,
        -- Core dimension keys
        cast(null as bigint) as customer_key,
        cast(null as bigint) as product_key,
        employee_key,
        cast(null as bigint) as territory_key,
        vendor_key,
        cast(null as bigint) as location_key,
        -- Additional dimension keys
        ship_method_key,
        cast(null as bigint) as credit_card_key,
        cast(null as bigint) as special_offer_key,
        cast(null as bigint) as scrap_reason_key,
        cast(null as bigint) as parent_order_id,
        -- Status columns ('All' for non-applicable)
        'All' as online_order_flag,
        'All' as has_discount,
        'All' as inventory_status,
        order_status,
        'All' as delivery_status,
        'All' as quota_status,
        -- Context columns
        'All' as location_name,
        'All' as scrap_reason_name,
        cast(null as numeric) as safety_stock_level,
        cast(null as numeric) as reorder_point,
        cast(null as numeric) as number_of_operations,
        cast(null as numeric) as commission_pct,
        -- Metric columns
        metric_key,
        metric_name,
        metric_category,
        metric_value,
        metric_unit
    from {{ ref('metrics_purchase_order') }}
    
    union all
    
    -- ============================================
    -- WORK ORDER METRICS
    -- ============================================
    select
        date_key,
        report_date,
        source_table,
        source_record_id,
        -- Core dimension keys
        cast(null as bigint) as customer_key,
        product_key,
        cast(null as bigint) as employee_key,
        cast(null as bigint) as territory_key,
        cast(null as bigint) as vendor_key,
        cast(null as bigint) as location_key,
        -- Additional dimension keys
        cast(null as bigint) as ship_method_key,
        cast(null as bigint) as credit_card_key,
        cast(null as bigint) as special_offer_key,
        scrap_reason_key,
        cast(null as bigint) as parent_order_id,
        -- Status columns ('All' for non-applicable)
        'All' as online_order_flag,
        'All' as has_discount,
        'All' as inventory_status,
        'All' as order_status,
        delivery_status,
        'All' as quota_status,
        -- Context columns
        'All' as location_name,
        scrap_reason_name,
        cast(null as numeric) as safety_stock_level,
        cast(null as numeric) as reorder_point,
        number_of_operations::numeric as number_of_operations,
        cast(null as numeric) as commission_pct,
        -- Metric columns
        metric_key,
        metric_name,
        metric_category,
        metric_value,
        metric_unit
    from {{ ref('metrics_work_order') }}
    
    union all
    
    -- ============================================
    -- EMPLOYEE QUOTA METRICS
    -- ============================================
    select
        date_key,
        report_date,
        source_table,
        source_record_id,
        -- Core dimension keys
        cast(null as bigint) as customer_key,
        cast(null as bigint) as product_key,
        employee_key,
        territory_key,
        cast(null as bigint) as vendor_key,
        cast(null as bigint) as location_key,
        -- Additional dimension keys
        cast(null as bigint) as ship_method_key,
        cast(null as bigint) as credit_card_key,
        cast(null as bigint) as special_offer_key,
        cast(null as bigint) as scrap_reason_key,
        cast(null as bigint) as parent_order_id,
        -- Status columns ('All' for non-applicable)
        'All' as online_order_flag,
        'All' as has_discount,
        'All' as inventory_status,
        'All' as order_status,
        'All' as delivery_status,
        quota_status,
        -- Context columns
        'All' as location_name,
        'All' as scrap_reason_name,
        cast(null as numeric) as safety_stock_level,
        cast(null as numeric) as reorder_point,
        cast(null as numeric) as number_of_operations,
        commission_pct,
        -- Metric columns
        metric_key,
        metric_name,
        metric_category,
        metric_value,
        metric_unit
    from {{ ref('metrics_employee_quota') }}
)

select
    -- Surrogate key
    row_number() over (order by date_key, metric_key, source_record_id) as metric_record_id,
    
    -- All columns from union
    date_key,
    report_date,
    metric_key,
    metric_name,
    metric_category,
    source_table,
    source_record_id,
    -- Core dimension keys
    customer_key,
    product_key,
    employee_key,
    territory_key,
    vendor_key,
    location_key,
    -- Additional dimension keys
    ship_method_key,
    credit_card_key,
    special_offer_key,
    scrap_reason_key,
    parent_order_id,
    -- Status columns
    online_order_flag,
    has_discount,
    inventory_status,
    order_status,
    delivery_status,
    quota_status,
    -- Context columns
    location_name,
    scrap_reason_name,
    safety_stock_level,
    reorder_point,
    number_of_operations,
    commission_pct,
    -- Metric value
    metric_value,
    metric_unit,
    -- Metadata
    current_timestamp as created_at

from all_metrics
where metric_value is not null
  and metric_value != 0
