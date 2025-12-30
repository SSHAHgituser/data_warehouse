{{ config(materialized='view') }}

select
    "City" as city,
    "Title" as title,
    "Suffix" as suffix,
    "JobTitle" as jobtitle,
    "LastName" as lastname,
    "FirstName" as firstname,
    "MiddleName" as middlename,
    "PostalCode" as postalcode,
    "PhoneNumber" as phonenumber,
    "AddressLine1" as addressline1,
    "AddressLine2" as addressline2,
    "EmailAddress" as emailaddress,
    "EmailPromotion" as emailpromotion,
    "PhoneNumberType" as phonenumbertype,
    "BusinessEntityID" as businessentityid,
    "CountryRegionName" as countryregionname,
    "StateProvinceName" as stateprovincename,
    "AdditionalContactInfo" as additionalcontactinfo
from {{ source('raw_hr', 'vEmployee') }}
