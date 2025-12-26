{{ config(materialized='table') }}

with sales_person_quota_history as (
    select
        businessentityid,
        quotadate,
        salesquota,
        rowguid,
        modifieddate
    from {{ ref('stg_salespersonquotahistory') }}
),

sales_person_info as (
    select
        businessentityid,
        territoryid,
        salesquota as current_quota,
        bonus,
        commissionpct,
        salesytd,
        saleslastyear
    from {{ ref('stg_salesperson') }}
),

quota_performance as (
    select
        sqh.businessentityid,
        sqh.quotadate,
        sqh.salesquota,
        spi.territoryid,
        spi.current_quota,
        spi.bonus,
        spi.commissionpct,
        spi.salesytd,
        spi.saleslastyear,
        -- Calculate quota achievement
        case
            when sqh.salesquota > 0 then (spi.salesytd / sqh.salesquota) * 100
            else 0
        end as quota_achievement_percent,
        (spi.salesytd - sqh.salesquota) as quota_variance,
        sqh.rowguid,
        sqh.modifieddate
    from sales_person_quota_history sqh
    left join sales_person_info spi on sqh.businessentityid = spi.businessentityid
)

select
    businessentityid as employee_key,
    cast(to_char(quotadate, 'YYYYMMDD') as integer) as quota_date_key,
    territoryid as territory_key,
    quotadate,
    salesquota,
    current_quota,
    bonus,
    commissionpct,
    salesytd,
    saleslastyear,
    quota_achievement_percent,
    quota_variance,
    case
        when quota_achievement_percent >= 100 then 'Achieved'
        when quota_achievement_percent >= 80 then 'Near Target'
        else 'Below Target'
    end as quota_status,
    rowguid,
    modifieddate
from quota_performance

