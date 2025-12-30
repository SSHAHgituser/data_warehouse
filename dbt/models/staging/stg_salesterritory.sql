{{ config(materialized='view') }}

select
    "Name" as name,
    "Group" as "group",
    "CostYTD" as costytd,
    "rowguid" as rowguid,
    "SalesYTD" as salesytd,
    "TerritoryID" as territoryid,
    "CostLastYear" as costlastyear,
    "ModifiedDate" as modifieddate,
    "SalesLastYear" as saleslastyear,
    "CountryRegionCode" as countryregioncode
from {{ source('raw_sales', 'SalesTerritory') }}
