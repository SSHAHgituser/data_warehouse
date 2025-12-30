{{ config(materialized='view') }}

select
    "Name" as name,
    "rowguid" as rowguid,
    "ModifiedDate" as modifieddate,
    "ProductCategoryID" as productcategoryid
from {{ source('raw_production', 'ProductCategory') }}
