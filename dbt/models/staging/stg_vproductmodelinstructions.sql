{{ config(materialized='view') }}

select
    "Name" as name,
    "Step" as step,
    "LotSize" as lotsize,
    "rowguid" as rowguid,
    "LaborHours" as laborhours,
    "LocationID" as locationid,
    "SetupHours" as setuphours,
    "Instructions" as instructions,
    "MachineHours" as machinehours,
    "ModifiedDate" as modifieddate,
    "ProductModelID" as productmodelid
from {{ source('raw_production', 'vProductModelInstructions') }}
