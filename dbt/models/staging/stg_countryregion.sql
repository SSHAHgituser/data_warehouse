{{ config(materialized='view') }}

select
    name,
    modifieddate,
    countryregioncode
from {{ source('raw', 'countryregion') }}
