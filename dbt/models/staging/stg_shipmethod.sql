{{ config(materialized='view') }}

select
    name,
    rowguid,
    shipbase,
    shiprate,
    modifieddate,
    shipmethodid
from {{ source('raw', 'shipmethod') }}
