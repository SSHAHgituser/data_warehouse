{{ config(materialized='view') }}

select
    "rowguid" as rowguid,
    "QuotaDate" as quotadate,
    "SalesQuota" as salesquota,
    "ModifiedDate" as modifieddate,
    "BusinessEntityID" as businessentityid
from {{ source('raw_sales', 'SalesPersonQuotaHistory') }}
