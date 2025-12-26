{{ config(materialized='view') }}

select
    diagram,
    modifieddate,
    illustrationid
from {{ source('raw', 'illustration') }}
