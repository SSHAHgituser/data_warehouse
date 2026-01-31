{{ config(materialized='view') }}

{#
    Employee Quota Metrics
    ======================
    Extracts metrics from fact_employee_quota (employee/period granularity)
    
    Metrics included:
    - EQ_QUOTA, EQ_SALES_YTD, EQ_SALES_LAST_YEAR
    - EQ_ACHIEVEMENT_PCT, EQ_QUOTA_VARIANCE, EQ_BONUS
    
    Note: metric_name, metric_category, and metric_unit come from dim_metric (single source of truth)
#}

with report_date_calc as (
    select max(orderdate)::date as report_date
    from {{ ref('stg_salesorderheader') }}
)

select
    quota_date_key as date_key,
    (select report_date from report_date_calc) as report_date,
    'employee_quota' as source_table,
    employee_key as source_record_id,
    
    -- Core dimension keys
    employee_key,
    territory_key,
    
    -- Relevant status columns
    quota_status,
    
    -- Relevant context columns
    commissionpct as commission_pct,
    
    -- Metric columns
    metric_key,
    metric_value
from {{ ref('fact_employee_quota') }}
cross join lateral (
    values
        ('EQ_QUOTA', salesquota::numeric),
        ('EQ_SALES_YTD', coalesce(salesytd, 0)::numeric),
        ('EQ_SALES_LAST_YEAR', coalesce(saleslastyear, 0)::numeric),
        ('EQ_ACHIEVEMENT_PCT', coalesce(quota_achievement_percent, 0)::numeric),
        ('EQ_QUOTA_VARIANCE', coalesce(quota_variance, 0)::numeric),
        ('EQ_BONUS', coalesce(bonus, 0)::numeric)
) as metrics(metric_key, metric_value)
where metric_value is not null
