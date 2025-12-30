{{ config(materialized='view') }}

select
    "Type" as "type",
    "MaxQty" as maxqty,
    "MinQty" as minqty,
    "EndDate" as enddate,
    "rowguid" as rowguid,
    "Category" as category,
    "StartDate" as startdate,
    "Description" as description,
    "DiscountPct" as discountpct,
    "ModifiedDate" as modifieddate,
    "SpecialOfferID" as specialofferid
from {{ source('raw_sales', 'SpecialOffer') }}
