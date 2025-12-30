{{ config(materialized='view') }}

select
    "EndDate" as enddate,
    "ProductID" as productid,
    "StartDate" as startdate,
    "ModifiedDate" as modifieddate,
    "StandardCost" as standardcost
from {{ source('raw_production', 'ProductCostHistory') }}
