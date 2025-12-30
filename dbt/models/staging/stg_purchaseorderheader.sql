{{ config(materialized='view') }}

select
    "Status" as status,
    "TaxAmt" as taxamt,
    "Freight" as freight,
    "ShipDate" as shipdate,
    "SubTotal" as subtotal,
    "TotalDue" as totaldue,
    "VendorID" as vendorid,
    "OrderDate" as orderdate,
    "EmployeeID" as employeeid,
    "ModifiedDate" as modifieddate,
    "ShipMethodID" as shipmethodid,
    "RevisionNumber" as revisionnumber,
    "PurchaseOrderID" as purchaseorderid
from {{ source('raw_purchasing', 'PurchaseOrderHeader') }}
