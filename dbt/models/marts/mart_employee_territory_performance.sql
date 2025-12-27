{{ config(materialized='table') }}

-- Employee & Territory Performance Mart
-- Supports: Employee performance, Territory analysis, Sales quota tracking, Compensation analysis

with employee_base as (
    select
        employee_id,
        jobtitle,
        department_name,
        territoryid,
        territory_name as emp_territory_name,
        sales_year_to_date,
        quota_achievement_percent,
        total_orders_managed,
        total_sales_revenue,
        years_of_service,
        current_pay_rate,
        payfrequency
    from {{ ref('dim_employee') }}
),

territory_base as (
    select
        territoryid,
        territory_name,
        countryregioncode,
        territory_group,
        total_revenue as territory_total_revenue,
        total_customers,
        total_orders as territory_total_orders,
        performance_category,
        total_revenue
    from {{ ref('dim_territory') }}
),

employee_sales_detail as (
    select
        fso.employee_key,
        fso.order_date_key,
        count(distinct fso.salesorderid) as daily_order_count,
        sum(fso.totaldue) as daily_revenue,
        count(distinct fso.customer_key) as daily_customers,
        count(distinct fsol.product_key) as daily_products_sold
    from {{ ref('fact_sales_order') }} fso
    left join {{ ref('fact_sales_order_line') }} fsol on fso.salesorderid = fsol.salesorderid
    where fso.employee_key is not null
    group by fso.employee_key, fso.order_date_key
),

employee_monthly_performance as (
    select
        esd.employee_key,
        dd.year,
        dd.quarter,
        dd.month,
        dd.year_quarter,
        dd.year_month,
        sum(esd.daily_order_count) as monthly_order_count,
        sum(esd.daily_revenue) as monthly_revenue,
        sum(esd.daily_customers) as monthly_unique_customers,
        sum(esd.daily_products_sold) as monthly_products_sold
    from employee_sales_detail esd
    join {{ ref('dim_date') }} dd on dd.date_key = esd.order_date_key
    group by esd.employee_key, dd.year, dd.quarter, dd.month, dd.year_quarter, dd.year_month
),

employee_quota_history as (
    select
        employee_key,
        quota_date_key,
        salesquota,
        salesytd,
        quota_achievement_percent,
        quota_status
    from {{ ref('fact_employee_quota') }}
),

territory_sales_detail as (
    select
        territory_key,
        order_date_key,
        count(distinct salesorderid) as daily_order_count,
        sum(totaldue) as daily_revenue,
        count(distinct customer_key) as daily_customers
    from {{ ref('fact_sales_order') }}
    where territory_key is not null
    group by territory_key, order_date_key
),

territory_monthly_performance as (
    select
        tsd.territory_key,
        dd.year,
        dd.quarter,
        dd.month,
        dd.year_quarter,
        dd.year_month,
        sum(tsd.daily_order_count) as monthly_order_count,
        sum(tsd.daily_revenue) as monthly_revenue,
        sum(tsd.daily_customers) as monthly_unique_customers
    from territory_sales_detail tsd
    join {{ ref('dim_date') }} dd on dd.date_key = tsd.order_date_key
    group by tsd.territory_key, dd.year, dd.quarter, dd.month, dd.year_quarter, dd.year_month
),

date_dim as (
    select
        date_key,
        year,
        quarter,
        month,
        year_quarter,
        year_month
    from {{ ref('dim_date') }}
)

-- Employee Performance
select
    'employee' as performance_type,
    eb.employee_id as performance_id,
    eb.jobtitle,
    eb.department_name,
    tb.territory_name,
    eb.territoryid,
    tb.countryregioncode,
    tb.territory_group,
    emp.year,
    emp.quarter,
    emp.month,
    emp.year_quarter,
    emp.year_month,
    emp.monthly_order_count,
    emp.monthly_revenue,
    emp.monthly_unique_customers,
    emp.monthly_products_sold,
    eb.sales_year_to_date,
    eb.quota_achievement_percent,
    eb.total_orders_managed,
    eb.total_sales_revenue,
    eb.years_of_service,
    eb.current_pay_rate,
    eb.payfrequency,
    eqh.salesquota as current_quota,
    eqh.quota_status,
    tb.performance_category as territory_performance,
    null::integer as territory_total_orders,
    null::integer as territory_total_customers
from employee_base eb
left join employee_monthly_performance emp on eb.employee_id = emp.employee_key
left join (
    select distinct on (employee_key)
        employee_key,
        salesquota,
        quota_status
    from employee_quota_history
    order by employee_key, quota_date_key desc
) eqh on eb.employee_id = eqh.employee_key
left join {{ ref('dim_territory') }} tb on eb.territoryid = tb.territoryid

union all

-- Territory Performance
select
    'territory' as performance_type,
    tb.territoryid as performance_id,
    null::varchar as jobtitle,
    null::varchar as department_name,
    tb.territory_name,
    tb.territoryid,
    tb.countryregioncode,
    tb.territory_group,
    tmp.year,
    tmp.quarter,
    tmp.month,
    tmp.year_quarter,
    tmp.year_month,
    tmp.monthly_order_count,
    tmp.monthly_revenue,
    tmp.monthly_unique_customers,
    null::bigint as monthly_products_sold,
    tb.territory_total_revenue as sales_year_to_date,
    null::numeric as quota_achievement_percent,
    null::bigint as total_orders_managed,
    tb.territory_total_revenue as total_sales_revenue,
    null::bigint as years_of_service,
    null::numeric as current_pay_rate,
    null::bigint as payfrequency,
    null::numeric as current_quota,
    null::varchar as quota_status,
    tb.performance_category as territory_performance,
    tb.territory_total_orders,
    tb.total_customers as territory_total_customers
from territory_base tb
left join territory_monthly_performance tmp on tb.territoryid = tmp.territory_key

