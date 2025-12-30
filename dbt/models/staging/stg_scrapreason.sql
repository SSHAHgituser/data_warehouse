{{ config(materialized='view') }}

select
    "Name" as name,
    "ModifiedDate" as modifieddate,
    "ScrapReasonID" as scrapreasonid
from {{ source('raw_production', 'ScrapReason') }}
