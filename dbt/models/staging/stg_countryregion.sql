{{ config(materialized='view') }}

select
    "Name" as name,
    "ModifiedDate" as modifieddate,
    "CountryRegionCode" as countryregioncode
from {{ source('raw_person', 'CountryRegion') }}
