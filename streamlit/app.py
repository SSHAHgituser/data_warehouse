"""
Simple Standard Streamlit Dashboard
A basic dashboard template with common Streamlit components
"""

import streamlit as st
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# Page configuration
st.set_page_config(
    page_title="Data Warehouse Dashboard",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Title
st.title("📊 Data Warehouse Dashboard")
st.markdown("---")

# Sidebar
with st.sidebar:
    st.header("⚙️ Configuration")
    
    # Date range selector
    st.subheader("Date Range")
    start_date = st.date_input(
        "Start Date",
        value=datetime.now() - timedelta(days=30),
        key="start_date"
    )
    end_date = st.date_input(
        "End Date",
        value=datetime.now(),
        key="end_date"
    )
    
    # Filter options
    st.subheader("Filters")
    filter_option = st.selectbox(
        "Select Filter",
        ["All", "Option 1", "Option 2", "Option 3"]
    )
    
    # Refresh button
    if st.button("🔄 Refresh Data"):
        st.rerun()

# Main content area
col1, col2, col3, col4 = st.columns(4)

# Key metrics cards
with col1:
    st.metric(
        label="Total Records",
        value="1,234",
        delta="12.5%"
    )

with col2:
    st.metric(
        label="Active Users",
        value="567",
        delta="-3.2%"
    )

with col3:
    st.metric(
        label="Revenue",
        value="$45,678",
        delta="8.1%"
    )

with col4:
    st.metric(
        label="Conversion Rate",
        value="3.2%",
        delta="0.5%"
    )

st.markdown("---")

# Charts section
col1, col2 = st.columns(2)

with col1:
    st.subheader("📈 Sample Line Chart")
    # Generate sample data
    chart_data = pd.DataFrame(
        np.random.randn(20, 3),
        columns=['Series A', 'Series B', 'Series C']
    )
    st.line_chart(chart_data)

with col2:
    st.subheader("📊 Sample Bar Chart")
    bar_data = pd.DataFrame(
        {
            'Category': ['A', 'B', 'C', 'D', 'E'],
            'Values': np.random.randint(10, 100, 5)
        }
    )
    st.bar_chart(bar_data.set_index('Category'))

st.markdown("---")

# Data table section
st.subheader("📋 Sample Data Table")
# Generate sample dataframe
df = pd.DataFrame({
    'ID': range(1, 21),
    'Name': [f'Item {i}' for i in range(1, 21)],
    'Value': np.random.randint(100, 1000, 20),
    'Status': np.random.choice(['Active', 'Inactive', 'Pending'], 20),
    'Date': pd.date_range(start=start_date, periods=20, freq='D')
})

st.dataframe(df, width="wide")

# Download button
csv = df.to_csv(index=False)
st.download_button(
    label="📥 Download CSV",
    data=csv,
    file_name=f"data_export_{datetime.now().strftime('%Y%m%d')}.csv",
    mime="text/csv"
)

st.markdown("---")

# Footer
st.markdown("---")
st.caption(f"Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

