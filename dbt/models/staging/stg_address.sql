{{ config(materialized='view') }}

select
    city,
    rowguid,
    addressid,
    postalcode,
    addressline1,
    addressline2,
    modifieddate,
    spatiallocation,
    stateprovinceid
from {{ source('raw', 'address') }}
