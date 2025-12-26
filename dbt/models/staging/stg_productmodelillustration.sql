{{ config(materialized='view') }}

select
    modifieddate,
    illustrationid,
    productmodelid
from {{ source('raw', 'productmodelillustration') }}
