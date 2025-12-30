{{ config(materialized='view') }}

select
    "ModifiedDate" as modifieddate,
    "IllustrationID" as illustrationid,
    "ProductModelID" as productmodelid
from {{ source('raw_production', 'ProductModelIllustration') }}
