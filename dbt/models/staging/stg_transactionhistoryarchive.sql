{{ config(materialized='view') }}

select
    "Quantity" as quantity,
    "ProductID" as productid,
    "ActualCost" as actualcost,
    "ModifiedDate" as modifieddate,
    "TransactionID" as transactionid,
    "TransactionDate" as transactiondate,
    "TransactionType" as transactiontype,
    "ReferenceOrderID" as referenceorderid,
    "ReferenceOrderLineID" as referenceorderlineid
from {{ source('raw_production', 'TransactionHistoryArchive') }}
