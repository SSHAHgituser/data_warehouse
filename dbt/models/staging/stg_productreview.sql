{{ config(materialized='view') }}

select
    "Rating" as rating,
    "Comments" as comments,
    "ProductID" as productid,
    "ReviewDate" as reviewdate,
    "EmailAddress" as emailaddress,
    "ModifiedDate" as modifieddate,
    "ReviewerName" as reviewername,
    "ProductReviewID" as productreviewid
from {{ source('raw_production', 'ProductReview') }}
