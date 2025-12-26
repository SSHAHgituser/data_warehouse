{{ config(materialized='view') }}

select
    enddate,
    rowguid,
    startdate,
    territoryid,
    modifieddate,
    businessentityid
from {{ source('raw', 'salesterritoryhistory') }}
