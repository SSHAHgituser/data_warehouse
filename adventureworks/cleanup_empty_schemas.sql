-- Cleanup script to remove empty schemas from AdventureWorks database
-- These schemas (hr, pe, pr, pu, sa) are created but never populated
-- The actual tables are in: humanresources, person, production, purchasing, sales

-- Drop empty schemas
DROP SCHEMA IF EXISTS hr CASCADE;
DROP SCHEMA IF EXISTS pe CASCADE;
DROP SCHEMA IF EXISTS pr CASCADE;
DROP SCHEMA IF EXISTS pu CASCADE;
DROP SCHEMA IF EXISTS sa CASCADE;

-- Verify remaining schemas
SELECT schemaname, COUNT(*) as table_count 
FROM pg_tables 
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
GROUP BY schemaname 
ORDER BY schemaname;

