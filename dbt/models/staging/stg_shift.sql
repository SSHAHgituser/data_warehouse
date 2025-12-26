{{ config(materialized='view') }}

select
    name,
    endtime,
    shiftid,
    starttime,
    modifieddate
from {{ source('raw', 'shift') }}
