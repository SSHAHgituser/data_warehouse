{{ config(materialized='view') }}

select
    "DueDate" as duedate,
    "EndDate" as enddate,
    "OrderQty" as orderqty,
    "ProductID" as productid,
    "StartDate" as startdate,
    "StockedQty" as stockedqty,
    "ScrappedQty" as scrappedqty,
    "WorkOrderID" as workorderid,
    "ModifiedDate" as modifieddate,
    "ScrapReasonID" as scrapreasonid
from {{ source('raw_production', 'WorkOrder') }}
