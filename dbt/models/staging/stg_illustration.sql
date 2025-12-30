{{ config(materialized='view') }}

select
    "Diagram" as diagram,
    "ModifiedDate" as modifieddate,
    "IllustrationID" as illustrationid
from {{ source('raw_production', 'Illustration') }}
