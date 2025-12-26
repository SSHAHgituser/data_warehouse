{{ config(materialized='view') }}

select
    bin,
    shelf,
    rowguid,
    quantity,
    productid,
    locationid,
    modifieddate
from {{ source('raw', 'productinventory') }}
