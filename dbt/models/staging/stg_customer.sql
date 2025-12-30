{{ config(materialized='view') }}

select
    "StoreID" as storeid,
    "rowguid" as rowguid,
    "PersonID" as personid,
    "CustomerID" as customerid,
    "TerritoryID" as territoryid,
    "ModifiedDate" as modifieddate,
    "AccountNumber" as accountnumber
from {{ source('raw_sales', 'Customer') }}
