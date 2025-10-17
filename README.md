# Oracle Travel Agency Database Project

## Overview

This project provides a complete Oracle XE 21c database setup for a travel agency management system.  
It automates the creation of all schema objects, loads data from CSV files, and initializes the environment using Docker.

The goal is to deliver a ready-to-use, containerized environment for data analysis, reporting, and further application development.

---

## Main Features

- Fully automated setup via Docker and SQL*Plus
- Hierarchical data model with geographic, client, booking, and logistics modules
- Account-level authentication stored directly on `CLIENTS` with per-booking snapshots (`BOOKING_CUSTOMER_SNAPSHOTS`) and automatic status auditing (`BOOKING_STATUS_HISTORY`) for realistic customer journeys
- `travel_agency_apex` helper package for APEX authentication, password resets, and account unlocking backed by the new `APEX_CLIENT_ACCOUNTS_V` view
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

### 2. Connect to the Database

#### 1. if you want execute scripts on system.

From Docker CLI:


```bash
docker exec -it oracle-xe bash
```

```bash
sqlplus system/admin@//localhost:1521/XE
```

```bash
@/opt/oracle/scripts/startup/system/main.sql
```

#### 2. If you want to execute scripts on created user from scritp: sql/system/create_user.sql

From user SYSTEM:

```bash
docker exec -it oracle-xe bash
```

```bash 
sqlplus system/admin@//localhost:1521/XE
```


```bash 
@/opt/oracle/scripts/startup/system/create_user.sql
```

Then logout and do from created user:

```bash
sqlplus travel_app/travel123@//localhost:1521/XE @/opt/oracle/scripts/startup/user/main.sql
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
│   ├── family_bookings_sample.csv   # 60-row dataset for testing family/group bookings
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

## Using the schema in Oracle APEX

1. In **SQL Workshop → SQL Scripts**, upload `sql/user/execute_on_user.sql` and run it as the APEX workspace schema user. The script is self-cleaning, recreates all objects, and uses `CREATE SEQUENCE` + triggers for APEX-friendly automatic numbering.
2. After the schema is created, optionally upload `dane/family_bookings_sample.csv` into a staging table or APEX collection to prototype interactive reports with a larger dataset.
3. Generate pages with **App Builder → Create App → From a File** by selecting the tables (e.g. `CLIENTS`, `BOOKINGS`, `HOTEL_ROOM_TYPES`, `ITINERARIES`). The relationships and constraints automatically appear in the Entity-Relationship Diagram for master-detail pages.
4. Use the package procedures exposed in `travel_agency_api` for interactive report actions or page processes. Parameters use SQL-friendly datatypes so they can be invoked from PL/SQL Dynamic Actions, REST Enabled SQL, or APEX Automations. New helpers such as `sync_booking_party` and `recommend_hotel_for_booking` keep traveller counts aligned and surface the best-fitting hotel rooms for each booking.
5. Configure the custom authentication scheme described in [`docs/APEX_APP_BLUEPRINT.md`](docs/APEX_APP_BLUEPRINT.md) to let `CLIENTS` sign in directly to the generated APEX app.

## Workflow Enhancements

- **User sign-in alignment:** `CLIENTS` now stores the APEX-friendly usernames, hashed passwords, and status flags, while `BOOKING_CUSTOMER_SNAPSHOTS` keeps a historical copy of the contact and preference data for each booking.
- **APEX login helpers:** The `travel_agency_apex` package centralizes credential checks, login auditing, password hashing, and administrative unlock actions for your custom authentication scheme.
- **Party management:** Trigger-driven recalculations keep `BOOKINGS.total_adults` / `total_children` synchronized with `BOOKING_TRAVELLERS`, while the `BOOKING_PARTY_SUMMARY_V` view highlights outliers for administrators.
- **Status history:** `BOOKING_STATUS_HISTORY` captures each lifecycle change via database triggers, making it easy to expose a timeline component in APEX.
- **Decision support:** `travel_agency_api.recommend_hotel_for_booking` cross-references preferences, budgets, and live availability to surface the most suitable rooms for families and groups.

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