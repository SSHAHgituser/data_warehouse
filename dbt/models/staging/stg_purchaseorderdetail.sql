{{ config(materialized='view') }}

select
    "DueDate" as duedate,
    "OrderQty" as orderqty,
    "LineTotal" as linetotal,
    "ProductID" as productid,
    "UnitPrice" as unitprice,
    "StockedQty" as stockedqty,
    "ReceivedQty" as receivedqty,
    "RejectedQty" as rejectedqty,
    "ModifiedDate" as modifieddate,
    "PurchaseOrderID" as purchaseorderid,
    "PurchaseOrderDetailID" as purchaseorderdetailid
from {{ source('raw_purchasing', 'PurchaseOrderDetail') }}
