"""
AI Analytics Assistant Page
===========================
Natural language interface for querying the data warehouse.
Converts questions to SQL and displays results with auto-generated visualizations.
"""

import streamlit as st
import pandas as pd
from datetime import datetime
import os
import sys

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pages.utils import format_dataframe

# Import AI modules
try:
    from ai import SQLGenerator, ResultVisualizer, SQLValidator
    AI_AVAILABLE = True
except ImportError as e:
    AI_AVAILABLE = False
    AI_IMPORT_ERROR = str(e)


def render(conn):
    """Render the AI Analytics Assistant page."""
    
    st.header("🤖 AI Analytics Assistant")
    st.markdown("Ask questions about your data in plain English. I'll translate them into SQL and show you the results.")
    
    # Check if AI modules are available
    if not AI_AVAILABLE:
        st.error(f"AI modules could not be loaded: {AI_IMPORT_ERROR}")
        st.info("Please ensure all AI dependencies are installed.")
        return
    
    # Check for API key
    api_key = os.getenv("OPENAI_API_KEY") or os.getenv("ANTHROPIC_API_KEY")
    provider = "openai" if os.getenv("OPENAI_API_KEY") else "anthropic"
    
    # Sidebar configuration
    with st.sidebar:
        st.markdown("---")
        st.subheader("🔧 AI Settings")
        
        # API Key input if not set
        if not api_key:
            st.warning("⚠️ No API key detected")
            api_provider = st.selectbox(
                "Select AI Provider",
                ["OpenAI (GPT-4)", "Anthropic (Claude)"],
                key="ai_provider"
            )
            
            api_key_input = st.text_input(
                "Enter API Key",
                type="password",
                help="Your API key will be stored in session state only",
                key="api_key_input"
            )
            
            if api_key_input:
                if "OpenAI" in api_provider:
                    os.environ["OPENAI_API_KEY"] = api_key_input
                    provider = "openai"
                else:
                    os.environ["ANTHROPIC_API_KEY"] = api_key_input
                    provider = "anthropic"
                st.success(f"✓ {api_provider.split()[0]} API key set")
                api_key = api_key_input
        else:
            provider_name = "OpenAI GPT-4" if provider == "openai" else "Anthropic Claude"
            st.success(f"✓ Using {provider_name}")
        
        # Clear conversation button
        if st.button("🗑️ Clear Conversation", key="clear_conv"):
            if 'messages' in st.session_state:
                st.session_state.messages = []
            if 'sql_generator' in st.session_state:
                st.session_state.sql_generator.clear_conversation()
            st.rerun()
    
    # Initialize session state
    if 'messages' not in st.session_state:
        st.session_state.messages = []
    
    if 'sql_generator' not in st.session_state and api_key:
        try:
            st.session_state.sql_generator = SQLGenerator(conn, provider=provider)
            st.session_state.visualizer = ResultVisualizer()
        except Exception as e:
            st.error(f"Failed to initialize AI: {e}")
            return
    
    # Show suggested questions for new users
    if not st.session_state.messages:
        st.markdown("### 💡 Try asking:")
        
        suggestions = [
            "What is our total revenue by territory?",
            "Show me the top 10 customers by lifetime value",
            "What is the monthly revenue trend?",
            "Which products have the highest profit margin?",
            "Show me customers at risk of churning"
        ]
        
        cols = st.columns(2)
        for i, suggestion in enumerate(suggestions):
            with cols[i % 2]:
                if st.button(f"📊 {suggestion}", key=f"suggest_{i}", use_container_width=True):
                    st.session_state.pending_question = suggestion
                    st.rerun()
        
        st.markdown("---")
    
    # Display chat history
    for message in st.session_state.messages:
        with st.chat_message(message["role"], avatar="🧑‍💼" if message["role"] == "user" else "🤖"):
            if message["role"] == "user":
                st.markdown(message["content"])
            else:
                # Assistant message contains SQL, results, and visualization
                if "error" in message:
                    st.error(message["error"])
                else:
                    # Show SQL in expander
                    if message.get("sql"):
                        with st.expander("🔍 View SQL Query", expanded=False):
                            st.code(message["sql"], language="sql")
                    
                    # Show results
                    if message.get("dataframe") is not None:
                        df = message["dataframe"]
                        
                        # Show visualization if available
                        if message.get("figure"):
                            st.plotly_chart(message["figure"], use_container_width=True)
                        
                        # Show metric cards for single-row results
                        if message.get("metric_cards"):
                            cols = st.columns(len(message["metric_cards"]))
                            for i, card in enumerate(message["metric_cards"]):
                                with cols[i]:
                                    st.metric(label=card["label"], value=card["value"])
                        
                        # Show data table
                        st.markdown(f"**Results:** {len(df):,} rows")
                        st.dataframe(
                            format_dataframe(df.head(100)), 
                            use_container_width=True,
                            hide_index=True
                        )
                        
                        # Download button
                        csv = df.to_csv(index=False)
                        st.download_button(
                            label="📥 Download CSV",
                            data=csv,
                            file_name=f"query_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                            mime="text/csv",
                            key=f"download_{message.get('timestamp', datetime.now().timestamp())}"
                        )
    
    # Check for pending question from suggestion buttons
    if hasattr(st.session_state, 'pending_question'):
        question = st.session_state.pending_question
        del st.session_state.pending_question
        process_question(conn, question)
    
    # Chat input
    if prompt := st.chat_input("Ask a question about your data...", key="chat_input"):
        if not api_key:
            st.error("Please enter an API key in the sidebar first.")
        else:
            process_question(conn, prompt)


def process_question(conn, question: str):
    """Process a user question and generate response."""
    
    # Add user message
    st.session_state.messages.append({
        "role": "user",
        "content": question
    })
    
    # Display user message
    with st.chat_message("user", avatar="🧑‍💼"):
        st.markdown(question)
    
    # Generate response
    with st.chat_message("assistant", avatar="🤖"):
        with st.spinner("🔄 Generating SQL..."):
            try:
                # Generate SQL
                sql_generator = st.session_state.sql_generator
                visualizer = st.session_state.visualizer
                
                sql, is_valid, error = sql_generator.generate(question)
                
                if not is_valid:
                    error_msg = f"❌ {error}" if error else "Could not generate a valid SQL query."
                    st.error(error_msg)
                    st.session_state.messages.append({
                        "role": "assistant",
                        "error": error_msg,
                        "timestamp": datetime.now().timestamp()
                    })
                    return
                
                # Show SQL
                with st.expander("🔍 View SQL Query", expanded=False):
                    st.code(sql, language="sql")
                
                # Execute query
                with st.spinner("⚡ Running query..."):
                    try:
                        df = pd.read_sql(sql, conn)
                    except Exception as e:
                        error_msg = f"❌ Query execution error: {str(e)}"
                        st.error(error_msg)
                        st.session_state.messages.append({
                            "role": "assistant",
                            "sql": sql,
                            "error": error_msg,
                            "timestamp": datetime.now().timestamp()
                        })
                        return
                
                # Generate visualization
                figure, chart_type = visualizer.analyze_and_visualize(df, question)
                metric_cards = visualizer.create_metric_cards(df) if len(df) == 1 else None
                
                # Display results
                if figure:
                    st.plotly_chart(figure, use_container_width=True)
                
                if metric_cards:
                    cols = st.columns(len(metric_cards))
                    for i, card in enumerate(metric_cards):
                        with cols[i]:
                            st.metric(label=card["label"], value=card["value"])
                
                # Show data table
                st.markdown(f"**Results:** {len(df):,} rows")
                st.dataframe(
                    format_dataframe(df.head(100)),
                    use_container_width=True,
                    hide_index=True
                )
                
                # Download button
                csv = df.to_csv(index=False)
                timestamp = datetime.now().timestamp()
                st.download_button(
                    label="📥 Download CSV",
                    data=csv,
                    file_name=f"query_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                    mime="text/csv",
                    key=f"download_{timestamp}"
                )
                
                # Store in session state
                st.session_state.messages.append({
                    "role": "assistant",
                    "sql": sql,
                    "dataframe": df,
                    "figure": figure,
                    "chart_type": chart_type,
                    "metric_cards": metric_cards,
                    "timestamp": timestamp
                })
                
            except Exception as e:
                error_msg = f"❌ Unexpected error: {str(e)}"
                st.error(error_msg)
                st.session_state.messages.append({
                    "role": "assistant",
                    "error": error_msg,
                    "timestamp": datetime.now().timestamp()
                })


def show_capabilities():
    """Show what the AI assistant can do."""
    st.markdown("""
    ### What I can help with:
    
    📈 **Sales Analysis**
    - Revenue trends, breakdowns by territory/product/customer
    - Order analysis, average order value, discounts
    
    👥 **Customer Insights**  
    - Customer segmentation, lifetime value
    - Churn risk, RFM analysis
    - Cohort analysis
    
    📦 **Product Analytics**
    - Product performance, profit margins
    - Inventory status, turnover
    - Market basket / co-purchase analysis
    
    👔 **Employee Performance**
    - Quota achievement, sales by rep
    - Territory performance
    
    ⚙️ **Operations**
    - Vendor performance
    - Work order analysis
    - Supply chain metrics
    """)
