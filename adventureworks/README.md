# AdventureWorks Sample Database

This folder contains all AdventureWorks-related files and documentation.

## Files

- **ADVENTUREWORKS_INSTALL.md** - Complete installation guide for the AdventureWorks sample database
- **cleanup_empty_schemas.sql** - SQL script to remove empty schemas created during installation

## Installation

To install AdventureWorks, run the installation script from the repository root:

```bash
./install_adventureworks.sh
```

The installation script will automatically use the cleanup script in this folder.

## Manual Cleanup

If you need to manually clean up empty schemas after installation:

```bash
docker exec -i data_warehouse_postgres psql -U postgres -d Adventureworks < adventureworks/cleanup_empty_schemas.sql
```

## Documentation

See [ADVENTUREWORKS_INSTALL.md](./ADVENTUREWORKS_INSTALL.md) for detailed installation instructions and troubleshooting.

