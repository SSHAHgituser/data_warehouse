{{ config(materialized='view') }}

select
    name,
    groupname,
    departmentid,
    modifieddate
from {{ source('raw', 'department') }}
