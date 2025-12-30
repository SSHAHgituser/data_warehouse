{{ config(materialized='view') }}

select
    "rowguid" as rowguid,
    "PersonID" as personid,
    "ModifiedDate" as modifieddate,
    "ContactTypeID" as contacttypeid,
    "BusinessEntityID" as businessentityid
from {{ source('raw_person', 'BusinessEntityContact') }}
