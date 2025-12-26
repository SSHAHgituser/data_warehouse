{{ config(materialized='view') }}

select
    quantity,
    productid,
    actualcost,
    modifieddate,
    transactionid,
    transactiondate,
    transactiontype,
    referenceorderid,
    referenceorderlineid
from {{ source('raw', 'transactionhistory') }}
