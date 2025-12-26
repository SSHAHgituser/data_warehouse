{{ config(materialized='view') }}

select
    rowguid,
    emailaddress,
    modifieddate,
    emailaddressid,
    businessentityid
from {{ source('raw', 'emailaddress') }}
