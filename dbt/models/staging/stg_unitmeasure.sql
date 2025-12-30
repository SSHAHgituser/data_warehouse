{{ config(materialized='view') }}

select
    "Name" as name,
    "ModifiedDate" as modifieddate,
    "UnitMeasureCode" as unitmeasurecode
from {{ source('raw_production', 'UnitMeasure') }}
