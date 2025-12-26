{{ config(materialized='view') }}

select
    name,
    costrate,
    locationid,
    availability,
    modifieddate
from {{ source('raw', 'location') }}
