{{ config(materialized='view') }}

select
    name,
    modifieddate,
    phonenumbertypeid
from {{ source('raw', 'phonenumbertype') }}
