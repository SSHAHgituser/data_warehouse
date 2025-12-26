{{ config(materialized='view') }}

select
    rowguid,
    modifieddate,
    businessentityid
from {{ source('raw', 'businessentity') }}
