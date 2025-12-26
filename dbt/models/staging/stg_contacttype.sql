{{ config(materialized='view') }}

select
    name,
    modifieddate,
    contacttypeid
from {{ source('raw', 'contacttype') }}
