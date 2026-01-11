#!/usr/bin/env python3
"""
Ontology Extraction Script
Extracts database schema from dbt model YAML files and converts it to RDF/OWL ontology in Turtle format.
- Uses intermediate models to create classes
- Uses marts to enrich properties and relationships
- Uses user-friendly class names
"""

import os
import sys
import yaml
from pathlib import Path
from rdflib import Graph, Namespace, URIRef, Literal
from rdflib.namespace import RDF, RDFS, OWL, XSD
from typing import Dict, Optional, Set
import re


# Configuration
DBT_MODELS_PATH = os.getenv("DBT_MODELS_PATH", "../dbt/models")
INTERMEDIATE_SCHEMA = "intermediate/_schema.yml"
MARTS_SCHEMA = "marts/_schema.yml"

# Namespaces
BASE_URI = "http://www.adventureworks.org/ontology#"
DW = Namespace(BASE_URI)
PROP = Namespace(BASE_URI + "property/")


def sanitize_name(name: str) -> str:
    """Convert database names to valid URI identifiers."""
    # Replace special characters and spaces with underscores
    name = re.sub(r'[^a-zA-Z0-9_]', '_', name)
    # Remove leading/trailing underscores
    name = name.strip('_')
    # Ensure it starts with a letter
    if name and name[0].isdigit():
        name = 'n' + name
    return name


def table_name_to_friendly_class_name(table_name: str) -> str:
    """Convert table name to user-friendly class name.
    
    Examples:
    - dim_customer -> Customer
    - fact_sales_order -> SalesOrder
    - dim_product -> Product
    """
    # Remove dim_ or fact_ prefix
    name = re.sub(r'^(dim_|fact_)', '', table_name)
    
    # Convert snake_case to PascalCase
    parts = name.split('_')
    friendly_name = ''.join(word.capitalize() for word in parts)
    
    return friendly_name


def infer_xsd_type(column_name: str, description: str = "") -> URIRef:
    """Infer XSD datatype from column name and description."""
    col_lower = column_name.lower()
    desc_lower = description.lower()
    
    # Check for common patterns
    if 'id' in col_lower or 'key' in col_lower:
        return XSD.integer
    elif 'date' in col_lower or 'time' in col_lower:
        if 'timestamp' in desc_lower:
            return XSD.dateTime
        elif 'date' in col_lower:
            return XSD.date
        else:
            return XSD.time
    elif 'percent' in col_lower or 'rate' in col_lower or 'margin' in col_lower:
        return XSD.decimal
    elif 'amount' in col_lower or 'value' in col_lower or 'cost' in col_lower or 'price' in col_lower or 'revenue' in col_lower or 'quota' in col_lower or 'due' in col_lower:
        return XSD.decimal
    elif 'qty' in col_lower or 'quantity' in col_lower or 'days' in col_lower or 'year' in col_lower or 'month' in col_lower or 'quarter' in col_lower:
        return XSD.integer
    elif 'status' in col_lower or 'segment' in col_lower or 'category' in col_lower or 'season' in col_lower:
        return XSD.string
    else:
        return XSD.string


def extract_foreign_key_from_description(description: str) -> Optional[str]:
    """Extract referenced table name from foreign key description."""
    # Pattern: "Foreign key to dim_xxx" or "Foreign key - Sales order identifier"
    match = re.search(r'foreign key to (\w+)', description.lower())
    if match:
        return match.group(1)
    return None


def map_mart_column_to_intermediate_class(column_name: str, intermediate_tables: Dict) -> Optional[str]:
    """Map a mart column to an intermediate class based on column name patterns.
    
    Returns the intermediate table name if a match is found.
    """
    col_lower = column_name.lower()
    
    # Mapping patterns based on column names
    mappings = {
        'customer': ['dim_customer'],
        'product': ['dim_product'],
        'employee': ['dim_employee'],
        'territory': ['dim_territory'],
        'vendor': ['dim_vendor'],
        'date': ['dim_date'],
        'sales_order': ['fact_sales_order', 'fact_sales_order_line'],
        'purchase_order': ['fact_purchase_order'],
        'work_order': ['fact_work_order'],
        'inventory': ['fact_inventory'],
        'quota': ['fact_employee_quota']
    }
    
    # Check each mapping pattern
    for pattern, table_candidates in mappings.items():
        if pattern in col_lower:
            # Return the first matching table that exists
            for table_name in table_candidates:
                if table_name in intermediate_tables:
                    return table_name
    
    # Fallback: direct table name matching
    for table_name in intermediate_tables.keys():
        table_lower = table_name.lower()
        # Extract base name (remove dim_/fact_ prefix)
        base_name = re.sub(r'^(dim_|fact_)', '', table_lower)
        if base_name in col_lower or col_lower in base_name:
            return table_name
    
    return None


def load_intermediate_models(base_path: str) -> Dict:
    """Load intermediate model schema (for classes)."""
    schema_info = {}
    file_path = Path(base_path) / INTERMEDIATE_SCHEMA
    
    if not file_path.exists():
        print(f"Warning: Intermediate schema file not found: {file_path}")
        return schema_info
    
    print(f"Loading intermediate models: {INTERMEDIATE_SCHEMA}")
    with open(file_path, 'r') as f:
        content = yaml.safe_load(f)
    
    if 'models' in content:
        for model in content['models']:
            table_name = model['name']
            description = model.get('description', '')
            columns = model.get('columns', [])
            
            schema_info[table_name] = {
                'description': description,
                'columns': columns,
                'friendly_name': table_name_to_friendly_class_name(table_name)
            }
            print(f"  Found table: {table_name} -> {schema_info[table_name]['friendly_name']} ({len(columns)} columns)")
    
    return schema_info


def load_mart_models(base_path: str) -> Dict:
    """Load mart model schema (for enrichment)."""
    schema_info = {}
    file_path = Path(base_path) / MARTS_SCHEMA
    
    if not file_path.exists():
        print(f"Warning: Marts schema file not found: {file_path}")
        return schema_info
    
    print(f"\nLoading mart models: {MARTS_SCHEMA}")
    with open(file_path, 'r') as f:
        content = yaml.safe_load(f)
    
    if 'models' in content:
        for model in content['models']:
            table_name = model['name']
            description = model.get('description', '')
            columns = model.get('columns', [])
            
            schema_info[table_name] = {
                'description': description,
                'columns': columns
            }
            print(f"  Found mart: {table_name} ({len(columns)} columns)")
    
    return schema_info


def create_ontology(intermediate_models: Dict, mart_models: Dict) -> Graph:
    """Create RDF/OWL ontology from intermediate models (classes) and enrich with marts."""
    g = Graph()
    
    # Bind namespaces
    g.bind("owl", OWL)
    g.bind("rdf", RDF)
    g.bind("rdfs", RDFS)
    g.bind("xsd", XSD)
    g.bind("dw", DW)
    g.bind("prop", PROP)
    
    # Ontology metadata
    ontology_uri = URIRef(BASE_URI)
    g.add((ontology_uri, RDF.type, OWL.Ontology))
    g.add((ontology_uri, RDFS.label, Literal("AdventureWorks Data Warehouse Ontology")))
    g.add((ontology_uri, RDFS.comment, Literal("Ontology extracted from AdventureWorks data warehouse schema")))
    
    # Create mapping from friendly names to table names
    friendly_to_table = {info['friendly_name']: table_name 
                         for table_name, info in intermediate_models.items()}
    
    # Step 1: Create OWL classes for intermediate models only
    print("\nCreating OWL classes from intermediate models...")
    for table_name, info in intermediate_models.items():
        friendly_name = info['friendly_name']
        class_uri = DW[sanitize_name(friendly_name)]
        g.add((class_uri, RDF.type, OWL.Class))
        g.add((class_uri, RDFS.label, Literal(friendly_name)))
        if info.get('description'):
            g.add((class_uri, RDFS.comment, Literal(info['description'])))
        # Add source table information for traceability to dbt models
        g.add((class_uri, RDFS.comment, Literal(f"Source dbt table: {table_name}")))
        print(f"  Created class: {friendly_name} (from {table_name})")
    
    # Step 2: Create datatype properties from intermediate models
    print("\nCreating datatype properties from intermediate models...")
    for table_name, info in intermediate_models.items():
        friendly_name = info['friendly_name']
        table_class = DW[sanitize_name(friendly_name)]
        
        for column in info['columns']:
            col_name = column['name']
            col_desc = column.get('description', '')
            
            # Check if it's a primary key
            is_pk = 'primary key' in col_desc.lower()
            
            # Create datatype property with table name included for traceability
            # Property URI: table_name_column_name (e.g., dim_customer_customerid)
            prop_uri = PROP[sanitize_name(f"{table_name}_{col_name}")]
            g.add((prop_uri, RDF.type, OWL.DatatypeProperty))
            g.add((prop_uri, RDFS.label, Literal(col_name)))
            g.add((prop_uri, RDFS.domain, table_class))
            
            # Infer XSD type
            xsd_type = infer_xsd_type(col_name, col_desc)
            g.add((prop_uri, RDFS.range, xsd_type))
            
            # Add description as comment
            if col_desc:
                g.add((prop_uri, RDFS.comment, Literal(col_desc)))
            
            # Add source table information for traceability
            g.add((prop_uri, RDFS.comment, Literal(f"Source table: {table_name}")))
            
            # Mark primary key properties
            if is_pk:
                g.add((prop_uri, RDFS.comment, Literal("Primary key property")))
            
            print(f"  Created property: {friendly_name}.{col_name} (from {table_name}) ({xsd_type})")
    
    # Step 3: Enrich with properties from marts
    print("\nEnriching with properties from mart models...")
    # Track existing properties from intermediate models (by table_name_column_name)
    existing_properties = set()
    for table_name, info in intermediate_models.items():
        for column in info['columns']:
            prop_key = f"{table_name}_{column['name']}"
            existing_properties.add(prop_key.lower())
    
    enriched_count = 0
    for mart_name, mart_info in mart_models.items():
        for column in mart_info['columns']:
            col_name = column['name']
            col_desc = column.get('description', '')
            
            # Try to map this column to an intermediate class
            target_table = map_mart_column_to_intermediate_class(col_name, intermediate_models)
            
            if target_table:
                target_friendly = intermediate_models[target_table]['friendly_name']
                target_class = DW[sanitize_name(target_friendly)]
                
                # Check if property already exists in intermediate model
                # Use table_name_column_name format for consistency
                prop_key = f"{target_table}_{col_name}"
                if prop_key.lower() not in existing_properties:
                    existing_properties.add(prop_key.lower())
                    
                    # Property URI includes table name for traceability
                    prop_uri = PROP[sanitize_name(prop_key)]
                    g.add((prop_uri, RDF.type, OWL.DatatypeProperty))
                    g.add((prop_uri, RDFS.label, Literal(col_name)))
                    g.add((prop_uri, RDFS.domain, target_class))
                    
                    xsd_type = infer_xsd_type(col_name, col_desc)
                    g.add((prop_uri, RDFS.range, xsd_type))
                    
                    if col_desc:
                        g.add((prop_uri, RDFS.comment, Literal(f"{col_desc} (enriched from {mart_name})")))
                    
                    # Add source information for traceability
                    g.add((prop_uri, RDFS.comment, Literal(f"Source table: {target_table}, enriched from: {mart_name}")))
                    
                    print(f"  Enriched property: {target_friendly}.{col_name} (from {target_table}, enriched via {mart_name})")
                    enriched_count += 1
                else:
                    # Property exists, but we can enhance the description if it's more detailed
                    pass
    
    if enriched_count == 0:
        print("  No new properties to enrich from marts")
    
    # Step 4: Create object properties for foreign key relationships
    print("\nCreating object properties for relationships...")
    for table_name, info in intermediate_models.items():
        friendly_name = info['friendly_name']
        table_class = DW[sanitize_name(friendly_name)]
        
        for column in info['columns']:
            col_name = column['name']
            col_desc = column.get('description', '')
            
            # Check if it's a foreign key
            ref_table = extract_foreign_key_from_description(col_desc)
            if ref_table and ref_table in intermediate_models:
                ref_friendly = intermediate_models[ref_table]['friendly_name']
                ref_class = DW[sanitize_name(ref_friendly)]
                
                # Create object property with table names included for traceability
                # Property URI: table_name_has_ref_table_name (e.g., fact_sales_order_has_dim_customer)
                prop_name = f"{table_name}_has_{ref_table}"
                prop_uri = PROP[sanitize_name(prop_name)]
                
                g.add((prop_uri, RDF.type, OWL.ObjectProperty))
                g.add((prop_uri, RDFS.label, Literal(f"{friendly_name} -> {ref_friendly}")))
                g.add((prop_uri, RDFS.domain, table_class))
                g.add((prop_uri, RDFS.range, ref_class))
                g.add((prop_uri, RDFS.comment, Literal(f"Relationship: {friendly_name}.{col_name} -> {ref_friendly}")))
                g.add((prop_uri, RDFS.comment, Literal(f"Source: {table_name} -> {ref_table}")))
                
                print(f"  Created relationship: {friendly_name} -> {ref_friendly} (from {table_name} -> {ref_table} via {col_name})")
    
    # Step 5: Extract additional relationships from marts (if columns reference multiple classes)
    print("\nAnalyzing relationships from mart models...")
    for mart_name, mart_info in mart_models.items():
        # Find columns that reference different intermediate classes
        referenced_classes = {}
        for column in mart_info['columns']:
            col_name = column['name']
            target_table = map_mart_column_to_intermediate_class(col_name, intermediate_models)
            if target_table:
                if target_table not in referenced_classes:
                    referenced_classes[target_table] = []
                referenced_classes[target_table].append(col_name)
        
        # If a mart references multiple classes, it might indicate a relationship
        if len(referenced_classes) > 1:
            class_list = [intermediate_models[t]['friendly_name'] for t in referenced_classes.keys()]
            print(f"  Mart {mart_name} links: {', '.join(class_list)}")
    
    return g


def main():
    """Main execution function."""
    print("=" * 60)
    print("AdventureWorks Data Warehouse - Ontology Extraction")
    print("From dbt Model YAML Files")
    print("=" * 60)
    
    # Determine base path
    script_dir = Path(__file__).parent
    dbt_path = script_dir / DBT_MODELS_PATH
    
    if not dbt_path.exists():
        print(f"Error: dbt models path not found: {dbt_path}")
        print(f"Please set DBT_MODELS_PATH environment variable or ensure path exists.")
        sys.exit(1)
    
    # Load intermediate models (for classes)
    intermediate_models = load_intermediate_models(dbt_path)
    
    if not intermediate_models:
        print("No intermediate models found. Exiting.")
        sys.exit(1)
    
    # Load mart models (for enrichment)
    mart_models = load_mart_models(dbt_path)
    
    # Create ontology
    print("\n" + "=" * 60)
    print("Generating OWL Ontology")
    print("=" * 60)
    g = create_ontology(intermediate_models, mart_models)
    
    # Serialize to Turtle format
    output_file = "adventureworks_ontology.ttl"
    print(f"\nSerializing ontology to {output_file}...")
    
    try:
        g.serialize(destination=output_file, format="turtle", encoding="utf-8")
        print(f"✓ Successfully created ontology file: {output_file}")
        print(f"  Total triples: {len(g)}")
        print(f"  Classes: {len([s for s, p, o in g.triples((None, RDF.type, OWL.Class))])}")
        print(f"  Datatype properties: {len([s for s, p, o in g.triples((None, RDF.type, OWL.DatatypeProperty))])}")
        print(f"  Object properties: {len([s for s, p, o in g.triples((None, RDF.type, OWL.ObjectProperty))])}")
    except Exception as e:
        print(f"Error serializing ontology: {e}")
        sys.exit(1)
    
    print("\n" + "=" * 60)
    print("Ontology extraction completed successfully!")
    print("=" * 60)


if __name__ == "__main__":
    main()
