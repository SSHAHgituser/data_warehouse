{{ config(materialized='view') }}

select
    "Name" as name,
    "CostRate" as costrate,
    "LocationID" as locationid,
    "Availability" as availability,
    "ModifiedDate" as modifieddate
from {{ source('raw_production', 'Location') }}
