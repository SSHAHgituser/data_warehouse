{{ config(materialized='view') }}

select
    city,
    name,
    postalcode,
    addresstype,
    addressline1,
    addressline2,
    businessentityid,
    countryregionname,
    stateprovincename
from {{ source('raw', 'vstorewithaddresses') }}
