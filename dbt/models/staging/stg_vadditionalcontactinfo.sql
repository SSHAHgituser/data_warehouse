{{ config(materialized='view') }}

select
    "City" as city,
    "Street" as street,
    "rowguid" as rowguid,
    "LastName" as lastname,
    "FirstName" as firstname,
    "MiddleName" as middlename,
    "PostalCode" as postalcode,
    "EMailAddress" as emailaddress,
    "ModifiedDate" as modifieddate,
    "CountryRegion" as countryregion,
    "StateProvince" as stateprovince,
    "TelephoneNumber" as telephonenumber,
    "BusinessEntityID" as businessentityid,
    "EMailTelephoneNumber" as emailtelephonenumber,
    "EMailSpecialInstructions" as emailspecialinstructions,
    "TelephoneSpecialInstructions" as telephonespecialinstructions,
    "HomeAddressSpecialInstructions" as homeaddressspecialinstructions
from {{ source('raw_person', 'vAdditionalContactInfo') }}
