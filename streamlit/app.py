"""
AdventureWorks Analytics Dashboard
Multi-page Streamlit application for comprehensive business analytics
"""

import streamlit as st
import pandas as pd
import psycopg2
from datetime import datetime
import plotly.express as px
import plotly.graph_objects as go

# Page configuration
st.set_page_config(
    page_title="AdventureWorks Analytics",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Database connection function
@st.cache_resource
def get_db_connection():
    """Create and return a database connection"""
    import os
    
    # Use environment variable or default to localhost for local development
    # In Docker, this will be set to "postgres" via docker-compose
    db_host = os.getenv("DB_HOST", "localhost")
    db_name = os.getenv("DB_NAME", "data_warehouse")
    db_user = os.getenv("DB_USER", "postgres")
    db_password = os.getenv("DB_PASSWORD", "postgres")
    db_port = os.getenv("DB_PORT", "5432")
    
    try:
        conn = psycopg2.connect(
            host=db_host,
            database=db_name,
            user=db_user,
            password=db_password,
            port=int(db_port),
            options="-c search_path=dbt,public"
        )
        return conn
    except Exception as e:
        st.error(f"Database connection error: {e}")
        st.info(f"Attempted to connect to: {db_host}:{db_port}/{db_name}")
        st.info("💡 Tip: If running locally, ensure PostgreSQL is running and accessible on localhost:5432")
        return None

# Custom CSS
st.markdown("""
    <style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
        margin-bottom: 1rem;
    }
    .metric-card {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #1f77b4;
    }
    </style>
""", unsafe_allow_html=True)

# Main page
st.markdown('<h1 class="main-header">📊 AdventureWorks Analytics Dashboard</h1>', unsafe_allow_html=True)
st.markdown("---")

# Sidebar navigation
st.sidebar.title("📑 Navigation")
st.sidebar.markdown("### Analytics Pages")

# Page selection
page = st.sidebar.radio(
    "Select Analytics Category",
    [
        "🏠 Overview",
        "💰 Sales & Revenue",
        "📦 Product & Inventory",
        "👥 Customer Analytics",
        "👔 HR & Employee Performance",
        "⚙️ Operations & Supply Chain",
        "🔮 Advanced Analytics"
    ],
    index=0
)

# Database connection
conn = get_db_connection()

if conn is None:
    st.error("⚠️ Unable to connect to database. Please ensure PostgreSQL is running.")
    st.stop()

# Overview Page
if page == "🏠 Overview":
    st.header("📊 Dashboard Overview")
    st.markdown("Welcome to the AdventureWorks Analytics Dashboard. Select an analytics category from the sidebar to explore insights.")
    
    col1, col2, col3, col4 = st.columns(4)
    
    # Key metrics from mart_sales
    try:
        with conn.cursor() as cur:
            # Total Revenue
            cur.execute("""
                SELECT 
                    COUNT(DISTINCT salesorderid) as total_orders,
                    SUM(order_total) as total_revenue,
                    COUNT(DISTINCT customer_key) as total_customers,
                    COUNT(DISTINCT product_key) as total_products
                FROM mart_sales
            """)
            metrics = cur.fetchone()
            
            with col1:
                st.metric(
                    label="Total Orders",
                    value=f"{metrics[0]:,}" if metrics[0] else "0",
                )
            
            with col2:
                st.metric(
                    label="Total Revenue",
                    value=f"${metrics[1]:,.2f}" if metrics[1] else "$0",
                )
            
            with col3:
                st.metric(
                    label="Total Customers",
                    value=f"{metrics[2]:,}" if metrics[2] else "0",
                )
            
            with col4:
                st.metric(
                    label="Total Products",
                    value=f"{metrics[3]:,}" if metrics[3] else "0",
                )
    except Exception as e:
        st.error(f"Error loading metrics: {e}")
    
    st.markdown("---")
    
    # Quick insights
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📈 Revenue Trend (Last 12 Months)")
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        order_year,
                        order_month,
                        SUM(order_total) as monthly_revenue
                    FROM mart_sales
                    WHERE order_date >= CURRENT_DATE - INTERVAL '12 months'
                    GROUP BY order_year, order_month
                    ORDER BY order_year, order_month
                """)
                revenue_data = pd.DataFrame(cur.fetchall(), columns=['Year', 'Month', 'Revenue'])
                if not revenue_data.empty:
                    revenue_data['Date'] = pd.to_datetime(revenue_data[['Year', 'Month']].assign(Day=1))
                    fig = px.line(revenue_data, x='Date', y='Revenue', 
                                 title='Monthly Revenue Trend',
                                 labels={'Revenue': 'Revenue ($)', 'Date': 'Month'})
                    st.plotly_chart(fig, use_container_width=True)
                else:
                    st.info("No data available for the selected period")
        except Exception as e:
            st.error(f"Error loading revenue trend: {e}")
    
    with col2:
        st.subheader("🏆 Top 5 Products by Revenue")
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        product_name,
                        SUM(net_line_amount) as total_revenue
                    FROM mart_sales
                    GROUP BY product_name
                    ORDER BY total_revenue DESC
                    LIMIT 5
                """)
                top_products = pd.DataFrame(cur.fetchall(), columns=['Product', 'Revenue'])
                if not top_products.empty:
                    fig = px.bar(top_products, x='Revenue', y='Product', 
                                orientation='h',
                                title='Top Products by Revenue',
                                labels={'Revenue': 'Revenue ($)', 'Product': 'Product Name'})
                    fig.update_layout(yaxis={'categoryorder': 'total ascending'})
                    st.plotly_chart(fig, use_container_width=True)
                else:
                    st.info("No data available")
        except Exception as e:
            st.error(f"Error loading top products: {e}")

# Import and route to other pages
elif page == "💰 Sales & Revenue":
    from pages import sales_revenue
    sales_revenue.render(conn)
elif page == "📦 Product & Inventory":
    from pages import product_inventory
    product_inventory.render(conn)
elif page == "👥 Customer Analytics":
    from pages import customer_analytics
    customer_analytics.render(conn)
elif page == "👔 HR & Employee Performance":
    from pages import hr_analytics
    hr_analytics.render(conn)
elif page == "⚙️ Operations & Supply Chain":
    from pages import operations
    operations.render(conn)
elif page == "🔮 Advanced Analytics":
    from pages import advanced_analytics
    advanced_analytics.render(conn)

# Footer
st.markdown("---")
st.caption(f"Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | AdventureWorks Sample Database")
