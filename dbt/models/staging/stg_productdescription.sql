{{ config(materialized='view') }}

select
    rowguid,
    description,
    modifieddate,
    productdescriptionid
from {{ source('raw', 'productdescription') }}
