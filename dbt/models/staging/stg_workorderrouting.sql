{{ config(materialized='view') }}

select
    "ProductID" as productid,
    "ActualCost" as actualcost,
    "LocationID" as locationid,
    "PlannedCost" as plannedcost,
    "WorkOrderID" as workorderid,
    "ModifiedDate" as modifieddate,
    "ActualEndDate" as actualenddate,
    "ActualStartDate" as actualstartdate,
    "ScheduledEndDate" as scheduledenddate,
    "ActualResourceHrs" as actualresourcehrs,
    "OperationSequence" as operationsequence,
    "ScheduledStartDate" as scheduledstartdate
from {{ source('raw_production', 'WorkOrderRouting') }}
