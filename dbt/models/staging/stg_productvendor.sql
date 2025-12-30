{{ config(materialized='view') }}

select
    "ProductID" as productid,
    "OnOrderQty" as onorderqty,
    "MaxOrderQty" as maxorderqty,
    "MinOrderQty" as minorderqty,
    "ModifiedDate" as modifieddate,
    "StandardPrice" as standardprice,
    "AverageLeadTime" as averageleadtime,
    "LastReceiptCost" as lastreceiptcost,
    "LastReceiptDate" as lastreceiptdate,
    "UnitMeasureCode" as unitmeasurecode,
    "BusinessEntityID" as businessentityid
from {{ source('raw_purchasing', 'ProductVendor') }}
