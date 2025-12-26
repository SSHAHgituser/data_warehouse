{{ config(materialized='view') }}

select
    territoryid,
    stateprovinceid,
    countryregioncode,
    countryregionname,
    stateprovincecode,
    stateprovincename,
    isonlystateprovinceflag
from {{ source('raw', 'vstateprovincecountryregion') }}
