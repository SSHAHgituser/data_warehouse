{{ config(materialized='view') }}

select
    name,
    rowguid,
    demographics,
    modifieddate,
    salespersonid,
    businessentityid
from {{ source('raw', 'store') }}
