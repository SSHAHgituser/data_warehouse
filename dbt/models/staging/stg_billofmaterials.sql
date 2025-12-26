{{ config(materialized='view') }}

select
    enddate,
    bomlevel,
    startdate,
    componentid,
    modifieddate,
    perassemblyqty,
    unitmeasurecode,
    billofmaterialsid,
    productassemblyid
from {{ source('raw', 'billofmaterials') }}
