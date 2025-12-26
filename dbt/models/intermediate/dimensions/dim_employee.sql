{{ config(materialized='table') }}

with employee_base as (
    select
        e.businessentityid as employee_id,
        e.nationalidnumber,
        e.loginid,
        e.jobtitle,
        e.birthdate,
        e.maritalstatus,
        e.gender,
        e.hiredate,
        e.salariedflag,
        e.vacationhours,
        e.sickleavehours,
        e.currentflag,
        e.rowguid,
        e.modifieddate,
        -- Person information
        p.title,
        p.firstname,
        p.middlename,
        p.lastname,
        p.suffix,
        p.emailpromotion,
        -- Department
        d.name as department_name,
        d.groupname as department_group,
        -- Organization hierarchy
        e.organizationnode,
        -- Pay information
        eph.rate as current_pay_rate,
        eph.payfrequency,
        eph.ratechangedate as last_pay_change_date
    from {{ ref('stg_employee') }} e
    left join {{ ref('stg_person') }} p on e.businessentityid = p.businessentityid
    left join lateral (
        select name, groupname
        from {{ ref('stg_employeedepartmenthistory') }} edh
        join {{ ref('stg_department') }} d on edh.departmentid = d.departmentid
        where edh.businessentityid = e.businessentityid
        and edh.enddate is null
        order by edh.startdate desc
        limit 1
    ) d on true
    left join lateral (
        select rate, payfrequency, ratechangedate
        from {{ ref('stg_employeepayhistory') }} eph
        where eph.businessentityid = e.businessentityid
        order by eph.ratechangedate desc
        limit 1
    ) eph on true
),

employee_sales_performance as (
    select
        sp.businessentityid as employee_id,
        sp.territoryid,
        st.name as territory_name,
        sp.salesquota,
        sp.bonus,
        sp.commissionpct,
        sp.salesytd as sales_year_to_date,
        sp.saleslastyear as sales_last_year,
        sqh.salesquota as current_quota,
        sqh.quota_date,
        case
            when sp.salesquota > 0 then (sp.salesytd / sp.salesquota) * 100
            else 0
        end as quota_achievement_percent
    from {{ ref('stg_salesperson') }} sp
    left join {{ ref('stg_salesterritory') }} st on sp.territoryid = st.territoryid
    left join lateral (
        select salesquota, quotadate as quota_date
        from {{ ref('stg_salespersonquotahistory') }} sqh
        where sqh.businessentityid = sp.businessentityid
        order by sqh.quotadate desc
        limit 1
    ) sqh on true
),

employee_orders_summary as (
    select
        salespersonid as employee_id,
        count(distinct salesorderid) as total_orders_managed,
        sum(totaldue) as total_sales_revenue,
        avg(totaldue) as avg_order_value,
        min(orderdate) as first_order_date,
        max(orderdate) as last_order_date
    from {{ ref('stg_salesorderheader') }}
    where salespersonid is not null
    group by salespersonid
)

select
    eb.*,
    esp.territoryid,
    esp.territory_name,
    esp.salesquota,
    esp.bonus,
    esp.commissionpct,
    esp.sales_year_to_date,
    esp.sales_last_year,
    esp.current_quota,
    esp.quota_achievement_percent,
    eos.total_orders_managed,
    eos.total_sales_revenue,
    eos.avg_order_value,
    eos.first_order_date,
    eos.last_order_date,
    date_part('year', current_date) - date_part('year', eb.hiredate) as years_of_service,
    case
        when eb.currentflag = '1' then 'Active'
        else 'Inactive'
    end as employment_status
from employee_base eb
left join employee_sales_performance esp on eb.employee_id = esp.employee_id
left join employee_orders_summary eos on eb.employee_id = eos.employee_id

