{{ config(materialized='view') }}

select
    "rowguid" as rowguid,
    "OrderQty" as orderqty,
    "LineTotal" as linetotal,
    "ProductID" as productid,
    "UnitPrice" as unitprice,
    "ModifiedDate" as modifieddate,
    "SalesOrderID" as salesorderid,
    "SpecialOfferID" as specialofferid,
    "UnitPriceDiscount" as unitpricediscount,
    "SalesOrderDetailID" as salesorderdetailid,
    "CarrierTrackingNumber" as carriertrackingnumber
from {{ source('raw_sales', 'SalesOrderDetail') }}
