{{ config(materialized='view') }}

select
    status,
    taxamt,
    comment,
    duedate,
    freight,
    rowguid,
    shipdate,
    subtotal,
    totaldue,
    orderdate,
    customerid,
    territoryid,
    creditcardid,
    modifieddate,
    salesorderid,
    shipmethodid,
    accountnumber,
    salespersonid,
    currencyrateid,
    revisionnumber,
    billtoaddressid,
    onlineorderflag,
    shiptoaddressid,
    purchaseordernumber,
    creditcardapprovalcode
from {{ source('raw', 'salesorderheader') }}
