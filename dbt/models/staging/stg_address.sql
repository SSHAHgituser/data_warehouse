{{ config(materialized='view') }}

select
    "City" as city,
    "rowguid" as rowguid,
    "AddressID" as addressid,
    "PostalCode" as postalcode,
    "AddressLine1" as addressline1,
    "AddressLine2" as addressline2,
    "ModifiedDate" as modifieddate,
    "SpatialLocation" as spatiallocation,
    "StateProvinceID" as stateprovinceid
from {{ source('raw_person', 'Address') }}
