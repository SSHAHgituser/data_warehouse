{{ config(materialized='view') }}

select
    name,
    rowguid,
    modifieddate,
    productcategoryid
from {{ source('raw', 'productcategory') }}
