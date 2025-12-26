{{ config(materialized='view') }}

select
    name,
    "group",
    costytd,
    rowguid,
    salesytd,
    territoryid,
    costlastyear,
    modifieddate,
    saleslastyear,
    countryregioncode
from {{ source('raw', 'salesterritory') }}
