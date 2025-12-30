{{ config(materialized='view') }}

select
    "Name" as name,
    "rowguid" as rowguid,
    "ModifiedDate" as modifieddate,
    "ProductCategoryID" as productcategoryid,
    "ProductSubcategoryID" as productsubcategoryid
from {{ source('raw_production', 'ProductSubcategory') }}
