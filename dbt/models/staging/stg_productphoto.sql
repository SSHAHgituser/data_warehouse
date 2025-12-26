{{ config(materialized='view') }}

select
    largephoto,
    modifieddate,
    productphotoid,
    thumbnailphoto,
    largephotofilename,
    thumbnailphotofilename
from {{ source('raw', 'productphoto') }}
