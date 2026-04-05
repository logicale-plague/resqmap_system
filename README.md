# Project Documentation

## Project Description

**ResQMap Evacuation Center System** is a mobile-first, offline-capable disaster management application designed to support evacuation center staff in managing evacuees, tracking facility capacity, monitoring medical supplies, and coordinating information with command centers. The system operates independently of internet connectivity while maintaining a synchronization mechanism to share data with authorities once a connection is restored.

The app is built with a disaster-response focus, prioritizing speed and simplicity over feature complexity. It enables rapid evacuee registration, real-time capacity monitoring, and critical supply tracking, which are all essential functions during emergencies when communication infrastructure may be compromised.

---

## Technology Stack

<p>
	<img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
	<img alt="Dart" src="https://camo.githubusercontent.com/39a1b2892a1bc54eabc495681cdcff675dd25e97d747a980ba8042d5fb20e5a9/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446172742d3031373543323f7374796c653d666f722d7468652d6261646765266c6f676f3d64617274266c6f676f436f6c6f723d7768697465"/>
	<img alt="PostgreSQL" src="https://img.shields.io/badge/postgresql-4169e1?style=for-the-badge&logo=postgresql&logoColor=white"/>
	<img alt="Supabase" src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white">
	<img alt="SQLite" src="https://img.shields.io/badge/-SQLite-323330?style=for-the-badge&logo=sqlite&logoColor=003B57"/>
	<img alt="Mapbox" src="https://img.shields.io/badge/Mapbox-000000?style=for-the-badge&logo=mapbox&logoColor=white"/>
</p>

### Frontend & Framework
- **Flutter 3.x** — Cross-platform mobile development framework
- **Dart** — Primary programming language

### Offline-First & Local Storage
- **SQLite (sqflite v2.3.0)** — Local relational database for offline data persistence
- **Flutter Secure Storage (v9.2.4)** — Encrypted storage for sensitive credentials

### Backend & Cloud Services
- **Supabase (v2.12.0)** — Backend-as-a-service for authentication, APIs, and cloud data storage
- **PostgreSQL** — Cloud database (via Supabase)

### Mapping & Location Services
- **Mapbox Maps Flutter (v2.20.0)** — Offline-capable maps and geospatial rendering
- **Geolocator (v14.0.2)** — GPS position and location accuracy
- **Location (v8.0.1)** — Location permission and background updates

---

## Implemented Features

### Authentication & User Management
- User account creation with email/password
- Secure credential storage using encrypted local storage
- Supabase authentication integration
- Role-based access control (Staff, Admin, Public)

### Evacuation Center Management (Admin)
- **Dashboard Screen** — View overall statistics, including supply shortages and overcrowded centers
- **Center Registration** — Create and configure evacuation centers from map (online only, initial setup)
- **Center Tracking** — Real-time tracking of center status (Operational, Near Capacity, At Capacity)

### Evacuee Management (Staff)
- **Two-Step Registration System** — Log evacuee arrival with their age group (Child/Adult/Elderly), and medical condition (None/Minor/Serious). Evacuee details such as name can be edited later
- **Evacuee List View** — Display all registered evacuees with details and search capability
- **Offline Registration** — Complete registration workflow without internet connectivity

### Station Management (Staff)
- **Station Creation** — Register stations/rooms within an evacuation center
- **Station Updates** — Modify station details and capacity
- **Multi-Station Support** — Manage multiple stations/rooms with individual capacity tracking
- **Offline-Capable** — Full station management works offline

### Medical Supply Management (Staff)
- **Supply Tracking** — Monitor medical supply inventory with name, current stock, and daily usage rate
- **Stock Status Indicators** — Color-coded status (Critical/Red, Low/Orange, Adequate/Green)
- **Days Remaining Calculation** — Automatic calculation based on current stock and usage rate
- **Stock Updates** — Modify stock quantities as supplies are used or restocked

### Data Synchronization
- **Offline-First Architecture** — Staff operations work without internet
- **Automatic Sync Detection** — System detects when connectivity is restored
- **Data Upload** — Automatic upload of unsynced records to Supabase
- **Data Download** — Receive updates from command center
- **Conflict Resolution** — Automatic handling of conflicting updates
- **Sync Status Screen** — View sync history, pending updates, and last sync timestamp
- **Manual Sync Trigger** — Staff can manually initiate data synchronization

### Offline Maps (Public User - Limited)
- **Mapbox Integration** — Offline map rendering
- **GPS Location Tracking** — Display user's current location
- **Map Display** — Show evacuation center locations on map

### User Interface
- **Material 3 Design** — Modern, accessibility-focused UI
- **Responsive Layout** — Adapts to various screen sizes
- **Large Touch Targets** — Buttons optimized for quick interaction during emergencies
- **Dark Mode Support** — System theme preference support
- **Color-Coded Status Indicators** — Visual identification of critical information

### Platform Support
- **Android** — Full support with native Android 

---

## Software Architecture and Development Methodology

### Software Architecture
- **Feature-first modular structure** — The app is organized by capability under `lib/features/` rather than by shared screen type.
- **Layered feature design** — Each feature follows a layered structure with `presentation`, `application`, `domain`, and `data` folders where applicable.
- **Shared core layer** — Cross-cutting concerns, utilities, and shared services live under `lib/core/`.
- **Offline-first data flow** — Operational data is stored locally in SQLite first, then synchronized to Supabase when connectivity returns.
- **Separation of concerns** — UI rendering, business rules, and persistence are separated so each layer can evolve independently.

### Development Methodology
- **Risk-Based Incremental Delivery with Stage-Gate Verification** — Features are implemented by priority, validated continuously, and promoted only after successful integration and system-level testing.
- **Priority-driven delivery** — The project starts with the highest-impact disaster response features such as locator, capacity tracking, registration, offline storage, and sync.
- **Verification at each gate** — Each increment is checked before moving to the next priority level to reduce integration risk and keep the app stable during development.

---

## Tutorial: Testing the App (For Judges & Evaluators)

### Test Account Credentials

To evaluate different roles and features of the application, use the following test accounts. All passwords are: **`test123`**

| Role | Email | Password | Purpose |
|------|-------|----------|---------|
| Admin | `admintest@gmail.com` | `test123` | Administrative panel and system oversight |
| Staff | `stafftest@gmail.com` | `test123` | Evacuation center operations and evacuee management |
| User (Public) | `usertest@gmail.com` | `test123` | Public evacuee view and map features |

### Getting Started

1. Install the app on your test device (Android only)
2. Check your connection. The first login should be online. The subsequent login can then be done offline
3. Launch the app and tap **Login** (or **Create Account** if you need to add a test account)
4. Enter the appropriate test email and password from the table above
5. Once logged in, the app will initialize and display the role-specific interface

---

### Testing Admin Panel

**Login with:** `admintest@gmail.com` / `test123`

The admin account provides system-wide oversight and monitoring capabilities.

### Dashboard Screen
1. After login, you'll see the **Overview Page**. For now, it is a placeholder for future developments
2. At the bottom screen are the buttons **Overview**, **Centers**, and **Profile**
3. In the **Command Centers Page**, you'll see a list of command centers
4. Tap on a command center. You will be redirected to the dashboard of that command center
5. View and test:
	- **Overview Statistics** — Total evacuation centers, overcrowded centers, supply shortages
	- **Supply Shortage Details** — List of evacuation centers with supply shortages
	- **Overcrowded Centers** — List of evacuation centers with at least 80% occupancy

#### Testing Evacuation Center Registration
1. Upon entering a command center, tap **Map** at the bottom of the screen
2. Zoom in the map
3. Test adding an evacuation center:
	- Long-press on a location
	- Enter a name for the evacuation center
 	- Check the evacuation centers list and the map. It should appear in both

#### Expected Behavior
- Admin dashboard should display aggregated data from all evacuation centers
- Charts and analytics should update when new data syncs from staff centers
- System should show overall resource allocation across the facility network

---

### Testing Evacuation Center Staff Interface

**Login with:** `stafftest@gmail.com` / `test123`

The staff account simulates real-world evacuation center operations. This is the primary interface tested during deployment.

#### Dashboard Screen
1. Try the offline feature. Make sure you logged in online at least once prior to this
2. After offline login, you'll see the **Main Dashboard**
3. Tap on one of the evacuation centers
4. View and test:
   - **Total Capacity** — Maximum evacuees the center can accommodate
   - **Current Occupancy** — Number of registered evacuees
   - **Occupancy Rate** — Percentage of capacity used
   - **Status Badge** — Shows center status (Operational, Near Capacity, At Capacity)
   - **Quick Action Buttons** — For adding evacuees, managing supplies, etc.

#### Testing Evacuee Registration (Offline Capability)
1. Tap **Add Evacuee** button
2. Fill in the registration form:
   - **Age Group** — Select Child, Adult, or Elderly
   - **Medical Condition** — Select None, Minor, or Serious
   - Register the name of the evacuee later in the **View Evacuees**
3. Tap **Save** — Evacuee is registered immediately offline
4. Return to dashboard and verify occupancy increased
5. Repeat multiple times to test capacity tracking

#### Testing Evacuee Management
1. Tap **View Evacuees** button
2. Verify all registered evacuees are listed with:
   - Name (if not provided, it is blank)
   - Age group and medical condition
   - Registration timestamp
3. You can choose to edit an evacuee
   - Tap on the edit button at the right
   - Try changing the details, especially the age group and medical condition
   - Doing so should change what the station assignment shows

#### Testing Station/Room Management
1. Tap **Stations** button
2. Try adding station online and offline. It should warn you if you are offline
3. Test adding a new station:
   - Tap **Add Station**
   - Enter station name (e.g., "Main Hall", "Gymnasium", "Cafeteria")
   - Enter station capacity
   - Tap **Save**
4. Test viewing station details:
   - Tap on any station
   - View current occupancy and capacity
   - See list of evacuees assigned to that station
5. Repeat to create multiple stations and distribute evacuees

#### Testing Medical Supply Tracking
1. Tap **View Supplies** button
2. Examine the **Supplies Screen**:
   - **Supply Name** — Type of medical supply
   - **Current Stock** — Quantity available
   - **Daily Usage Rate** — How much is consumed per day
   - **Days Remaining** — Automatically calculated (stock ÷ daily usage)
   - **Status Indicator** — Color-coded (Red = Critical, Orange = Low, Green = Adequate)
3. Test adding supplies:
   - Tap **Add Supply**
   - Enter: Supply name, initial stock, daily usage rate
   - Tap **Save**
4. Test updating supplies:
   - Tap on a supply entry
   - Modify stock quantity (simulate usage)
   - Update usage rate if needed
   - Tap **Update**
5. Observe status colors changing as stock decreases

#### Testing Data Synchronization (Offline-First)
1. Tap **Sync** or **View Sync Status** button
2. Examine the **Sync Screen**:
   - **Connection Status** — Shows "Online" or "Offline"
   - **Pending Updates** — Number of unsynced local records
   - **Last Sync Time** — Timestamp of most recent sync
3. **To Test Offline Registration** (Primary Feature):
   - Turn off device WiFi and mobile data
   - Add 5-10 evacuees using the registration screen
   - Add or update 2-3 supplies
   - Verify data is saved locally (check dashboard occupancy)
   - Connection status should show "Offline"
4. **To Test Sync When Online**:
   - Turn WiFi or mobile data back on
   - Return to Sync Screen
   - Tap **Upload to Command Center** (manual sync)
   - Observe pending updates count decrease
   - Last sync time should update
   - All records should be marked as synced once complete
5. **Verify Offline-First Behavior**:
   - All operations should work smoothly whether online or offline
   - Data entry should never be blocked by connectivity
   - Sync should occur automatically in background when online

#### Testing Evacuation Scenario (Complete Workflow)
1. Start with staff account logged in
2. Simulate an evacuation:
   - Add 20-30 evacuees with varied age groups and medical conditions
   - Create 3-4 stations/rooms
   - Distribute evacuees across stations
   - Set up medical supplies (first aid kits, medications, bandages)
   - Reduce supply quantities to trigger critical/low status

3. Test offline operations:
   - Disable connectivity
   - Register additional evacuees
   - Update supply usage
   - Note that all changes happen instantly and locally

4. Test sync:
   - Enable connectivity
   - Trigger sync to send all changes to command center
   - Verify sync completes successfully
   - All records should show as synced

---

### Testing Public User Interface

**Login with:** `usertest@gmail.com` / `test123`

The public user account simulates evacuees or citizens seeking shelter information.

#### Public User Features to Test
1. **Evacuation Center Locator**
   - View list of nearby evacuation centers
   - See center names, locations, and current capacity status
   - View color-coded availability (Green = Available, Orange = Near Full, Red = Full)

2. **Map Interface**
   - **Location Display** — Blue dot shows user's current position
   - **Center Markers** — Color-coded by capacity status
   - **Tap Center** — View center name and most recent capacity status

3. **Center Details**
   - Tap a center to see full information:
     - Center name and location
     - Current capacity status
     - Last data update timestamp
     - Available facilities (medical services indicator)
   - Tap **Navigate** to open directions to the center

4. **Offline Map Usage**
   - Disable connectivity
   - Verify map still displays (uses offline tiles)
   - Verify center locations still show
   - Tap centers to see cached capacity information
   - Re-enable connectivity to fetch latest updates

---

## Contributors

- logicale-plague (backend, QA)
- Maruuu1101110 (backend, services)
- way2donatt, Ozanii (frontend)
- banm1do (documentation)

---
