{{ config(materialized='view') }}

select
    "Title" as title,
    "Suffix" as suffix,
    "rowguid" as rowguid,
    "LastName" as lastname,
    "FirstName" as firstname,
    "NameStyle" as namestyle,
    "MiddleName" as middlename,
    "PersonType" as persontype,
    "Demographics" as demographics,
    "ModifiedDate" as modifieddate,
    "EmailPromotion" as emailpromotion,
    "BusinessEntityID" as businessentityid,
    "AdditionalContactInfo" as additionalcontactinfo
from {{ source('raw_person', 'Person') }}
