{{ config(materialized='view') }}

select
    name,
    color,
    pedal,
    style,
    wheel,
    saddle,
    "Summary",
    rowguid,
    crankset,
    material,
    bikeframe,
    copyright,
    noofyears,
    producturl,
    picturesize,
    productline,
    manufacturer,
    modifieddate,
    pictureangle,
    productmodelid,
    productphotoid,
    warrantyperiod,
    riderexperience,
    warrantydescription,
    maintenancedescription
from {{ source('raw', 'vproductmodelcatalogdescription') }}
