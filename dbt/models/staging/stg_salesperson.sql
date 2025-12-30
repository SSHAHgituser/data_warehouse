{{ config(materialized='view') }}

select
    "Bonus" as bonus,
    "rowguid" as rowguid,
    "SalesYTD" as salesytd,
    "SalesQuota" as salesquota,
    "TerritoryID" as territoryid,
    "ModifiedDate" as modifieddate,
    "CommissionPct" as commissionpct,
    "SalesLastYear" as saleslastyear,
    "BusinessEntityID" as businessentityid
from {{ source('raw_sales', 'SalesPerson') }}
