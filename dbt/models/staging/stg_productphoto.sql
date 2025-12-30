{{ config(materialized='view') }}

select
    "LargePhoto" as largephoto,
    "ModifiedDate" as modifieddate,
    "ProductPhotoID" as productphotoid,
    "ThumbNailPhoto" as thumbnailphoto,
    "LargePhotoFileName" as largephotofilename,
    "ThumbnailPhotoFileName" as thumbnailphotofilename
from {{ source('raw_production', 'ProductPhoto') }}
