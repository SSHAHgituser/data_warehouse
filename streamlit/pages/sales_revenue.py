"""
Sales & Revenue Analytics Page
Supports: CLV, Sales performance by territory, Product sales trends, Sales funnel, Customer segmentation
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from pages.utils import format_dataframe

def render(conn):
    st.header("💰 Sales & Revenue Analytics")
    st.markdown("Analyze sales performance, revenue trends, and customer value")
    
    # Show report date note
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT MAX(order_date) FROM mart_sales")
            result = cur.fetchone()
            if result and result[0]:
                st.info(f"📅 **Report Date:** All analyses are based on data up to {result[0].strftime('%B %d, %Y')} (most recent sales transaction date).")
    except Exception:
        pass
    
    # Tabs for different analyses
    tab1, tab2, tab3, tab4, tab5 = st.tabs([
        "📊 Overview",
        "🌍 Territory Performance",
        "📈 Product Sales Trends",
        "🎯 Customer Segmentation",
        "💎 Customer Lifetime Value"
    ])
    
    with tab1:
        st.subheader("Sales Overview")
        
        col1, col2, col3 = st.columns(3)
        
        with conn.cursor() as cur:
            # Total revenue
            cur.execute("""
                SELECT 
                    SUM(order_total) as total_revenue,
                    COUNT(DISTINCT salesorderid) as total_orders,
                    AVG(order_total) as avg_order_value
                FROM mart_sales
            """)
            overview = cur.fetchone()
            
            with col1:
                st.metric("Total Revenue", f"${overview[0]:,.2f}" if overview[0] else "$0")
            with col2:
                st.metric("Total Orders", f"{overview[1]:,}" if overview[1] else "0")
            with col3:
                st.metric("Avg Order Value", f"${overview[2]:,.2f}" if overview[2] else "$0")
        
        # Revenue by month
        st.subheader("Revenue Trend Over Time")
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    order_year,
                    order_month,
                    order_month_name,
                    SUM(order_total) as monthly_revenue,
                    COUNT(DISTINCT salesorderid) as monthly_orders
                FROM mart_sales
                GROUP BY order_year, order_month, order_month_name
                ORDER BY order_year, order_month
            """)
            revenue_trend = pd.DataFrame(cur.fetchall(), 
                                        columns=['Year', 'Month', 'Month Name', 'Revenue', 'Orders'])
            if not revenue_trend.empty:
                revenue_trend['Date'] = pd.to_datetime(revenue_trend[['Year', 'Month']].assign(Day=1))
                fig = px.line(revenue_trend, x='Date', y='Revenue',
                            title='Monthly Revenue Trend',
                            labels={'Revenue': 'Revenue ($)', 'Date': 'Month'})
                st.plotly_chart(fig, use_container_width=True)
    
    with tab2:
        st.subheader("Territory Performance Analysis")
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    territory_name,
                    countryregioncode,
                    SUM(order_total) as total_revenue,
                    COUNT(DISTINCT salesorderid) as total_orders,
                    COUNT(DISTINCT customer_key) as total_customers,
                    AVG(order_total) as avg_order_value
                FROM mart_sales
                WHERE territory_name IS NOT NULL
                GROUP BY territory_name, countryregioncode
                ORDER BY total_revenue DESC
            """)
            territory_data = pd.DataFrame(cur.fetchall(),
                                         columns=['Territory', 'Country', 'Revenue', 'Orders', 'Customers', 'Avg Order Value'])
            
            if not territory_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    fig = px.bar(territory_data, x='Territory', y='Revenue',
                                title='Revenue by Territory',
                                labels={'Revenue': 'Revenue ($)', 'Territory': 'Territory Name'})
                    fig.update_xaxes(tickangle=45)
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    fig = px.scatter(territory_data, x='Orders', y='Revenue',
                                   size='Customers', color='Country',
                                   hover_data=['Territory'],
                                   title='Territory Performance: Orders vs Revenue',
                                   labels={'Revenue': 'Revenue ($)', 'Orders': 'Number of Orders'})
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(format_dataframe(territory_data), use_container_width=True)
    
    with tab3:
        st.subheader("Product Sales Trends")
        
        # Category filter
        with conn.cursor() as cur:
            cur.execute("SELECT DISTINCT category_name FROM mart_sales WHERE category_name IS NOT NULL ORDER BY category_name")
            categories = [row[0] for row in cur.fetchall()]
        
        selected_category = st.selectbox("Select Category", ["All"] + categories)
        
        category_filter = f"AND category_name = '{selected_category}'" if selected_category != "All" else ""
        
        with conn.cursor() as cur:
            cur.execute(f"""
                SELECT 
                    category_name,
                    product_name,
                    SUM(net_line_amount) as total_revenue,
                    SUM(orderqty) as total_quantity,
                    COUNT(DISTINCT salesorderid) as order_count
                FROM mart_sales
                WHERE category_name IS NOT NULL {category_filter}
                GROUP BY category_name, product_name
                ORDER BY total_revenue DESC
                LIMIT 20
            """)
            product_data = pd.DataFrame(cur.fetchall(),
                                      columns=['Category', 'Product', 'Revenue', 'Quantity', 'Orders'])
            
            if not product_data.empty:
                fig = px.bar(product_data.head(10), x='Revenue', y='Product',
                           orientation='h',
                           title='Top 10 Products by Revenue',
                           labels={'Revenue': 'Revenue ($)', 'Product': 'Product Name'})
                fig.update_layout(yaxis={'categoryorder': 'total ascending'})
                st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(format_dataframe(product_data), use_container_width=True)
    
    with tab4:
        st.subheader("Customer Segmentation Analysis")
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    customer_segment,
                    customer_status,
                    COUNT(*) as customer_count,
                    AVG(lifetime_value) as avg_clv,
                    AVG(total_orders) as avg_orders
                FROM mart_customer_analytics
                WHERE customer_segment IS NOT NULL 
                    AND customer_status IS NOT NULL
                    AND customer_segment != ''
                    AND customer_status != ''
                GROUP BY customer_segment, customer_status
                ORDER BY customer_segment, customer_status
            """)
            segment_data = pd.DataFrame(cur.fetchall(),
                                      columns=['Segment', 'Status', 'Count', 'Avg CLV', 'Avg Orders'])
            
            if not segment_data.empty:
                # Additional filtering to ensure no empty strings or NaN values
                segment_data = segment_data[
                    (segment_data['Segment'].notna()) & 
                    (segment_data['Status'].notna()) &
                    (segment_data['Segment'] != '') & 
                    (segment_data['Status'] != '')
                ]
                
                col1, col2 = st.columns(2)
                
                with col1:
                    if not segment_data.empty:
                        fig = px.sunburst(segment_data, path=['Segment', 'Status'], values='Count',
                                        title='Customer Distribution by Segment and Status')
                        st.plotly_chart(fig, use_container_width=True)
                    else:
                        st.info("No valid data available for sunburst chart")
                
                with col2:
                    fig = px.bar(segment_data, x='Segment', y='Avg CLV', color='Status',
                               title='Average CLV by Segment and Status',
                               labels={'Avg CLV': 'Average CLV ($)', 'Segment': 'Customer Segment'})
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(format_dataframe(segment_data), use_container_width=True)
    
    with tab5:
        st.subheader("Customer Lifetime Value Analysis")
        
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        customer_segment,
                        COUNT(*) as customer_count,
                        AVG(lifetime_value) as avg_clv,
                        MIN(lifetime_value) as min_clv,
                        MAX(lifetime_value) as max_clv,
                        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lifetime_value) as median_clv
                    FROM mart_customer_analytics
                    WHERE lifetime_value IS NOT NULL
                    GROUP BY customer_segment
                    ORDER BY avg_clv DESC
                """)
                clv_data = pd.DataFrame(cur.fetchall(),
                                      columns=['Segment', 'Count', 'Avg CLV', 'Min CLV', 'Max CLV', 'Median CLV'])
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading CLV data: {e}")
            clv_data = pd.DataFrame()
        
        if not clv_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    fig = px.bar(clv_data, x='Segment', y='Avg CLV',
                               title='Average CLV by Segment',
                               labels={'Avg CLV': 'Average CLV ($)', 'Segment': 'Customer Segment'})
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    fig = go.Figure()
                    fig.add_trace(go.Box(y=clv_data['Avg CLV'], name='CLV Distribution',
                                        boxmean='sd'))
                    fig.update_layout(title='CLV Distribution', yaxis_title='CLV ($)')
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(format_dataframe(clv_data), use_container_width=True)
        else:
            # Diagnostic query to help understand why there's no data
            try:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT 
                            COUNT(*) as total_customers,
                            COUNT(CASE WHEN lifetime_value IS NOT NULL THEN 1 END) as has_lifetime_value,
                            COUNT(CASE WHEN customer_segment IS NOT NULL AND customer_segment != '' THEN 1 END) as has_segment
                        FROM mart_customer_analytics
                    """)
                    diag = cur.fetchone()
                    st.warning(f"**Data Availability:** Total customers: {diag[0]}, Has lifetime_value: {diag[1]}, Has segment: {diag[2]}")
            except Exception as e:
                st.info("Unable to run diagnostic query")
        
        # Top customers (show regardless of CLV data availability)
        st.subheader("Top 20 Customers by Lifetime Value")
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        customerid,
                        firstname || ' ' || lastname as customer_name,
                        lifetime_value,
                        total_orders,
                        customer_segment,
                        customer_status
                    FROM mart_customer_analytics
                    WHERE lifetime_value IS NOT NULL
                    ORDER BY lifetime_value DESC
                    LIMIT 20
                """)
                top_customers = pd.DataFrame(cur.fetchall(),
                                           columns=['Customer ID', 'Name', 'Lifetime Value', 'Orders', 'Segment', 'Status'])
                if not top_customers.empty:
                    st.dataframe(format_dataframe(top_customers), use_container_width=True)
                else:
                    st.info("No customer data available with lifetime value information")
                    # Additional diagnostic
                    try:
                        with conn.cursor() as cur:
                            cur.execute("""
                                SELECT 
                                    COUNT(*) as total_customers,
                                    COUNT(CASE WHEN lifetime_value IS NOT NULL THEN 1 END) as has_lifetime_value,
                                    COUNT(CASE WHEN firstname IS NOT NULL AND lastname IS NOT NULL THEN 1 END) as has_name
                                FROM mart_customer_analytics
                            """)
                            diag = cur.fetchone()
                            st.warning(f"**Diagnostic:** Total customers: {diag[0]}, Has lifetime_value: {diag[1]}, Has name: {diag[2]}")
                    except Exception:
                        pass
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading top customers: {e}")

