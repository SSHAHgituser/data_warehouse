{{ config(materialized='view') }}

select
    "Name" as name,
    "ReasonType" as reasontype,
    "ModifiedDate" as modifieddate,
    "SalesReasonID" as salesreasonid
from {{ source('raw_sales', 'SalesReason') }}
