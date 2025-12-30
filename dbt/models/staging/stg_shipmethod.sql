{{ config(materialized='view') }}

select
    "Name" as name,
    "rowguid" as rowguid,
    "ShipBase" as shipbase,
    "ShipRate" as shiprate,
    "ModifiedDate" as modifieddate,
    "ShipMethodID" as shipmethodid
from {{ source('raw_purchasing', 'ShipMethod') }}
