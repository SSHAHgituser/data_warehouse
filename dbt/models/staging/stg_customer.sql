{{ config(materialized='view') }}

select
    rowguid,
    storeid,
    personid,
    customerid,
    territoryid,
    modifieddate
from {{ source('raw', 'customer') }}
