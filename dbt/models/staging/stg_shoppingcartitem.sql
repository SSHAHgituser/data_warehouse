{{ config(materialized='view') }}

select
    quantity,
    productid,
    datecreated,
    modifieddate,
    shoppingcartid,
    shoppingcartitemid
from {{ source('raw', 'shoppingcartitem') }}
