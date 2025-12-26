{{ config(materialized='view') }}

select
    name,
    rowguid,
    taxrate,
    taxtype,
    modifieddate,
    salestaxrateid,
    stateprovinceid
from {{ source('raw', 'salestaxrate') }}
