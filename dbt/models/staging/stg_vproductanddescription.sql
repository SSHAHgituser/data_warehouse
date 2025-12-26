{{ config(materialized='view') }}

select
    name,
    cultureid,
    productid,
    description,
    productmodel
from {{ source('raw', 'vproductanddescription') }}
