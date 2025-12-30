{{ config(materialized='view') }}

select
    "EndDate" as enddate,
    "rowguid" as rowguid,
    "StartDate" as startdate,
    "TerritoryID" as territoryid,
    "ModifiedDate" as modifieddate,
    "BusinessEntityID" as businessentityid
from {{ source('raw_sales', 'SalesTerritoryHistory') }}
