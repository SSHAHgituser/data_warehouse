{{ config(materialized='view') }}

select
    "EndDate" as enddate,
    "ListPrice" as listprice,
    "ProductID" as productid,
    "StartDate" as startdate,
    "ModifiedDate" as modifieddate
from {{ source('raw_production', 'ProductListPriceHistory') }}
