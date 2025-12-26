{{ config(materialized='view') }}

select
    name,
    modifieddate,
    unitmeasurecode
from {{ source('raw', 'unitmeasure') }}
