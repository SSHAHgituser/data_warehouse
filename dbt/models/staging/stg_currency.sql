{{ config(materialized='view') }}

select
    name,
    currencycode,
    modifieddate
from {{ source('raw', 'currency') }}
