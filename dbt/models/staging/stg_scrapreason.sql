{{ config(materialized='view') }}

select
    name,
    modifieddate,
    scrapreasonid
from {{ source('raw', 'scrapreason') }}
