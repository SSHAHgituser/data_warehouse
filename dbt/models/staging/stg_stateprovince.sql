{{ config(materialized='view') }}

select
    name,
    rowguid,
    territoryid,
    modifieddate,
    stateprovinceid,
    countryregioncode,
    stateprovincecode,
    isonlystateprovinceflag
from {{ source('raw', 'stateprovince') }}
