{{ config(materialized='view') }}

select
    "EndDate" as enddate,
    "BOMLevel" as bomlevel,
    "StartDate" as startdate,
    "ComponentID" as componentid,
    "ModifiedDate" as modifieddate,
    "PerAssemblyQty" as perassemblyqty,
    "UnitMeasureCode" as unitmeasurecode,
    "BillOfMaterialsID" as billofmaterialsid,
    "ProductAssemblyID" as productassemblyid
from {{ source('raw_production', 'BillOfMaterials') }}
