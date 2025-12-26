{{ config(materialized='table') }}

with customer_base as (
    select
        c.customerid,
        c.personid,
        c.storeid,
        c.territoryid,
        c.rowguid,
        c.modifieddate,
        -- Person information
        p.title,
        p.firstname,
        p.middlename,
        p.lastname,
        p.suffix,
        p.namestyle,
        p.emailpromotion,
        p.demographics,
        -- Store information
        s.name as store_name,
        s.salespersonid as store_salespersonid,
        -- Territory information
        st.name as territory_name,
        st.countryregioncode,
        st."group" as territory_group,
        st.salesytd as territory_sales_ytd,
        st.saleslastyear as territory_sales_last_year,
        st.costytd as territory_cost_ytd,
        st.costlastyear as territory_cost_last_year
    from {{ ref('stg_customer') }} c
    left join {{ ref('stg_person') }} p on c.personid = p.businessentityid
    left join {{ ref('stg_store') }} s on c.storeid = s.businessentityid
    left join {{ ref('stg_salesterritory') }} st on c.territoryid = st.territoryid
),

customer_sales_summary as (
    select
        soh.customerid,
        count(distinct soh.salesorderid) as total_orders,
        sum(soh.totaldue) as lifetime_value,
        min(soh.orderdate) as first_order_date,
        max(soh.orderdate) as last_order_date,
        avg(soh.totaldue) as avg_order_value,
        sum(sod.orderqty) as total_quantity_purchased
    from {{ ref('stg_salesorderheader') }} soh
    left join {{ ref('stg_salesorderdetail') }} sod on soh.salesorderid = sod.salesorderid
    group by soh.customerid
),

customer_segmentation as (
    select
        customerid,
        case
            when lifetime_value >= 50000 then 'High Value'
            when lifetime_value >= 20000 then 'Medium Value'
            else 'Low Value'
        end as customer_segment,
        case
            when date_part('day', current_date - last_order_date) <= 90 then 'Active'
            when date_part('day', current_date - last_order_date) <= 180 then 'At Risk'
            else 'Inactive'
        end as customer_status,
        case
            when total_orders >= 10 then 'Frequent'
            when total_orders >= 5 then 'Regular'
            else 'Occasional'
        end as purchase_frequency
    from customer_sales_summary
)

select
    cb.*,
    css.total_orders,
    css.lifetime_value,
    css.first_order_date,
    css.last_order_date,
    css.avg_order_value,
    css.total_quantity_purchased,
    cs.customer_segment,
    cs.customer_status,
    cs.purchase_frequency,
    date_part('day', css.last_order_date - css.first_order_date) as customer_tenure_days,
    case
        when css.total_orders > 0 then css.lifetime_value / css.total_orders
        else 0
    end as avg_order_value_calculated
from customer_base cb
left join customer_sales_summary css on cb.customerid = css.customerid
left join customer_segmentation cs on cb.customerid = cs.customerid

