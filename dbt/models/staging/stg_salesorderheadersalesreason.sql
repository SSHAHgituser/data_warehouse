{{ config(materialized='view') }}

select
    "ModifiedDate" as modifieddate,
    "SalesOrderID" as salesorderid,
    "SalesReasonID" as salesreasonid
from {{ source('raw_sales', 'SalesOrderHeaderSalesReason') }}
