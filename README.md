# Kalig-Onan Evacuation Center System

A mobile, offline-first disaster management system that helps evacuation centers track capacity, manage evacuees, monitor medical supplies, and coordinate with responders, while syncing data to authorities once connectivity is restored.

==============================================================================================

## Developer Roles:
### Logicale-Plague
- Improve app functionality and runtime, app testing
### Maruuu
- Integration of offline maps, locators, AI
### way2donatt / Ozanii
- Frontend / improve UI UX for priority 1
### banm1do
- Pitch

==============================================================================================

## Development Priority Order:

### Priority 1
- Locator (offline preloaded maps, GPS-based positioning)
- Capacity Tracking (total capacity, current number of evacuees, status)
- Registration (name (optional), age group, medical flag (yes/no))
- Offline storage
- Synchronization when online (with resolving conflicts)
- Smart predictions
- Visual analytics
- Minimal UI

### Priority 2
- Local sharing
- Alerts
- User viewing (non-personnel)

### Priority 3
- Medical supply system

### Priority 4
- Mesh networking

==============================================================================================

## Users:

### Evacuation Center Personnel --------------------- (Priority 1)
- Manage evacuees
- Track capacity
- Monitor supplies

### Command Center ---------------------------------- (Priority 1)
- Receive synced 

### Evacuees / Public users ------------------------- (Priority 2)
- Find evacuation centers (offline maps)
- Check availability 

### Medical Suppliers / Responders ------------------ (Priority 3)
- View requests
- Deliver supplies

==============================================================================================

## Core Features:

### Offline Evacuation Center Locator
- Uses GPS + offline maps						(1)
- Shows capacity status							(1)
- Share information (from another center)		(1)

### Smart Capacity Tracking
- Auto-calculate occupancy						(1)
- Overcrowding risk prediction					(1)

### Offline registration system
- Assigns each evacuee:							(1)
	- name (optional)
	- ID
	- age group
	- medical condition

### Offline Alert System
- Alerts nearby users							(2)

### Offline Data + Sync
- Stores data locally							(1)
- Auto-sync when connection returns				(1)
- Conflict resolution							(1)

### Medical Supply Tracking
- Tracks stock levels, usage rate				(3)
- Estimates days remaining						(1)

### Supply Prediction System
- Predict needs using:							(1)
	- number of evacuees
	- age groups
	- common post-disaster diseases

### Supplier request system
- Priority levels (urgent/moderate)				(3)
- Sends when connection returns					(3)

==============================================================================================

## What the users should see

### Evacuation Center Staff (Priority 1)
- Dashboard Screen
	- Total Capacity
	- Current Occupancy
	- Status
	- Quick buttons (add, remove, check supplies)
- Registration Screen
	- ID / Name (optional)
	- Age group (child, adult, elderly)
	- Medical condition (none, minor, serious)
	- Save (offline)
- Sync Screen
	- Status (offline / synced)
	- Button (upload to command center)

### Command Center (Priority 1)
- Overview Dashboard
	- Total evacuation centers
	- Overcrowded centers
	- Supply shortages
- Resource Monitoring
	- Monitors centers' medicine supplies and capacity

### Evacuee / Public User (Priority 2)
- Home Screen
	- "Find nearest evacuation center"
	- Offline map
	- Status (available, near full, full)
- Map Screen
	- User location (blue dot)
	- Evacuation centers (color-coded by capacity, only updates when nearby if offline)
	- Tap a center (shows name, most recent capacity status)
- Center Details Screen
	- Shows when the data was last updated
	- Capacity, estimated space left, basic facilities (medical available y/n)
	- Button (navigation)
- Design Rule: BIG Buttons, MINIMAL Text, Works offline

### Medical Supplier / Responder (Priority 3)
- Requests Screen
	- List of evacuation centers (name, urgency)
	- Tap -> details
- Request Details Screen
	- Needed supplies
	- Location
	- Button (accept/deny)
- Navigation Screen
	- Map with route to center



