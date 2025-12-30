{{ config(materialized='view') }}

select
    "ProductID" as productid,
    "DocumentNode" as documentnode,
    "ModifiedDate" as modifieddate
from {{ source('raw_production', 'ProductDocument') }}
