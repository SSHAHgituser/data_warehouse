{{ config(materialized='view') }}

select
    "City" as city,
    "Title" as title,
    "Suffix" as suffix,
    "JobTitle" as jobtitle,
    "LastName" as lastname,
    "SalesYTD" as salesytd,
    "FirstName" as firstname,
    "MiddleName" as middlename,
    "PostalCode" as postalcode,
    "SalesQuota" as salesquota,
    "PhoneNumber" as phonenumber,
    "AddressLine1" as addressline1,
    "AddressLine2" as addressline2,
    "EmailAddress" as emailaddress,
    "SalesLastYear" as saleslastyear,
    "TerritoryName" as territoryname,
    "EmailPromotion" as emailpromotion,
    "TerritoryGroup" as territorygroup,
    "PhoneNumberType" as phonenumbertype,
    "BusinessEntityID" as businessentityid,
    "CountryRegionName" as countryregionname,
    "StateProvinceName" as stateprovincename
from {{ source('raw_sales', 'vSalesPerson') }}
