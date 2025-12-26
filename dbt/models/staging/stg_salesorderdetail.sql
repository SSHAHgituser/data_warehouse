{{ config(materialized='view') }}

select
    rowguid,
    orderqty,
    productid,
    unitprice,
    modifieddate,
    salesorderid,
    specialofferid,
    unitpricediscount,
    salesorderdetailid,
    carriertrackingnumber
from {{ source('raw', 'salesorderdetail') }}
