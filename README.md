# Oracle Travel Agency Database Project

## Overview
This project provides a complete Oracle XE 21c database setup for a travel agency management system.  
It automates the creation of all schema objects, loads data from CSV files, and initializes the environment using Docker.

The goal is to deliver a ready-to-use, containerized environment for data analysis, reporting, and further application development.

## Main Features
- Fully automated setup via Docker and SQL*Plus
- Hierarchical data model with geographic, client, booking, and logistics modules
- External table loading from CSV files
- Referential integrity between all entities
- Clean restart support (safe to re-run multiple times)
- Ready for extension with stored procedures and PL/SQL logic

---

## Main Relationships
- Kontynenty → Kraje → Miasta → hierarchical structure
- Miasta → Hotele (1:N)
- Miasta → Wycieczki (1:N)
- Wycieczki → Rezerwacje (1:N)
- Klienci → Rezerwacje (1:N)
- Przewodnicy → Wycieczki (M:N)
- Wycieczki → Transport → Etapy → Przesiadki (1:N chain)
- Rezerwacje → Ubezpieczenia (M:N)

---

## Requirements
- Docker 20.10 or newer  
- Docker Compose 2.0 or newer  
- Minimum 2 GB RAM  
- 5 GB free disk space  

---

## Setup Instructions

### 1. Start the Database
```bash
docker-compose up -d
```

This will:

Pull the official Oracle XE 21c image

Start the container oracle-xe

Mount local folders with CSV and SQL scripts

Expose Oracle port 1521

2. Connect to the Database

From Docker CLI:

```bash
docker exec -it oracle-xe bash
```

```bash
sqlplus system/admin@//localhost:1521/XE
```

From any SQL client (e.g. DataGrip, DBeaver):

```yaml
Host: localhost
Port: 1521
SID: XE
User: system
Password: admin
```

## Folder Structure

```bash
project-root/
│
├── dane/                        # CSV data files
│   ├── kraje.csv
│   ├── miasta.csv
│   ├── wycieczki.csv
│   └── ...
│
├── main.sql                     # Full schema and data initialization script
├── Dockerfile                   # Oracle image setup
├── docker-compose.yml            # Docker service definition
└── README.md
```

## Data Initialization Script

The main.sql script performs the following:

Drops all existing user tables (excluding system ones)

Creates directories for external data access

Imports CSV data into external tables

Loads the data into permanent tables

Enforces all primary and foreign key constraints

Cleans up external tables after import

Commits all changes safely

All date values are parsed using the YYYY-MM-DD format.

## Example Entities

Kontynenty – list of continents

Kraje – list of countries

Miasta – list of cities (linked to countries)

Hotele – hotels in each city

Wycieczki – travel packages

Przewodnicy – tour guides

Rezerwacje – reservations with assigned clients and employees

Transport / Etapy / Przesiadki – travel logistics chain

Future Enhancements (Planned)
Stored procedures for analytics and dynamic reporting

## License
This project is released for academic and development purposes.
You may freely modify, extend, and distribute it under your own repository.