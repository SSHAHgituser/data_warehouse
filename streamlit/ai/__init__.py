"""
AI Module for AdventureWorks Analytics
======================================
Natural Language to SQL analytics assistant powered by LLMs.

Components:
- schema_context: Loads semantic context from dim_metric and schema definitions
- sql_generator: Converts natural language questions to SQL queries
- sql_validator: Validates and sanitizes generated SQL for safety
- visualizer: Auto-generates appropriate visualizations for query results
"""

from .schema_context import SchemaContext
from .sql_generator import SQLGenerator
from .sql_validator import SQLValidator
from .visualizer import ResultVisualizer

__all__ = [
    'SchemaContext',
    'SQLGenerator', 
    'SQLValidator',
    'ResultVisualizer'
]
