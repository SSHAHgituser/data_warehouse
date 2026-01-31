"""
SQL Generator
=============
Converts natural language questions to SQL queries using LLMs.
Supports OpenAI GPT-4 and Anthropic Claude models.
"""

import os
from typing import Optional, Tuple
from .schema_context import SchemaContext
from .sql_validator import SQLValidator


class SQLGenerator:
    """Generates SQL queries from natural language using LLMs."""
    
    def __init__(self, conn, provider: str = "openai"):
        """
        Initialize the SQL generator.
        
        Args:
            conn: Database connection for schema context
            provider: LLM provider ("openai" or "anthropic")
        """
        self.conn = conn
        self.provider = provider
        self.schema_context = SchemaContext(conn)
        self.validator = SQLValidator(strict_mode=True)
        self._client = None
        self._conversation_history = []
    
    def _get_client(self):
        """Lazy-load the LLM client."""
        if self._client is not None:
            return self._client
        
        if self.provider == "openai":
            try:
                from openai import OpenAI
                api_key = os.getenv("OPENAI_API_KEY")
                if not api_key:
                    raise ValueError("OPENAI_API_KEY environment variable not set")
                self._client = OpenAI(api_key=api_key)
            except ImportError:
                raise ImportError("openai package not installed. Run: pip install openai")
        
        elif self.provider == "anthropic":
            try:
                import anthropic
                api_key = os.getenv("ANTHROPIC_API_KEY")
                if not api_key:
                    raise ValueError("ANTHROPIC_API_KEY environment variable not set")
                self._client = anthropic.Anthropic(api_key=api_key)
            except ImportError:
                raise ImportError("anthropic package not installed. Run: pip install anthropic")
        
        else:
            raise ValueError(f"Unknown provider: {self.provider}")
        
        return self._client
    
    def generate(self, question: str, use_conversation: bool = True) -> Tuple[str, bool, Optional[str]]:
        """
        Generate SQL from a natural language question.
        
        Args:
            question: The natural language question
            use_conversation: Whether to use conversation history for context
            
        Returns:
            Tuple of (sql_query, is_valid, error_message)
        """
        try:
            client = self._get_client()
        except (ImportError, ValueError) as e:
            return "", False, str(e)
        
        # Build messages
        if use_conversation and self._conversation_history:
            # Use quick context for follow-ups
            system_prompt = self.schema_context.get_quick_context()
            messages = self._conversation_history.copy()
            messages[0] = {"role": "system", "content": system_prompt}
        else:
            # Use full context for first question
            system_prompt = self.schema_context.build_system_prompt()
            messages = [{"role": "system", "content": system_prompt}]
            self._conversation_history = messages.copy()
        
        # Add user question
        messages.append({"role": "user", "content": question})
        
        # Generate SQL based on provider
        try:
            if self.provider == "openai":
                sql = self._generate_openai(client, messages)
            else:
                sql = self._generate_anthropic(client, messages, system_prompt)
        except Exception as e:
            return "", False, f"LLM API error: {str(e)}"
        
        # Validate the generated SQL
        is_valid, cleaned_sql, error = self.validator.validate(sql)
        
        if is_valid:
            # Add to conversation history
            self._conversation_history.append({"role": "user", "content": question})
            self._conversation_history.append({"role": "assistant", "content": cleaned_sql})
            
            # Keep history manageable (last 10 exchanges)
            if len(self._conversation_history) > 22:  # system + 10 pairs
                self._conversation_history = [self._conversation_history[0]] + self._conversation_history[-20:]
        
        return cleaned_sql or sql, is_valid, error
    
    def _generate_openai(self, client, messages: list) -> str:
        """Generate SQL using OpenAI API."""
        response = client.chat.completions.create(
            model=os.getenv("OPENAI_MODEL", "gpt-4o"),
            messages=messages,
            temperature=0,  # Deterministic output for SQL
            max_tokens=1000
        )
        return response.choices[0].message.content.strip()
    
    def _generate_anthropic(self, client, messages: list, system_prompt: str) -> str:
        """Generate SQL using Anthropic API."""
        # Anthropic uses system prompt separately
        anthropic_messages = [
            {"role": msg["role"], "content": msg["content"]}
            for msg in messages
            if msg["role"] != "system"
        ]
        
        response = client.messages.create(
            model=os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-20250514"),
            max_tokens=1000,
            system=system_prompt,
            messages=anthropic_messages
        )
        return response.content[0].text.strip()
    
    def clear_conversation(self):
        """Clear the conversation history."""
        self._conversation_history = []
    
    def get_suggestions(self) -> list:
        """
        Get suggested questions based on available data.
        
        Returns:
            List of suggested question strings
        """
        return [
            "What is our total revenue by territory?",
            "Show me the top 10 customers by lifetime value",
            "What is the monthly revenue trend?",
            "Which products have the highest profit margin?",
            "Show me customers at risk of churning",
            "What is the average order value by customer segment?",
            "How many orders do we have by status?",
            "What is revenue by product category?",
            "Show me employee quota achievement rates",
            "What is our inventory value by category?"
        ]
