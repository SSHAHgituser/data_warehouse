"""
Operations & Supply Chain Analytics Page
Supports: Vendor performance, Production efficiency, Shipping & logistics
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from pages.utils import format_dataframe

def render(conn):
    st.header("⚙️ Operations & Supply Chain Analytics")
    st.markdown("Analyze vendor performance, production efficiency, and supply chain operations")
    
    # Show report date note
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT MAX(order_date) FROM mart_sales")
            result = cur.fetchone()
            if result and result[0]:
                st.info(f"📅 **Report Date:** All analyses are based on data up to {result[0].strftime('%B %d, %Y')} (most recent sales transaction date).")
    except Exception:
        pass
    
    tab1, tab2, tab3 = st.tabs([
        "🏭 Production Efficiency",
        "🚚 Vendor Performance",
        "📦 Shipping & Logistics"
    ])
    
    with tab1:
        st.subheader("Production Efficiency Analysis")
        
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        product_name,
                        category_name,
                        COUNT(DISTINCT operation_id) as total_work_orders,
                        AVG(production_days) as avg_production_days,
                        AVG(cost_variance) as avg_cost_variance,
                        AVG(scrap_rate_percent) as avg_scrap_rate
                    FROM mart_operations
                    WHERE operation_type = 'work_order' AND product_name IS NOT NULL
                    GROUP BY product_name, category_name
                    HAVING COUNT(DISTINCT operation_id) > 0
                    ORDER BY total_work_orders DESC
                    LIMIT 30
                """)
                production_data = pd.DataFrame(cur.fetchall(),
                                              columns=['Product', 'Category', 'Work Orders', 'Avg Days', 
                                                      'Avg Cost Variance', 'Avg Scrap Rate %'])
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading production data: {e}")
            production_data = pd.DataFrame()
            
        if not production_data.empty:
            # Convert numeric columns and handle None/NaN values
            production_data['Work Orders'] = pd.to_numeric(production_data['Work Orders'], errors='coerce').fillna(1)
            production_data['Avg Days'] = pd.to_numeric(production_data['Avg Days'], errors='coerce')
            production_data['Avg Cost Variance'] = pd.to_numeric(production_data['Avg Cost Variance'], errors='coerce')
            production_data['Avg Scrap Rate %'] = pd.to_numeric(production_data['Avg Scrap Rate %'], errors='coerce')
            # Filter out rows with invalid values
            production_data = production_data[
                (production_data['Avg Days'].notna()) & 
                (production_data['Avg Cost Variance'].notna())
            ]
            
            if not production_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    # Handle Category column - fill NaN with 'Unknown'
                    plot_data = production_data.copy()
                    if 'Category' in plot_data.columns:
                        plot_data['Category'] = plot_data['Category'].fillna('Unknown')
                    fig = px.scatter(plot_data, x='Avg Days', y='Avg Cost Variance',
                                   size='Work Orders', color='Category',
                                   hover_data=['Product'],
                                   title='Production Efficiency: Days vs Cost Variance',
                                   labels={'Avg Days': 'Average Production Days', 'Avg Cost Variance': 'Cost Variance ($)'})
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    # Top 10 products by work orders
                    if 'Work Orders' in production_data.columns:
                        work_order_data = production_data.nlargest(10, 'Work Orders')[['Product', 'Work Orders', 'Category']].copy()
                        work_order_data['Work Orders'] = pd.to_numeric(work_order_data['Work Orders'], errors='coerce')
                        work_order_data = work_order_data[work_order_data['Work Orders'].notna()]
                        
                        if not work_order_data.empty:
                            fig = px.bar(work_order_data, x='Product', y='Work Orders',
                                       title='Top 10 Products by Work Orders',
                                       labels={'Work Orders': 'Number of Work Orders', 'Product': 'Product Name'},
                                       color='Category')
                            fig.update_xaxes(tickangle=45)
                            fig.update_layout(yaxis={'categoryorder': 'total descending'})
                            st.plotly_chart(fig, use_container_width=True)
                        else:
                            st.info("No work order data available")
                    else:
                        st.info("Work order data not available")
                
                st.dataframe(format_dataframe(production_data), use_container_width=True)
            else:
                st.info("No valid data available for visualization (missing required metrics)")
        else:
            # Diagnostic query to help understand why there's no data
            try:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT 
                            COUNT(*) as total_records,
                            COUNT(CASE WHEN operation_type = 'work_order' THEN 1 END) as work_order_records,
                            COUNT(CASE WHEN product_name IS NOT NULL THEN 1 END) as has_product_name,
                            COUNT(CASE WHEN production_days IS NOT NULL THEN 1 END) as has_production_days,
                            COUNT(CASE WHEN cost_variance IS NOT NULL THEN 1 END) as has_cost_variance,
                            COUNT(CASE WHEN scrap_rate_percent IS NOT NULL THEN 1 END) as has_scrap_rate
                        FROM mart_operations
                    """)
                    diag = cur.fetchone()
                    st.warning(f"**Data Availability:** Total records: {diag[0]}, Work orders: {diag[1]}, Has product_name: {diag[2]}, Has production_days: {diag[3]}, Has cost_variance: {diag[4]}, Has scrap_rate: {diag[5]}")
            except Exception as e:
                st.info(f"Unable to run diagnostic query: {e}")
    
    with tab2:
        st.subheader("Vendor Performance Analysis")
        
        try:
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
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading vendor data: {e}")
            vendor_data = pd.DataFrame()
            
        if not vendor_data.empty:
            # Convert numeric columns and handle None/NaN values
            vendor_data['Total Amount'] = pd.to_numeric(vendor_data['Total Amount'], errors='coerce').fillna(1)
            vendor_data['Avg Delivery Days'] = pd.to_numeric(vendor_data['Avg Delivery Days'], errors='coerce')
            vendor_data['Avg Rejection %'] = pd.to_numeric(vendor_data['Avg Rejection %'], errors='coerce')
            # Filter out rows with invalid values
            vendor_data = vendor_data[
                (vendor_data['Avg Delivery Days'].notna()) & 
                (vendor_data['Avg Rejection %'].notna())
            ]
            
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
                
                st.dataframe(format_dataframe(vendor_data), use_container_width=True)
            else:
                st.info("No valid data available for visualization")
    
    with tab3:
        st.subheader("Shipping & Logistics Analysis")
        
        try:
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
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading shipping data: {e}")
            shipping_data = pd.DataFrame()
        
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
            
            st.dataframe(format_dataframe(shipping_data), use_container_width=True)
        else:
            st.info("No shipping data available")

