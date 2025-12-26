{{ config(materialized='table') }}

with work_order as (
    select
        workorderid,
        productid,
        orderqty,
        scrappedqty,
        startdate,
        enddate,
        duedate,
        scrapreasonid,
        modifieddate
    from {{ ref('stg_workorder') }}
),

work_order_routing as (
    select
        workorderid,
        productid,
        operationsequence,
        locationid,
        scheduledstartdate,
        scheduledenddate,
        actualstartdate,
        actualenddate,
        actualresourcehrs,
        plannedcost,
        actualcost,
        modifieddate
    from {{ ref('stg_workorderrouting') }}
),

work_order_summary as (
    select
        workorderid,
        count(*) as number_of_operations,
        sum(actualresourcehrs) as total_actual_hours,
        sum(plannedcost) as total_planned_cost,
        sum(actualcost) as total_actual_cost,
        min(scheduledstartdate) as first_operation_start,
        max(scheduledenddate) as last_operation_end,
        min(actualstartdate) as first_operation_actual_start,
        max(actualenddate) as last_operation_actual_end
    from work_order_routing
    group by workorderid
),

scrap_reason_info as (
    select
        scrapreasonid,
        name as scrap_reason_name
    from {{ ref('stg_scrapreason') }}
)

select
    wo.workorderid,
    -- Date keys
    cast(to_char(wo.startdate, 'YYYYMMDD') as integer) as start_date_key,
    cast(to_char(wo.enddate, 'YYYYMMDD') as integer) as end_date_key,
    cast(to_char(wo.duedate, 'YYYYMMDD') as integer) as due_date_key,
    -- Dimension keys
    wo.productid as product_key,
    wo.scrapreasonid as scrap_reason_key,
    -- Work order attributes
    wo.orderqty,
    wo.scrappedqty,
    wos.number_of_operations,
    -- Time measures
    date_part('day', wo.enddate - wo.startdate) as production_days,
    date_part('day', wo.duedate - wo.startdate) as days_until_due,
    date_part('day', wo.enddate - wo.duedate) as days_early_or_late,
    -- Cost measures
    wos.total_planned_cost,
    wos.total_actual_cost,
    (wos.total_actual_cost - wos.total_planned_cost) as cost_variance,
    case
        when wos.total_planned_cost > 0 then ((wos.total_actual_cost - wos.total_planned_cost) / wos.total_planned_cost) * 100
        else 0
    end as cost_variance_percent,
    -- Efficiency measures
    wos.total_actual_hours,
    case
        when wo.orderqty > 0 then wos.total_actual_hours / wo.orderqty
        else 0
    end as hours_per_unit,
    -- Quality measures
    case
        when wo.orderqty > 0 then (wo.scrappedqty / wo.orderqty) * 100
        else 0
    end as scrap_rate_percent,
    (wo.orderqty - wo.scrappedqty) as good_quantity,
    -- Scrap information
    sr.scrap_reason_name,
    -- Schedule performance
    date_part('day', wos.last_operation_actual_end - wos.last_operation_end) as schedule_variance_days,
    case
        when wo.enddate <= wo.duedate then 'On Time'
        when wo.enddate <= wo.duedate + interval '7 days' then 'Slightly Late'
        else 'Late'
    end as delivery_status,
    -- Metadata
    wo.modifieddate
from work_order wo
left join work_order_summary wos on wo.workorderid = wos.workorderid
left join scrap_reason_info sr on wo.scrapreasonid = sr.scrapreasonid

