{{ config(materialized='view') }}

select
    name,
    rowguid,
    instructions,
    modifieddate,
    productmodelid,
    catalogdescription
from {{ source('raw', 'productmodel') }}
