{{ config(materialized='view') }}

select
    status,
    taxamt,
    freight,
    shipdate,
    subtotal,
    vendorid,
    orderdate,
    employeeid,
    modifieddate,
    shipmethodid,
    revisionnumber,
    purchaseorderid
from {{ source('raw', 'purchaseorderheader') }}
