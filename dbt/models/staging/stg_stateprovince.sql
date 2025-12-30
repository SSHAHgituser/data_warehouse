{{ config(materialized='view') }}

select
    "Name" as name,
    "rowguid" as rowguid,
    "TerritoryID" as territoryid,
    "ModifiedDate" as modifieddate,
    "StateProvinceID" as stateprovinceid,
    "CountryRegionCode" as countryregioncode,
    "StateProvinceCode" as stateprovincecode,
    "IsOnlyStateProvinceFlag" as isonlystateprovinceflag
from {{ source('raw_person', 'StateProvince') }}
