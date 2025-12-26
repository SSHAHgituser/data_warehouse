{{ config(materialized='view') }}

select
    rating,
    comments,
    productid,
    reviewdate,
    emailaddress,
    modifieddate,
    reviewername,
    productreviewid
from {{ source('raw', 'productreview') }}
