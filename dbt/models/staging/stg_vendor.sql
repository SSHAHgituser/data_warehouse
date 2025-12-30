{{ config(materialized='view') }}

select
    "Name" as name,
    "ActiveFlag" as activeflag,
    "CreditRating" as creditrating,
    "ModifiedDate" as modifieddate,
    "AccountNumber" as accountnumber,
    "BusinessEntityID" as businessentityid,
    "PreferredVendorStatus" as preferredvendorstatus,
    "PurchasingWebServiceURL" as purchasingwebserviceurl
from {{ source('raw_purchasing', 'Vendor') }}
