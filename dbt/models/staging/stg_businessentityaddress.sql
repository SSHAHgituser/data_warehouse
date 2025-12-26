{{ config(materialized='view') }}

select
    rowguid,
    addressid,
    modifieddate,
    addresstypeid,
    businessentityid
from {{ source('raw', 'businessentityaddress') }}
