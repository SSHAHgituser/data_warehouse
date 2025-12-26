{{ config(materialized='view') }}

select
    phonenumber,
    modifieddate,
    businessentityid,
    phonenumbertypeid
from {{ source('raw', 'personphone') }}
