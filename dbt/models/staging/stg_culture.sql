{{ config(materialized='view') }}

select
    "Name" as name,
    "CultureID" as cultureid,
    "ModifiedDate" as modifieddate
from {{ source('raw_production', 'Culture') }}
