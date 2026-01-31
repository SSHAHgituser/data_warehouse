{{ config(materialized='view') }}

{#
    Employee Quota Metrics
    ======================
    Extracts metrics from fact_employee_quota (employee/period granularity)
    
    Metrics included:
    - EQ_QUOTA: Sales quota amount
    - EQ_SALES_YTD: Sales year to date
    - EQ_SALES_LAST_YEAR: Sales from last year
    - EQ_ACHIEVEMENT_PCT: Quota achievement percentage
    - EQ_QUOTA_VARIANCE: Variance from quota
    - EQ_BONUS: Employee bonus amount
#}

with report_date_calc as (
    select max(orderdate)::date as report_date
    from {{ ref('stg_salesorderheader') }}
)

select
    quota_date_key as date_key,
    (select report_date from report_date_calc) as report_date,
    'employee_quota' as source_table,
    cast(null as bigint) as customer_key,
    cast(null as bigint) as product_key,
    employee_key,
    territory_key,
    cast(null as bigint) as vendor_key,
    cast(null as bigint) as location_key,
    employee_key as source_record_id,
    jsonb_build_object(
        'quota_status', quota_status,
        'commission_pct', commissionpct
    ) as additional_dimensions,
    metric_key,
    metric_name,
    metric_category,
    metric_value,
    metric_unit
from {{ ref('fact_employee_quota') }}
cross join lateral (
    values
        ('EQ_QUOTA', 'Sales Quota', 'HR', salesquota::numeric, 'USD'),
        ('EQ_SALES_YTD', 'Sales Year to Date', 'HR', coalesce(salesytd, 0)::numeric, 'USD'),
        ('EQ_SALES_LAST_YEAR', 'Sales Last Year', 'HR', coalesce(saleslastyear, 0)::numeric, 'USD'),
        ('EQ_ACHIEVEMENT_PCT', 'Quota Achievement Percent', 'HR', coalesce(quota_achievement_percent, 0)::numeric, 'Percent'),
        ('EQ_QUOTA_VARIANCE', 'Quota Variance', 'HR', coalesce(quota_variance, 0)::numeric, 'USD'),
        ('EQ_BONUS', 'Employee Bonus', 'HR', coalesce(bonus, 0)::numeric, 'USD')
) as metrics(metric_key, metric_name, metric_category, metric_value, metric_unit)
where metric_value is not null
