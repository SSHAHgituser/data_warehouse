{{ config(materialized='view') }}

select
    name,
    rowguid,
    modifieddate,
    productcategoryid,
    productsubcategoryid
from {{ source('raw', 'productsubcategory') }}
