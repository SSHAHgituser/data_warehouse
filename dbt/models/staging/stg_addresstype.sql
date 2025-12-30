{{ config(materialized='view') }}

select
    "Name" as name,
    "rowguid" as rowguid,
    "ModifiedDate" as modifieddate,
    "AddressTypeID" as addresstypeid
from {{ source('raw_person', 'AddressType') }}
