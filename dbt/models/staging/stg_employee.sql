{{ config(materialized='view') }}

select
    gender,
    loginid,
    rowguid,
    hiredate,
    jobtitle,
    birthdate,
    currentflag,
    modifieddate,
    salariedflag,
    maritalstatus,
    vacationhours,
    sickleavehours,
    businessentityid,
    nationalidnumber,
    organizationnode
from {{ source('raw', 'employee') }}
