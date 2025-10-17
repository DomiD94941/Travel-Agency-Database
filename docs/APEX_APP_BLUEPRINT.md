# Oracle APEX Application Blueprint for the Travel Agency Schema

This guide describes how to build a full-featured Oracle APEX application on top of the
`sql/user/execute_on_user.sql` schema.  It walks through the required import steps,
recommends page structures, and explains how to connect APEX authentication and
business logic packages to deliver a production-ready travel agency experience.

## 1. Prerequisites
- Oracle APEX workspace with an associated schema (for example `TRAVEL_APP`).
- Access to APEX SQL Workshop and App Builder.
- Local copy of this repository so you can upload the SQL and CSV assets.

## 2. Deploy the Database Objects
1. Open **SQL Workshop → SQL Scripts**.
2. Upload `sql/user/execute_on_user.sql` and run it as the workspace schema user. The script
   recreates the entire model, seeds sample data, and compiles the helper packages required by APEX.
3. (Optional) Load additional seed data from `dane/family_bookings_sample.csv` using **Utilities →
   Data Workshop → Load Data**.  Target either a staging table or an existing reporting table such as
   `BOOKINGS`.

## 3. Configure Authentication with `travel_agency_apex`
1. Navigate to **Shared Components → Authentication Schemes** and create a new scheme using the
   **Custom** option.
2. Set the PL/SQL function body to:
   ```plsql
   RETURN travel_agency_apex.authenticate_client(
            p_username => :P101_USERNAME,
            p_password => :P101_PASSWORD);
   ```
3. Enable post-authentication processing with:
   ```plsql
   travel_agency_apex.log_successful_login(:APP_USER);
   ```
4. The helper view `APEX_CLIENT_ACCOUNTS_V` exposes the same credentials with preference metadata, so
   it can back login reports or administration pages without duplicating joins.
5. Use the packaged procedure `travel_agency_apex.set_client_password` inside an APEX form process
   whenever administrators reset client credentials from the UI.

### Default Sign-in Credentials
| Username     | Password      | Status  |
|--------------|---------------|---------|
| john.walker  | Walker#2024   | ACTIVE  |
| sofia.r      | Ramirez#2024  | ACTIVE  |
| chen.li      | Li#2024       | LOCKED  |

## 4. Recommended Application Pages
The schema already defines consistent primary keys, foreign keys, and APEX-friendly sequences.
Create the following pages via **App Builder → Create App → From a File** or **Add Page**:

| Page Type        | Source / Table                         | Key Features |
|------------------|-----------------------------------------|--------------|
| Dashboard (home) | Views `AVAILABLE_OFFERS_V`, `TOP_RATED_HOTELS_V`, `BOOKING_PARTY_SUMMARY_V` | KPIs, charts, cards |
| Clients          | Table `CLIENTS` master-detail with `CLIENT_PREFERENCES`, `TRAVELLERS` | Create / edit accounts and family members |
| Bookings         | Table `BOOKINGS` with detail regions for `BOOKING_TRAVELLERS`, `BOOKING_ROOMS`, `BOOKING_TRANSPORTS`, `BOOKING_INSURANCES`, `BOOKING_COSTS`, `BOOKING_STATUS_HISTORY`, `BOOKING_CUSTOMER_SNAPSHOTS` | Complete reservation management |
| Hotels           | Table `HOTELS` master with child grids for `HOTEL_ROOM_TYPES`, `HOTEL_ROOM_INVENTORY`, `HOTEL_ROOM_TYPE_AMENITIES` | Availability planning |
| Attractions      | Table `ATTRACTIONS` with LOVs to `GUIDES` | Activity catalogue |
| Guides           | Table `GUIDES` with embedded report of `GUIDE_LANGUAGES` | Staffing management |
| Transport        | Table `TRANSPORT_OPTIONS` | Flights, transfers, and rentals |
| Discounts        | Table `DISCOUNTS` plus `INSURANCES` | Pricing management |
| Reviews          | Table `REVIEWS` referencing hotels, attractions, and guides | Customer feedback |
| Itineraries      | Tables `ITINERARIES`, `ITINERARY_DAYS`, `ITINERARY_ACTIVITIES` | Day-by-day planner |

## 5. Wire Business Logic into Pages
- **Booking Totals:** Add a process button that calls
  `travel_agency_api.calculate_total_booking_cost(:Pxx_BOOKING_ID);` to refresh totals after editing
  room or transport rows.
- **Hotel Recommendations:** Create a modal page or dynamic action that opens a report on
  `travel_agency_api.recommend_hotel_for_booking`.  Use a `PL/SQL Dynamic Content` region that opens
  the returned cursor and displays results in a Classic Report template.
- **Itinerary Generator:** Provide a wizard page that invokes
  `travel_agency_api.generate_itinerary` using the booking ID, number of days, and rest-day toggle.
- **Account Maintenance:** Surface the `travel_agency_apex.unlock_client` procedure from an admin
  page to reinstate locked accounts directly from the UI.

## 6. Reporting & Analytics Tips
- Build interactive reports on `FAMILY_PACKAGES_V` and `AVAILABLE_OFFERS_V` for pricing snapshots.
- Use `BOOKING_PARTY_SUMMARY_V` to monitor discrepancies between stored party counts and traveller rows.
- Create pivot charts on `REVIEWS` to highlight average family suitability scores by destination.

## 7. Deployment Automation (Optional)
For CI/CD pipelines, run the following SQL*Plus block after schema deployment to ensure core data is
present and the demo logic compiles:
```bash
sqlplus travel_app/travel123@//localhost:1521/XE @sql/user/execute_on_user.sql
```
Then import the generated APEX application export (if under version control) using `sqlplus` or the
APEX UI.

With these steps, the delivered SQL schema, helper packages, and seed data translate directly into a
maintainable Oracle APEX application ready for production customization.
