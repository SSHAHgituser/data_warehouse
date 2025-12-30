{{ config(materialized='view') }}

select
    "Name" as name,
    "rowguid" as rowguid,
    "Demographics" as demographics,
    "ModifiedDate" as modifieddate,
    "SalesPersonID" as salespersonid,
    "BusinessEntityID" as businessentityid
from {{ source('raw_sales', 'Store') }}
