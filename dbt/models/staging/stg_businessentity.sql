{{ config(materialized='view') }}

select
    "rowguid" as rowguid,
    "ModifiedDate" as modifieddate,
    "BusinessEntityID" as businessentityid
from {{ source('raw_person', 'BusinessEntity') }}
