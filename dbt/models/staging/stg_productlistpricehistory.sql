{{ config(materialized='view') }}

select
    enddate,
    listprice,
    productid,
    startdate,
    modifieddate
from {{ source('raw', 'productlistpricehistory') }}
