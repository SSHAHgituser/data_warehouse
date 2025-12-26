{{ config(materialized='view') }}

select
    enddate,
    shiftid,
    startdate,
    departmentid,
    modifieddate,
    businessentityid
from {{ source('raw', 'employeedepartmenthistory') }}
