{{ config(materialized='view') }}

select
    "Primary" as "primary",
    "ProductID" as productid,
    "ModifiedDate" as modifieddate,
    "ProductPhotoID" as productphotoid
from {{ source('raw_production', 'ProductProductPhoto') }}
