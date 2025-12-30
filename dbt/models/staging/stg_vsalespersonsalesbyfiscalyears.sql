{{ config(materialized='view') }}

select
    "_2002" as _2002,
    "_2003" as _2003,
    "_2004" as _2004,
    "FullName" as fullname,
    "JobTitle" as jobtitle,
    "SalesPersonID" as salespersonid,
    "SalesTerritory" as salesterritory
from {{ source('raw_sales', 'vSalesPersonSalesByFiscalYears') }}
