{{ config(materialized='view') }}

select
    duedate,
    orderqty,
    productid,
    unitprice,
    receivedqty,
    rejectedqty,
    modifieddate,
    purchaseorderid,
    purchaseorderdetailid
from {{ source('raw', 'purchaseorderdetail') }}
