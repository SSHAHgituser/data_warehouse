{{ config(materialized='view') }}

select
    rowguid,
    personid,
    modifieddate,
    contacttypeid,
    businessentityid
from {{ source('raw', 'businessentitycontact') }}
