"""
Advanced Analytics Page
Supports: Time series forecasting, Market basket analysis, Geographic analysis, Price elasticity
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
from pages.utils import format_dataframe
import folium
from streamlit_folium import st_folium

def render(conn):
    st.header("🔮 Advanced Analytics")
    st.markdown("Advanced analytics including time series, market basket, geographic analysis, and price elasticity")
    
    # Show report date note
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT MAX(order_date) FROM mart_sales")
            result = cur.fetchone()
            if result and result[0]:
                st.info(f"📅 **Report Date:** All analyses are based on data up to {result[0].strftime('%B %d, %Y')} (most recent sales transaction date).")
    except Exception:
        pass
    
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
                
                st.dataframe(format_dataframe(basket_data.head(20)), use_container_width=True)
    
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
                    # Revenue by country - Folium map
                    country_revenue = geo_data.groupby('Country')['Revenue'].sum().reset_index()
                    
                    # Convert Revenue to integer to avoid JSON serialization issues with Decimal
                    country_revenue['Revenue'] = pd.to_numeric(country_revenue['Revenue'], errors='coerce').fillna(0).astype(int)
                    
                    # Map ISO-2 country codes to full country names and coordinates
                    country_name_map = {
                        'US': 'United States',
                        'CA': 'Canada',
                        'GB': 'United Kingdom',
                        'DE': 'Germany',
                        'FR': 'France',
                        'AU': 'Australia',
                        'NZ': 'New Zealand'
                    }
                    # Approximate center coordinates for each country
                    country_coords = {
                        'US': [39.8283, -98.5795],
                        'CA': [56.1304, -106.3468],
                        'GB': [55.3781, -3.4360],
                        'DE': [51.1657, 10.4515],
                        'FR': [46.2276, 2.2137],
                        'AU': [-25.2744, 133.7751],
                        'NZ': [-40.9006, 174.8860]
                    }
                    
                    # Create a copy for mapping
                    country_revenue_map = country_revenue.copy()
                    country_revenue_map['Country Name'] = country_revenue_map['Country'].map(country_name_map).fillna(country_revenue_map['Country'])
                    country_revenue_map['Lat'] = country_revenue_map['Country'].map(lambda x: country_coords.get(x, [0, 0])[0])
                    country_revenue_map['Lon'] = country_revenue_map['Country'].map(lambda x: country_coords.get(x, [0, 0])[1])
                    
                    # Filter out countries without coordinates
                    country_revenue_map = country_revenue_map[(country_revenue_map['Lat'] != 0) | (country_revenue_map['Lon'] != 0)]
                    
                    if not country_revenue_map.empty:
                        # Create Folium map
                        try:
                            # Create base map centered on world with dark theme
                            m = folium.Map(location=[20, 0], zoom_start=2, tiles='CartoDB dark_matter')
                            
                            # Normalize revenue for color and size
                            max_revenue = int(country_revenue_map['Revenue'].max())
                            min_revenue = int(country_revenue_map['Revenue'].min())
                            revenue_range = max_revenue - min_revenue if max_revenue != min_revenue else 1
                            
                            # Add markers for each country
                            for idx, row in country_revenue_map.iterrows():
                                revenue_val = int(row['Revenue'])
                                
                                # Calculate color intensity for light blue to dark blue gradient
                                # Higher revenue = darker blue, lower revenue = lighter blue
                                intensity = (revenue_val - min_revenue) / revenue_range if revenue_range > 0 else 0
                                
                                # Light blue (low revenue): RGB(173, 216, 230) = #ADD8E6
                                # Dark blue (high revenue): RGB(0, 0, 139) = #00008B
                                red = int(173 - (173 * intensity))
                                green = int(216 - (216 * intensity))
                                blue = int(230 - (91 * intensity))  # 230 to 139
                                color = f'#{red:02x}{green:02x}{blue:02x}'
                                
                                # Calculate marker size based on revenue
                                size = max(10, min(50, 10 + (revenue_val / max_revenue) * 40))
                                
                                # Format revenue with currency and commas
                                revenue_formatted = f"${revenue_val:,}"
                                
                                # Create popup with formatted revenue (dark theme styling)
                                popup_html = f"""
                                <div style="font-family: Arial; font-size: 14px; color: #e0e0e0; background-color: #1e1e1e; padding: 10px; border-radius: 5px;">
                                    <b style="color: #ffffff;">{row['Country Name']}</b><br>
                                    <span style="color: #87CEEB;">Revenue: {revenue_formatted}</span>
                                </div>
                                """
                                
                                folium.CircleMarker(
                                    location=[row['Lat'], row['Lon']],
                                    radius=size,
                                    popup=folium.Popup(popup_html, max_width=250),
                                    tooltip=f"{row['Country Name']}: {revenue_formatted}",
                                    color='#ffffff',
                                    fillColor=color,
                                    fillOpacity=0.8,
                                    weight=2
                                ).add_to(m)
                            
                            # Add legend with dark theme styling
                            legend_html = f'''
                            <div style="position: fixed; 
                                        bottom: 50px; right: 50px; width: 220px; height: 140px; 
                                        background-color: #1e1e1e; border:2px solid #4169E1; z-index:9999; 
                                        font-size:14px; padding: 15px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.3);">
                            <h4 style="margin-top: 0; color: #ffffff; font-weight: bold;">Revenue Scale</h4>
                            <p style="margin: 8px 0; color: #e0e0e0;"><span style="color: #00008B;">●</span> High: <span style="color: #87CEEB; font-weight: bold;">${max_revenue:,}</span></p>
                            <p style="margin: 8px 0; color: #e0e0e0;"><span style="color: #ADD8E6;">●</span> Low: <span style="color: #87CEEB; font-weight: bold;">${min_revenue:,}</span></p>
                            </div>
                            '''
                            m.get_root().html.add_child(folium.Element(legend_html))
                            
                            # Display map
                            st_folium(m, width=700, height=500)
                        except Exception as e:
                            # Fallback to bar chart if map fails
                            st.warning(f"Map visualization unavailable, showing bar chart instead: {e}")
                            fig = px.bar(country_revenue_map, x='Country Name', y='Revenue',
                                       title='Total Revenue by Country',
                                       labels={'Revenue': 'Revenue ($)', 'Country Name': 'Country'})
                            fig.update_xaxes(tickangle=45)
                            st.plotly_chart(fig, use_container_width=True)
                    else:
                        st.info("No country revenue data available for map")
                
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
                
                st.dataframe(format_dataframe(geo_data), use_container_width=True)
    
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
                # Convert numeric columns and handle None/NaN values
                price_data['Avg Price'] = pd.to_numeric(price_data['Avg Price'], errors='coerce')
                price_data['Avg Discounted Price'] = pd.to_numeric(price_data['Avg Discounted Price'], errors='coerce')
                price_data['Discounted Qty'] = pd.to_numeric(price_data['Discounted Qty'], errors='coerce').fillna(0)
                price_data['Regular Qty'] = pd.to_numeric(price_data['Regular Qty'], errors='coerce').fillna(0)
                price_data['Avg Discount %'] = pd.to_numeric(price_data['Avg Discount %'], errors='coerce')
                
                # Calculate price elasticity indicator
                price_data['Price Change %'] = ((price_data['Avg Discounted Price'] - price_data['Avg Price']) / price_data['Avg Price'].replace(0, 1)) * 100
                price_data['Quantity Change %'] = ((price_data['Discounted Qty'] - price_data['Regular Qty']) / price_data['Regular Qty'].replace(0, 1)) * 100
                price_data['Elasticity Indicator'] = price_data['Quantity Change %'] / price_data['Price Change %'].replace(0, 1)
                
                # Filter out rows with invalid values for scatter plot
                scatter_data = price_data[
                    (price_data['Price Change %'].notna()) & 
                    (price_data['Quantity Change %'].notna()) &
                    (price_data['Avg Price'].notna())
                ]
                
                col1, col2 = st.columns(2)
                
                with col1:
                    if not scatter_data.empty:
                        # Fill NaN Category with 'Unknown'
                        scatter_data = scatter_data.copy()
                        if 'Category' in scatter_data.columns:
                            scatter_data['Category'] = scatter_data['Category'].fillna('Unknown')
                        fig = px.scatter(scatter_data, x='Price Change %', y='Quantity Change %',
                                       size='Avg Price', color='Category',
                                       hover_data=['Product'],
                                       title='Price Elasticity: Price Change vs Quantity Change',
                                       labels={'Price Change %': 'Price Change (%)', 'Quantity Change %': 'Quantity Change (%)'})
                        st.plotly_chart(fig, use_container_width=True)
                    else:
                        st.info("No valid data available for price elasticity scatter plot")
                
                with col2:
                    # Top elastic products (filter out invalid elasticity values)
                    elastic_data = price_data[
                        (price_data['Elasticity Indicator'].notna()) & 
                        (price_data['Elasticity Indicator'].abs() != float('inf'))
                    ]
                    if not elastic_data.empty:
                        elastic_products = elastic_data.nlargest(10, 'Elasticity Indicator')
                        if not elastic_products.empty:
                            fig = px.bar(elastic_products, x='Product', y='Elasticity Indicator',
                                       title='Top 10 Most Price-Elastic Products',
                                       labels={'Elasticity Indicator': 'Elasticity', 'Product': 'Product Name'})
                            fig.update_xaxes(tickangle=45)
                            st.plotly_chart(fig, use_container_width=True)
                        else:
                            st.info("No valid elasticity data available")
                    else:
                        st.info("No valid elasticity data available for analysis")
                
                st.dataframe(format_dataframe(price_data), use_container_width=True)

