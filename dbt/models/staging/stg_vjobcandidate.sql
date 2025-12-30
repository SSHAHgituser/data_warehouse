{{ config(materialized='view') }}

select
    "EMail" as email,
    "Skills" as skills,
    "WebSite" as website,
    "Addr_Type" as addr_type,
    "Name_Last" as name_last,
    "Name_First" as name_first,
    "Name_Middle" as name_middle,
    "Name_Prefix" as name_prefix,
    "Name_Suffix" as name_suffix,
    "ModifiedDate" as modifieddate,
    "Addr_Loc_City" as addr_loc_city,
    "Addr_Loc_State" as addr_loc_state,
    "JobCandidateID" as jobcandidateid,
    "Addr_PostalCode" as addr_postalcode,
    "BusinessEntityID" as businessentityid,
    "Addr_Loc_CountryRegion" as addr_loc_countryregion
from {{ source('raw_hr', 'vJobCandidate') }}
