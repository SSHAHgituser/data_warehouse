{{ config(materialized='view') }}

select
    "Name" as name,
    "Title" as title,
    "Suffix" as suffix,
    "LastName" as lastname,
    "FirstName" as firstname,
    "MiddleName" as middlename,
    "ContactType" as contacttype,
    "PhoneNumber" as phonenumber,
    "EmailAddress" as emailaddress,
    "EmailPromotion" as emailpromotion,
    "PhoneNumberType" as phonenumbertype,
    "BusinessEntityID" as businessentityid
from {{ source('raw_purchasing', 'vVendorWithContacts') }}
