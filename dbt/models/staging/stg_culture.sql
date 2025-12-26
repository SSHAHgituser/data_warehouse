{{ config(materialized='view') }}

select
    name,
    cultureid,
    modifieddate
from {{ source('raw', 'culture') }}
