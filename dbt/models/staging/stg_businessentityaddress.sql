{{ config(materialized='view') }}

select
    "rowguid" as rowguid,
    "AddressID" as addressid,
    "ModifiedDate" as modifieddate,
    "AddressTypeID" as addresstypeid,
    "BusinessEntityID" as businessentityid
from {{ source('raw_person', 'BusinessEntityAddress') }}
