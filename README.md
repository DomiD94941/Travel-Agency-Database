A **database-driven travel management platform** built with **Oracle Database 21c XE** and **PL/SQL**, designed to manage tours, clients, reservations, guides, transport, and hotels for a travel agency.  
Includes complete schema, data import automation, business logic (functions, procedures, triggers), and reporting views.

---

## 🚀 Features

✅ Complete relational database model (15 tables)  
✅ Automatic CSV data import using Oracle External Tables  
✅ 10 business functions for analytics & automation  
✅ 7 procedures for data management and workflows  
✅ 2 triggers for data integrity and event logging  
✅ 1 view for reporting (Top 10 most booked trips)  
✅ Fully Dockerized Oracle XE environment  
✅ Clean SQL structure and reusable PL/SQL logic  

---

## 🧱 Database Schema

**Main Entities:**
- 🌍 `Kontynenty`, `Kraje`, `Miasta` – geography
- 🏨 `Hotele` – hotels and locations
- 👥 `Klienci`, `Pracownicy`, `Przewodnicy` – people
- 🌴 `Wycieczki` – trips and tourism data
- 💬 `Oceny` – customer reviews
- 💰 `Rezerwacje`, `Ubezpieczenia` – bookings and insurance
- 🚌 `Transport`, `Etapy_Transportu`, `Przesiadki` – travel logistics

All tables use **foreign key relationships** to maintain data integrity.  
(See the `main.sql` file for full schema definitions.)

---

## 🐳 Docker Setup

You can run the full Oracle XE environment using Docker:

```bash
docker-compose up -d
```

Then, copy SQL files and CSV data into the container:

```bash
docker cp main.sql <container_id>:/home/oracle/
docker cp dane/ <container_id>:/opt/oracle/dane/
```

Connect to Oracle SQL*Plus:

```bash
docker exec -it <container_id> sqlplus system/oracle@localhost/XEPDB1
```

Run scripts inside the database:

```bash
@/home/oracle/main.sql
```

---

## 📦 Project Structure

📁 Travel-Management-System/
│
├── 🐳 Dockerfile
├── 🐳 docker-compose.yml
├── 🧠 main.sql                # Database schema
├── 📥 import_data.sql         # External table + data import
├── 🧩 functions.sql           # Business logic functions
├── ⚙️ procedures.sql          # Stored procedures
├── 🔔 triggers_and_views.sql  # Triggers and reporting views
├── 📚 Travel_Management_System_Description.docx
├── 📄 README.md
└── 📂 dane/                   # CSV data files

## 🧪 How to Run Locally

Clone the repository:

```bash
git clone https://github.com/<your-username>/travel-management-system.git
```

Start the Oracle container:

```bash
docker-compose up -d
```

Load the schema:

```bash
sqlplus system/oracle@localhost/XEPDB1 @main.sql
```

Import the data:

```bash
sqlplus system/oracle@localhost/XEPDB1 @import_data.sql
```
