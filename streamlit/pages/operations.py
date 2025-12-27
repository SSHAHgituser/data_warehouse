"""
Operations & Supply Chain Analytics Page
Supports: Vendor performance, Production efficiency, Shipping & logistics
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

def render(conn):
    st.header("⚙️ Operations & Supply Chain Analytics")
    st.markdown("Analyze vendor performance, production efficiency, and supply chain operations")
    
    tab1, tab2, tab3 = st.tabs([
        "🏭 Production Efficiency",
        "🚚 Vendor Performance",
        "📦 Shipping & Logistics"
    ])
    
    with tab1:
        st.subheader("Production Efficiency Analysis")
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    product_name,
                    category_name,
                    COUNT(DISTINCT operation_id) as total_work_orders,
                    AVG(production_days) as avg_production_days,
                    AVG(cost_variance_percent) as avg_cost_variance,
                    AVG(scrap_rate_percent) as avg_scrap_rate,
                    SUM(CASE WHEN delivery_status = 'On Time' THEN 1 ELSE 0 END) as on_time_count,
                    SUM(CASE WHEN delivery_status = 'Late' THEN 1 ELSE 0 END) as late_count
                FROM mart_operations
                WHERE operation_type = 'work_order' AND product_name IS NOT NULL
                GROUP BY product_name, category_name
                HAVING COUNT(DISTINCT operation_id) > 0
                ORDER BY total_work_orders DESC
                LIMIT 30
            """)
            production_data = pd.DataFrame(cur.fetchall(),
                                          columns=['Product', 'Category', 'Work Orders', 'Avg Days', 
                                                  'Avg Cost Variance %', 'Avg Scrap Rate %', 'On Time', 'Late'])
            
            if not production_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    fig = px.scatter(production_data, x='Avg Days', y='Avg Cost Variance %',
                                   size='Work Orders', color='Category',
                                   hover_data=['Product'],
                                   title='Production Efficiency: Days vs Cost Variance',
                                   labels={'Avg Days': 'Average Production Days', 'Avg Cost Variance %': 'Cost Variance (%)'})
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    delivery_data = production_data[['Product', 'On Time', 'Late']].head(10)
                    delivery_melted = pd.melt(delivery_data, id_vars=['Product'],
                                            value_vars=['On Time', 'Late'],
                                            var_name='Status', value_name='Count')
                    fig = px.bar(delivery_melted, x='Product', y='Count', color='Status',
                               title='On-Time vs Late Deliveries (Top 10 Products)',
                               labels={'Count': 'Number of Orders', 'Product': 'Product Name'})
                    fig.update_xaxes(tickangle=45)
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(production_data, use_container_width=True)
    
    with tab2:
        st.subheader("Vendor Performance Analysis")
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    vendor_name,
                    vendor_type,
                    COUNT(DISTINCT operation_id) as total_orders,
                    SUM(totaldue) as total_purchase_amount,
                    AVG(days_to_ship) as avg_delivery_days,
                    AVG(rejection_rate_percent) as avg_rejection_rate,
                    AVG(fulfillment_rate_percent) as avg_fulfillment_rate
                FROM mart_operations
                WHERE operation_type = 'purchase_order' AND vendor_name IS NOT NULL
                GROUP BY vendor_name, vendor_type
                ORDER BY total_purchase_amount DESC
            """)
            vendor_data = pd.DataFrame(cur.fetchall(),
                                     columns=['Vendor', 'Type', 'Orders', 'Total Amount', 
                                            'Avg Delivery Days', 'Avg Rejection %', 'Avg Fulfillment %'])
            
            if not vendor_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    fig = px.scatter(vendor_data, x='Avg Delivery Days', y='Avg Rejection %',
                                   size='Total Amount', color='Type',
                                   hover_data=['Vendor'],
                                   title='Vendor Performance: Delivery vs Quality',
                                   labels={'Avg Delivery Days': 'Average Delivery Days', 'Avg Rejection %': 'Rejection Rate (%)'})
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    top_vendors = vendor_data.head(15)
                    fig = px.bar(top_vendors, x='Vendor', y='Total Amount',
                               color='Type',
                               title='Top 15 Vendors by Purchase Amount',
                               labels={'Total Amount': 'Purchase Amount ($)', 'Vendor': 'Vendor Name'})
                    fig.update_xaxes(tickangle=45)
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(vendor_data, use_container_width=True)
    
    with tab3:
        st.subheader("Shipping & Logistics Analysis")
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    shipping_speed_category,
                    territory_name,
                    COUNT(DISTINCT salesorderid) as order_count,
                    AVG(days_to_ship) as avg_days_to_ship,
                    AVG(order_total) as avg_order_value
                FROM mart_sales
                WHERE shipping_speed_category IS NOT NULL
                GROUP BY shipping_speed_category, territory_name
                ORDER BY order_count DESC
            """)
            shipping_data = pd.DataFrame(cur.fetchall(),
                                       columns=['Speed Category', 'Territory', 'Orders', 'Avg Days', 'Avg Order Value'])
            
            if not shipping_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    speed_counts = shipping_data.groupby('Speed Category')['Orders'].sum().reset_index()
                    fig = px.pie(speed_counts, values='Orders', names='Speed Category',
                               title='Order Distribution by Shipping Speed')
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    territory_speed = shipping_data.pivot_table(
                        index='Territory',
                        columns='Speed Category',
                        values='Orders',
                        aggfunc='sum'
                    ).fillna(0)
                    fig = px.bar(territory_speed,
                               title='Shipping Speed by Territory',
                               labels={'value': 'Number of Orders', 'Territory': 'Territory'})
                    fig.update_xaxes(tickangle=45)
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(shipping_data, use_container_width=True)

