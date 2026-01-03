"""
Utility functions for Streamlit pages
"""

import pandas as pd

def format_dataframe(df):
    """Format dataframe numbers for easy reading: currency with $, numbers with comma separator, 0 decimals"""
    if df.empty:
        return df
    
    df_formatted = df.copy()
    
    # Currency-related column patterns - check for pay rate FIRST to avoid conflicts
    currency_patterns = ['revenue', 'price', 'cost', 'value', 'clv', 'amount', 'total', 'profit', 
                        'pay', 'pay rate', 'sales', 'purchase', 'inventory_value', 'lifetime_value', 
                        'order_total', 'line_amount', 'subtotal', 'taxamt', 'freight', 'totaldue']
    
    # Percentage columns - check AFTER currency to avoid conflicts with pay rate
    # Columns with % in name or percentage-related terms (but not pay rate)
    percent_patterns = ['percent', 'percentage', '%', 'achievement', 'quota %', 'quota%', 
                       'scrap rate', 'rejection rate', 'fulfillment rate', 'discount', 
                       'elasticity', 'change %', 'turnover ratio']
    
    # Count/quantity columns
    count_patterns = ['count', 'quantity', 'orders', 'qty', 'number', 'days', 'hours', 'years']
    
    for col in df_formatted.columns:
        # Skip non-numeric columns
        if df_formatted[col].dtype not in ['int64', 'float64', 'Int64', 'Float64']:
            # Try to convert to numeric if possible
            numeric_series = pd.to_numeric(df_formatted[col], errors='coerce')
            if numeric_series.notna().any():
                df_formatted[col] = numeric_series
            else:
                continue
        
        col_lower = col.lower()
        
        # Columns with % symbol should ALWAYS be percentage (highest priority)
        has_percent_symbol = '%' in col
        
        # Check if it's a currency column (but not if it has % symbol)
        is_currency = not has_percent_symbol and any(pattern in col_lower for pattern in currency_patterns)
        # Check if it's a percentage column (if it has % symbol OR matches percentage patterns and not currency)
        is_percent = has_percent_symbol or (not is_currency and any(pattern in col_lower for pattern in percent_patterns))
        # Check if it's a count/quantity column
        is_count = any(pattern in col_lower for pattern in count_patterns)
        
        if is_percent:
            # Format as percentage: X,XXX% (if not already formatted)
            # Check if values are already strings with %
            sample_val = df_formatted[col].iloc[0] if not df_formatted[col].empty else None
            if sample_val is None or (isinstance(sample_val, (int, float)) and not pd.isna(sample_val)):
                df_formatted[col] = df_formatted[col].apply(
                    lambda x: f"{x:,.0f}%" if pd.notna(x) and not pd.isnull(x) else ""
                )
        elif is_currency:
            # Format as currency: $X,XXX
            df_formatted[col] = df_formatted[col].apply(
                lambda x: f"${x:,.0f}" if pd.notna(x) and not pd.isnull(x) else ""
            )
        elif is_count or df_formatted[col].dtype in ['int64', 'Int64']:
            # Format as integer with comma: X,XXX
            df_formatted[col] = df_formatted[col].apply(
                lambda x: f"{x:,.0f}" if pd.notna(x) and not pd.isnull(x) else ""
            )
        else:
            # Format other numeric columns as integer with comma: X,XXX
            df_formatted[col] = df_formatted[col].apply(
                lambda x: f"{x:,.0f}" if pd.notna(x) and not pd.isnull(x) else ""
            )
    
    return df_formatted

