{{ config(materialized='table') }}

{#
    Global Metrics Fact Table
    =========================
    Consolidates all metrics from individual metric building blocks into a single unified table.
    Uses a "tall" format where each row represents one metric value.
    
    Each UNION ALL section explicitly maps columns from source metrics models,
    using 'All' for dimension columns not applicable to that metric type.
    
    metric_name, metric_category, metric_unit, and metric_level are pulled from dim_metric 
    (single source of truth) after the union, ensuring consistency across all metrics.
    
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
        metric_value
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
        metric_value
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
        metric_value
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
        metric_value
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
        metric_value
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
        metric_value
    from {{ ref('metrics_employee_quota') }}
    
    union all
    
    -- ============================================
    -- DERIVED / STRATEGIC METRICS (L3-L5)
    -- Company-wide aggregates for KPIs and strategic metrics
    -- ============================================
    select
        date_key,
        report_date,
        source_table,
        source_record_id,
        -- Core dimension keys (all null - company-wide aggregates)
        cast(null as bigint) as customer_key,
        cast(null as bigint) as product_key,
        cast(null as bigint) as employee_key,
        cast(null as bigint) as territory_key,
        cast(null as bigint) as vendor_key,
        cast(null as bigint) as location_key,
        -- Additional dimension keys
        cast(null as bigint) as ship_method_key,
        cast(null as bigint) as credit_card_key,
        cast(null as bigint) as special_offer_key,
        cast(null as bigint) as scrap_reason_key,
        cast(null as bigint) as parent_order_id,
        -- Status columns ('All' - company-wide)
        'All' as online_order_flag,
        'All' as has_discount,
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
        metric_value
    from {{ ref('metrics_derived') }}
)

select
    -- Surrogate key
    row_number() over (order by am.date_key, am.metric_key, am.source_record_id) as metric_record_id,
    
    -- Date columns
    am.date_key,
    am.report_date,
    
    -- Metric info from dim_metric (single source of truth)
    am.metric_key,
    dm.metric_name,
    dm.metric_category,
    dm.metric_unit,
    dm.metric_level,
    
    -- Source info
    am.source_table,
    am.source_record_id,
    
    -- Core dimension keys
    am.customer_key,
    am.product_key,
    am.employee_key,
    am.territory_key,
    am.vendor_key,
    am.location_key,
    
    -- Additional dimension keys
    am.ship_method_key,
    am.credit_card_key,
    am.special_offer_key,
    am.scrap_reason_key,
    am.parent_order_id,
    
    -- Status columns
    am.online_order_flag,
    am.has_discount,
    am.inventory_status,
    am.order_status,
    am.delivery_status,
    am.quota_status,
    
    -- Context columns
    am.location_name,
    am.scrap_reason_name,
    am.safety_stock_level,
    am.reorder_point,
    am.number_of_operations,
    am.commission_pct,
    
    -- Metric value
    am.metric_value,
    
    -- Metadata
    current_timestamp as created_at

from all_metrics am
left join {{ ref('dim_metric') }} dm on am.metric_key = dm.metric_key
where am.metric_value is not null
  and am.metric_value != 0
