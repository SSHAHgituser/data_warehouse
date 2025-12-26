{{ config(materialized='view') }}

select
    rowguid,
    productid,
    modifieddate,
    specialofferid
from {{ source('raw', 'specialofferproduct') }}
