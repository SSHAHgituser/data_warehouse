{{ config(materialized='view') }}

select
    "Name" as name,
    "TaxRate" as taxrate,
    "TaxType" as taxtype,
    "rowguid" as rowguid,
    "ModifiedDate" as modifieddate,
    "SalesTaxRateID" as salestaxrateid,
    "StateProvinceID" as stateprovinceid
from {{ source('raw_sales', 'SalesTaxRate') }}
