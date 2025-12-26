{{ config(materialized='view') }}

select
    currencycode,
    modifieddate,
    countryregioncode
from {{ source('raw', 'countryregioncurrency') }}
