# AdventureWorks Sample Database

This directory contains the AdventureWorks sample database installation script for SQL Server. AdventureWorks is a Microsoft sample database that provides realistic business data for testing and development.

## Quick Installation

The easiest way to install AdventureWorks on SQL Server is using the automated script:

```bash
# From repository root
./adventureworks/install_adventureworks_sqlserver.sh

# Or from this directory
cd adventureworks
./install_adventureworks_sqlserver.sh
```

**Note:** The installation script is automatically run by `./start.sh` if the database doesn't exist.

The script will:
1. Check if SQL Server is running (start it if needed)
2. Download AdventureWorks2022 backup file (.bak)
3. Copy backup file into SQL Server container
4. Restore the database
5. Verify the installation

## Files

- **install_adventureworks_sqlserver.sh** - Automated installation script for SQL Server
- **README_SQLSERVER.md** - Detailed SQL Server installation documentation
- **README.md** - This file

## Resources

- [Microsoft SQL Server Samples](https://github.com/Microsoft/sql-server-samples)
- [AdventureWorks Documentation](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure)
- [SQL Server Docker Documentation](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-docker-container-configure)

For detailed installation instructions, troubleshooting, and connection examples, see [README_SQLSERVER.md](./README_SQLSERVER.md).
