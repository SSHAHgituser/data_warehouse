{{ config(materialized='view') }}

select
    "Name" as name,
    "EndTime" as endtime,
    "ShiftID" as shiftid,
    "StartTime" as starttime,
    "ModifiedDate" as modifieddate
from {{ source('raw_hr', 'Shift') }}
