{{ config(materialized='view') }}

select
    "Name" as name,
    "Color" as color,
    "Pedal" as pedal,
    "Style" as style,
    "Wheel" as wheel,
    "Saddle" as saddle,
    "Summary" as summary,
    "rowguid" as rowguid,
    "Crankset" as crankset,
    "Material" as material,
    "BikeFrame" as bikeframe,
    "Copyright" as copyright,
    "NoOfYears" as noofyears,
    "ProductURL" as producturl,
    "PictureSize" as picturesize,
    "ProductLine" as productline,
    "Manufacturer" as manufacturer,
    "ModifiedDate" as modifieddate,
    "PictureAngle" as pictureangle,
    "ProductModelID" as productmodelid,
    "ProductPhotoID" as productphotoid,
    "WarrantyPeriod" as warrantyperiod,
    "RiderExperience" as riderexperience,
    "WarrantyDescription" as warrantydescription,
    "MaintenanceDescription" as maintenancedescription
from {{ source('raw_production', 'vProductModelCatalogDescription') }}
