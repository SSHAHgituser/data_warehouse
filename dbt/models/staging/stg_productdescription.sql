{{ config(materialized='view') }}

select
    "rowguid" as rowguid,
    "Description" as description,
    "ModifiedDate" as modifieddate,
    "ProductDescriptionID" as productdescriptionid
from {{ source('raw_production', 'ProductDescription') }}
