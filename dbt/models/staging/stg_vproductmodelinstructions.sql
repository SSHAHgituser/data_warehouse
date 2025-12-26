{{ config(materialized='view') }}

select
    "Step",
    name,
    "LotSize",
    rowguid,
    "LaborHours",
    "LocationID",
    "SetupHours",
    "MachineHours",
    instructions,
    modifieddate,
    productmodelid
from {{ source('raw', 'vproductmodelinstructions') }}
