"""
Advanced Analytics Page
Supports: Time series forecasting, Market basket analysis, Geographic analysis, Price elasticity
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta

def render(conn):
    st.header("🔮 Advanced Analytics")
    st.markdown("Advanced analytics including time series, market basket, geographic analysis, and price elasticity")
    
    tab1, tab2, tab3, tab4 = st.tabs([
        "📈 Time Series Forecasting",
        "🛒 Market Basket Analysis",
        "🌍 Geographic Analysis",
        "💰 Price Elasticity"
    ])
    
    with tab1:
        st.subheader("Time Series Forecasting")
        
        # Product selector
        with conn.cursor() as cur:
            cur.execute("SELECT DISTINCT product_name FROM mart_sales WHERE product_name IS NOT NULL ORDER BY product_name LIMIT 50")
            products = [row[0] for row in cur.fetchall()]
        
        selected_product = st.selectbox("Select Product for Forecasting", products)
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    order_date,
                    order_year,
                    order_month,
                    SUM(net_line_amount) as daily_revenue,
                    SUM(orderqty) as daily_quantity
                FROM mart_sales
                WHERE product_name = %s
                GROUP BY order_date, order_year, order_month
                ORDER BY order_date
            """, (selected_product,))
            ts_data = pd.DataFrame(cur.fetchall(),
                                  columns=['Date', 'Year', 'Month', 'Revenue', 'Quantity'])
            
            if not ts_data.empty:
                ts_data['Date'] = pd.to_datetime(ts_data['Date'])
                
                col1, col2 = st.columns(2)
                
                with col1:
                    fig = px.line(ts_data, x='Date', y='Revenue',
                                title=f'Revenue Trend for {selected_product}',
                                labels={'Revenue': 'Revenue ($)', 'Date': 'Date'})
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    fig = px.line(ts_data, x='Date', y='Quantity',
                                title=f'Quantity Sold Trend for {selected_product}',
                                labels={'Quantity': 'Quantity Sold', 'Date': 'Date'})
                    st.plotly_chart(fig, use_container_width=True)
                
                # Seasonal analysis
                st.subheader("Seasonal Analysis")
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT 
                            order_season,
                            SUM(net_line_amount) as seasonal_revenue,
                            SUM(orderqty) as seasonal_quantity
                        FROM mart_sales
                        WHERE product_name = %s
                        GROUP BY order_season
                        ORDER BY 
                            CASE order_season
                                WHEN 'Spring' THEN 1
                                WHEN 'Summer' THEN 2
                                WHEN 'Fall' THEN 3
                                WHEN 'Winter' THEN 4
                            END
                    """, (selected_product,))
                    seasonal_data = pd.DataFrame(cur.fetchall(),
                                               columns=['Season', 'Revenue', 'Quantity'])
                    
                    if not seasonal_data.empty:
                        fig = px.bar(seasonal_data, x='Season', y='Revenue',
                                    title=f'Seasonal Revenue for {selected_product}',
                                    labels={'Revenue': 'Revenue ($)', 'Season': 'Season'})
                        st.plotly_chart(fig, use_container_width=True)
    
    with tab2:
        st.subheader("Market Basket Analysis")
        
        st.markdown("### Frequently Bought Together Products")
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    p1.product_name as product,
                    p2.product_name as related_product,
                    COUNT(*) as co_occurrence_count,
                    SUM(s1.net_line_amount + s2.net_line_amount) as combined_revenue
                FROM mart_sales s1
                JOIN mart_sales s2 ON s1.salesorderid = s2.salesorderid 
                    AND s1.product_key != s2.product_key
                LEFT JOIN mart_product_analytics p1 ON s1.product_key = p1.productid
                LEFT JOIN mart_product_analytics p2 ON s2.product_key = p2.productid
                WHERE p1.product_name IS NOT NULL AND p2.product_name IS NOT NULL
                GROUP BY p1.product_name, p2.product_name
                ORDER BY co_occurrence_count DESC
                LIMIT 50
            """)
            basket_data = pd.DataFrame(cur.fetchall(),
                                     columns=['Product', 'Related Product', 'Co-occurrence', 'Combined Revenue'])
            
            if not basket_data.empty:
                # Top product pairs
                st.subheader("Top 20 Product Pairs")
                fig = px.bar(basket_data.head(20), x='Co-occurrence', y='Product',
                           orientation='h',
                           title='Top 20 Product Pairs by Co-occurrence',
                           labels={'Co-occurrence': 'Times Bought Together', 'Product': 'Product Pair'})
                fig.update_layout(yaxis={'categoryorder': 'total ascending'})
                st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(basket_data.head(20), use_container_width=True)
    
    with tab3:
        st.subheader("Geographic Analysis")
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    territory_name,
                    countryregioncode,
                    territory_group,
                    SUM(order_total) as total_revenue,
                    COUNT(DISTINCT salesorderid) as total_orders,
                    COUNT(DISTINCT customer_key) as total_customers,
                    AVG(order_total) as avg_order_value
                FROM mart_sales
                WHERE territory_name IS NOT NULL
                GROUP BY territory_name, countryregioncode, territory_group
                ORDER BY total_revenue DESC
            """)
            geo_data = pd.DataFrame(cur.fetchall(),
                                  columns=['Territory', 'Country', 'Region', 'Revenue', 'Orders', 'Customers', 'Avg Order'])
            
            if not geo_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    # Revenue by country
                    country_revenue = geo_data.groupby('Country')['Revenue'].sum().reset_index()
                    fig = px.bar(country_revenue, x='Country', y='Revenue',
                               title='Total Revenue by Country',
                               labels={'Revenue': 'Revenue ($)', 'Country': 'Country Code'})
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    # Revenue by region
                    region_revenue = geo_data.groupby('Region')['Revenue'].sum().reset_index()
                    fig = px.pie(region_revenue, values='Revenue', names='Region',
                               title='Revenue Distribution by Region')
                    st.plotly_chart(fig, use_container_width=True)
                
                # Territory performance map
                st.subheader("Territory Performance Matrix")
                fig = px.scatter(geo_data, x='Orders', y='Revenue',
                               size='Customers', color='Country',
                               hover_data=['Territory', 'Region'],
                               title='Territory Performance: Orders vs Revenue',
                               labels={'Orders': 'Number of Orders', 'Revenue': 'Revenue ($)'})
                st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(geo_data, use_container_width=True)
    
    with tab4:
        st.subheader("Price Elasticity Analysis")
        
        st.info("Price elasticity analysis shows how price changes affect sales volume")
        
        # Category selector
        with conn.cursor() as cur:
            cur.execute("SELECT DISTINCT category_name FROM mart_sales WHERE category_name IS NOT NULL ORDER BY category_name")
            categories = [row[0] for row in cur.fetchall()]
        
        selected_category = st.selectbox("Select Category", ["All"] + categories, key="price_cat")
        
        category_filter = f"AND category_name = '{selected_category}'" if selected_category != "All" else ""
        
        with conn.cursor() as cur:
            cur.execute(f"""
                SELECT 
                    product_name,
                    category_name,
                    AVG(unitprice) as avg_price,
                    AVG(CASE WHEN has_discount THEN unitprice ELSE NULL END) as avg_discounted_price,
                    SUM(CASE WHEN has_discount THEN orderqty ELSE 0 END) as discounted_quantity,
                    SUM(CASE WHEN NOT has_discount THEN orderqty ELSE 0 END) as regular_quantity,
                    AVG(unitpricediscount) as avg_discount_percent
                FROM mart_sales
                WHERE category_name IS NOT NULL {category_filter}
                GROUP BY product_name, category_name
                HAVING AVG(CASE WHEN has_discount THEN unitprice ELSE NULL END) IS NOT NULL
                ORDER BY avg_price DESC
                LIMIT 30
            """)
            price_data = pd.DataFrame(cur.fetchall(),
                                    columns=['Product', 'Category', 'Avg Price', 'Avg Discounted Price', 
                                           'Discounted Qty', 'Regular Qty', 'Avg Discount %'])
            
            if not price_data.empty:
                # Calculate price elasticity indicator
                price_data['Price Change %'] = ((price_data['Avg Discounted Price'] - price_data['Avg Price']) / price_data['Avg Price']) * 100
                price_data['Quantity Change %'] = ((price_data['Discounted Qty'] - price_data['Regular Qty']) / price_data['Regular Qty'].replace(0, 1)) * 100
                price_data['Elasticity Indicator'] = price_data['Quantity Change %'] / price_data['Price Change %'].replace(0, 1)
                
                col1, col2 = st.columns(2)
                
                with col1:
                    fig = px.scatter(price_data, x='Price Change %', y='Quantity Change %',
                                   size='Avg Price', color='Category',
                                   hover_data=['Product'],
                                   title='Price Elasticity: Price Change vs Quantity Change',
                                   labels={'Price Change %': 'Price Change (%)', 'Quantity Change %': 'Quantity Change (%)'})
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    # Top elastic products
                    elastic_products = price_data.nlargest(10, 'Elasticity Indicator')
                    fig = px.bar(elastic_products, x='Product', y='Elasticity Indicator',
                               title='Top 10 Most Price-Elastic Products',
                               labels={'Elasticity Indicator': 'Elasticity', 'Product': 'Product Name'})
                    fig.update_xaxes(tickangle=45)
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(price_data, use_container_width=True)

