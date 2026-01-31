{{ config(materialized='table') }}

{#
    Metrics Mart
    ============
    Joins fact_global_metrics with dim_metric to provide a complete view of all metrics
    with their names, categories, units, and hierarchical information.
    
    This mart is the primary table for:
    - AI Analytics queries about metrics
    - Cross-domain metric analysis
    - Time-series metric trending
    - KPI dashboards
    
    Use this table instead of joining fact_global_metrics with dim_metric manually.
#}

select
    -- Surrogate key
    fgm.metric_record_id,
    
    -- Date columns
    fgm.date_key,
    fgm.report_date,
    
    -- Metric info from dim_metric (single source of truth)
    fgm.metric_key,
    dm.metric_name,
    dm.metric_description,
    dm.metric_category,
    dm.metric_unit,
    dm.metric_level,
    dm.metric_parent,
    dm.metric_target,
    dm.alert_criteria,
    dm.recommended_actions,
    
    -- Metric value
    fgm.metric_value,
    
    -- Source info
    fgm.source_table,
    fgm.source_record_id,
    
    -- Core dimension keys
    fgm.customer_key,
    fgm.product_key,
    fgm.employee_key,
    fgm.territory_key,
    fgm.vendor_key,
    fgm.location_key,
    
    -- Additional dimension keys
    fgm.ship_method_key,
    fgm.credit_card_key,
    fgm.special_offer_key,
    fgm.scrap_reason_key,
    fgm.parent_order_id,
    
    -- Status columns
    fgm.online_order_flag,
    fgm.has_discount,
    fgm.inventory_status,
    fgm.order_status,
    fgm.delivery_status,
    fgm.quota_status,
    
    -- Context columns
    fgm.location_name,
    fgm.scrap_reason_name,
    fgm.safety_stock_level,
    fgm.reorder_point,
    fgm.number_of_operations,
    fgm.commission_pct,
    
    -- Metadata
    fgm.created_at

from {{ ref('fact_global_metrics') }} fgm
left join {{ ref('dim_metric') }} dm on fgm.metric_key = dm.metric_key
