{{ config(materialized='view') }}

select
    "TerritoryID" as territoryid,
    "StateProvinceID" as stateprovinceid,
    "CountryRegionCode" as countryregioncode,
    "CountryRegionName" as countryregionname,
    "StateProvinceCode" as stateprovincecode,
    "StateProvinceName" as stateprovincename,
    "IsOnlyStateProvinceFlag" as isonlystateprovinceflag
from {{ source('raw_person', 'vStateProvinceCountryRegion') }}
