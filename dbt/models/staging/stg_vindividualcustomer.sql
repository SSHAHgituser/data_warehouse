{{ config(materialized='view') }}

select
    "City" as city,
    "Title" as title,
    "Suffix" as suffix,
    "LastName" as lastname,
    "FirstName" as firstname,
    "MiddleName" as middlename,
    "PostalCode" as postalcode,
    "AddressType" as addresstype,
    "PhoneNumber" as phonenumber,
    "AddressLine1" as addressline1,
    "AddressLine2" as addressline2,
    "Demographics" as demographics,
    "EmailAddress" as emailaddress,
    "EmailPromotion" as emailpromotion,
    "PhoneNumberType" as phonenumbertype,
    "BusinessEntityID" as businessentityid,
    "CountryRegionName" as countryregionname,
    "StateProvinceName" as stateprovincename
from {{ source('raw_sales', 'vIndividualCustomer') }}
