{{ config(materialized='view') }}

select
    rowguid,
    quotadate,
    salesquota,
    modifieddate,
    businessentityid
from {{ source('raw', 'salespersonquotahistory') }}
