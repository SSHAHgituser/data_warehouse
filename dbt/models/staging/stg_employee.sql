{{ config(materialized='view') }}

select
    "Gender" as gender,
    "LoginID" as loginid,
    "rowguid" as rowguid,
    "HireDate" as hiredate,
    "JobTitle" as jobtitle,
    "BirthDate" as birthdate,
    "CurrentFlag" as currentflag,
    "ModifiedDate" as modifieddate,
    "SalariedFlag" as salariedflag,
    "MaritalStatus" as maritalstatus,
    "VacationHours" as vacationhours,
    "SickLeaveHours" as sickleavehours,
    "BusinessEntityID" as businessentityid,
    "NationalIDNumber" as nationalidnumber,
    "OrganizationNode" as organizationnode,
    "OrganizationLevel" as organizationlevel
from {{ source('raw_hr', 'Employee') }}
