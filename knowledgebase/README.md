# Knowledge Base - Ontology Extraction

This part of the data warehouse project connects our data with an ontology and stores it in Turtle (.ttl) format.

## Overview

The goal is to extract the database schema and relationships from the AdventureWorks data warehouse and represent them as an RDF/OWL ontology. This enables semantic querying, knowledge graph construction, and integration with other knowledge bases.

## Approach

### 1. Schema Extraction
- **Tables → Classes**: Each database table becomes an OWL class
- **Columns → Properties**: Each column becomes a datatype property
- **Primary Keys**: Used to identify unique instances
- **Data Types**: Mapped to appropriate XSD datatypes (xsd:string, xsd:integer, xsd:decimal, xsd:date, etc.)

### 2. Relationship Mapping
- **Foreign Keys → Object Properties**: Foreign key relationships become object properties linking classes
- **Constraints**: Unique constraints, check constraints, and other database constraints inform property cardinalities and restrictions
- **Hierarchies**: Table inheritance patterns (if any) are mapped to class hierarchies

### 3. Output Format
- **Turtle (.ttl)**: Human-readable RDF serialization format
- **Namespace**: Define appropriate namespaces for the ontology
- **Metadata**: Include ontology metadata (title, description, version, etc.)

## Source Schema Files

The ontology is extracted from dbt model schema YAML files:
- **`dbt/models/intermediate/_schema.yml`** - Used to create OWL classes (dimensions and facts)
- **`dbt/models/marts/_schema.yml`** - Used to enrich classes with additional properties and relationships

## Implementation

The ontology extraction uses a two-tier approach:

### Intermediate Models (Classes)
- **Source**: `dbt/models/intermediate/_schema.yml`
- **Purpose**: Defines the core OWL classes
- **Class Names**: User-friendly names (e.g., `Customer` instead of `dim_customer`, `SalesOrder` instead of `fact_sales_order`)
- **Properties**: All columns from intermediate models become datatype properties

### Mart Models (Enrichment)
- **Source**: `dbt/models/marts/_schema.yml`
- **Purpose**: Enriches classes with additional properties and relationships
- **Process**: Mart columns are mapped to intermediate classes and added as new properties (avoiding duplicates)

The extraction process:
1. Loads intermediate models to create OWL classes with user-friendly names
2. Creates datatype properties from intermediate model columns (with table names in URIs for traceability)
3. Enriches classes with additional properties from mart models
4. Generates object properties for foreign key relationships from intermediate models
5. Analyzes relationships indicated by mart models
6. Serializes to Turtle format

### Traceability to dbt Models

All properties and classes include source table information for easy traceability back to dbt models:
- **Property URIs**: Include table name (e.g., `prop:dim_customer_customerid` instead of `prop:Customer_customerid`)
- **Source Comments**: Each property includes a "Source table" comment
- **Class Comments**: Each class includes "Source dbt table" information
- **Relationship Comments**: Object properties include source table information

This allows you to easily map ontology elements back to their originating dbt models.

## Tools & Technologies

- **RDFLib** (Python): For RDF/OWL manipulation and Turtle serialization
- **PyYAML**: For parsing dbt schema YAML files
- **OWL**: Web Ontology Language for formal ontology representation

## Usage

### Quick Start

Run the extraction script:

```bash
cd knowledgebase
./run_extraction.sh
```

Or manually:

```bash
cd knowledgebase
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 extract_ontology.py
```

### Output

The script generates `adventureworks_ontology.ttl` containing:
- **17 OWL Classes** (one for each table)
- **106 Datatype Properties** (one for each column)
- **13 Object Properties** (one for each foreign key relationship)
- **659 Total RDF Triples**

### Scripts

- `extract_ontology.py`: Main script that extracts ontology from dbt model YAML files
- `run_extraction.sh`: Convenience script to set up environment and run the extraction

### Configuration

The script reads from dbt model YAML files. You can configure the path using the `DBT_MODELS_PATH` environment variable:

```bash
export DBT_MODELS_PATH="../dbt/models"
python3 extract_ontology.py
```

By default, it looks for schema files in:
- `intermediate/_schema.yml`
- `marts/_schema.yml`

## Generated Ontology Structure

The ontology includes user-friendly class names:

1. **Dimension Classes**: `Customer`, `Product`, `Date`, `Employee`, `Territory`, `Vendor`
2. **Fact Classes**: `SalesOrder`, `SalesOrderLine`, `Inventory`, `PurchaseOrder`, `WorkOrder`, `EmployeeQuota`
3. **Enriched Properties**: Additional properties from mart models (e.g., `rfm_segment`, `churn_risk` for `Customer`)
4. **Relationships**: Foreign key relationships mapped as OWL object properties (e.g., `SalesOrder -> Customer`, `SalesOrder -> Employee`)

### Class Name Mapping

| Table Name | Class Name |
|------------|------------|
| `dim_customer` | `Customer` |
| `dim_product` | `Product` |
| `dim_date` | `Date` |
| `dim_employee` | `Employee` |
| `dim_territory` | `Territory` |
| `dim_vendor` | `Vendor` |
| `fact_sales_order` | `SalesOrder` |
| `fact_sales_order_line` | `SalesOrderLine` |
| `fact_inventory` | `Inventory` |
| `fact_purchase_order` | `PurchaseOrder` |
| `fact_work_order` | `WorkOrder` |
| `fact_employee_quota` | `EmployeeQuota` |