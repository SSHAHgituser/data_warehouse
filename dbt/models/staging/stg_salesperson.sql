{{ config(materialized='view') }}

select
    bonus,
    rowguid,
    salesytd,
    salesquota,
    territoryid,
    modifieddate,
    commissionpct,
    saleslastyear,
    businessentityid
from {{ source('raw', 'salesperson') }}
