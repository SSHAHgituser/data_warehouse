{{ config(materialized='view') }}

select
    "primary",
    productid,
    modifieddate,
    productphotoid
from {{ source('raw', 'productproductphoto') }}
