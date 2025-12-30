{{ config(materialized='view') }}

select
    "City" as city,
    "Name" as name,
    "PostalCode" as postalcode,
    "AddressType" as addresstype,
    "AddressLine1" as addressline1,
    "AddressLine2" as addressline2,
    "BusinessEntityID" as businessentityid,
    "CountryRegionName" as countryregionname,
    "StateProvinceName" as stateprovincename
from {{ source('raw_purchasing', 'vVendorWithAddresses') }}
