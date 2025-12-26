{{ config(materialized='view') }}

select
    name,
    rowguid,
    modifieddate,
    addresstypeid
from {{ source('raw', 'addresstype') }}
