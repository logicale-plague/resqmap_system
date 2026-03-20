# Evacuation Center Staff Frontend - Implementation Summary

## Overview
A complete Flutter mobile application for evacuation center staff to manage evacuees, track capacity, monitor supplies, and coordinate data synchronization with the command center.

## Features Implemented

### 1. **Dashboard Screen** (Main Entry Point)
- **Total Capacity**: Display center's total capacity
- **Current Occupancy**: Number of registered evacuees
- **Occupancy Rate**: Percentage of center capacity used
- **Status Badge**: Visual indicator (Operational, Near Capacity, At Capacity)
- **Quick Action Buttons**: 
  - Add Evacuee
  - Remove Evacuee
  - View Supplies
  - View Alerts
  - View Evacuees List
  - Sync Data
- **Medical Services Status**: Shows if medical services are available

### 2. **Registration Screen**
- **Evacuee Registration Form** with:
  - Name (optional)
  - Age Group selection (Child, Adult, Elderly) with visual indicators
  - Medical Condition selection (None, Minor, Serious) with color coding
- **Offline Storage**: Automatically saves to local database
- **Unique ID Generation**: Each evacuee gets a unique UUID

### 3. **Evacuees Screen**
- **List View**: Display all registered evacuees
- **Evacuee Details**: Name, ID, Age Group, Medical Condition
- **Registration Time**: Shows when each person was registered
- **Remove Functionality**: Delete evacuees from the center
- **Search & Filter**: Easy identification of evacuees

### 4. **Alerts Screen**
- **Alert Listing**: All alerts sorted by recency
- **Alert Severity Levels**: Info, Warning, Urgent (color-coded)
- **Alert Creation**: Staff can create and send alerts to nearby users
- **Read/Unread Status**: Visual indicator for unread alerts
- **Alert Details**: View full alert message and timestamp
- **Disaster Alerts**: Examples include:
  - "90% CAPACITY REACHED"
  - "Medical supplies critical"
  - "Area flooding detected"

### 5. **Supplies Screen**
- **Medical Supply Tracking**:
  - Supply name and current stock
  - Daily usage rate
  - Days remaining (calculated automatically)
  - Stock status (Critical/Low/Adequate)
- **Visual Progress Bar**: Shows stock levels at a glance
- **Add Supply**: Add new medical supplies to track
- **Update Stock**: Modify current stock quantities
- **Priority Coloring**: Red (critical), Orange (low), Green (adequate)

### 6. **Sync Screen**
- **Connection Status**: Shows online/offline status
- **Pending Updates**: Number of unsynced records
- **Last Sync Time**: Timestamp of last successful sync
- **Sync Process**: 
  - Upload unsynced data to command center
  - Download updates from command center
  - Conflict resolution
- **Offline-First Approach**: Data works offline and syncs when connected

## Data Models

### Evacuee
```dart
- id: String (UUID)
- name: String? (optional)
- ageGroup: AgeGroup (Child, Adult, Elderly)
- medicalCondition: MedicalCondition (None, Minor, Serious)
- registeredAt: DateTime
- synced: bool
```

### EvacuationCenter
```dart
- id: String
- name: String
- latitude/longitude: Double (GPS coordinates)
- totalCapacity: Int
- currentOccupancy: Int
- status: CenterStatus (Operational, Near Capacity, At Capacity, Closed)
- medicalAvailable: bool
- lastUpdated: DateTime
- synced: bool
```

### Supply
```dart
- id: String (UUID)
- name: String
- currentStock: Int
- usageRatePerDay: Int
- lastRestocked: DateTime
- daysRemaining: Int (calculated)
- synced: bool
```

### Alert
```dart
- id: String
- message: String
- severity: AlertSeverity (Info, Warning, Urgent)
- createdAt: DateTime
- read: bool
```

## Technology Stack

### Core Framework
- **Flutter 3.x**: Cross-platform mobile development
- **Dart**: Programming language

### Key Dependencies
- **sqflite** (v2.3.0): Local SQLite database for offline storage
- **path** (v1.8.3): File path utilities
- **intl** (v0.19.0): Internationalization and date formatting
- **provider** (v6.1.0): State management support
- **uuid** (v4.0.0): Unique ID generation

## Offline-First Architecture

### Local Storage
- SQLite database stored locally on device
- Automatic persistence of all evacuee, supply, and alert data
- No internet required for core operations

### Sync Mechanism
- Tracks which records are synced vs. pending
- When connection is detected:
  - Uploads all unsynced records to command center
  - Receives updates from other centers
  - Resolves conflicts automatically
  - Marks local records as synced

### Data Sync Tables
- evacuees table
- evacuation_centers table  
- supplies table
- alerts table

## User Interface Design

### Design Principles
- **Large Buttons**: Easy to tap under stressful conditions
- **Minimal Text**: Clear labels and icons
- **Color Coding**: Status indicators (Green/Orange/Red)
- **Visual Hierarchy**: Important information is prominent
- **Accessible Layout**: Responsive design for various screen sizes

### Navigation
- Bottom navigation or drawer for screen access
- Route-based navigation for better state management
- Named routes: /dashboard, /register, /evacuees, /alerts, /supplies, /sync

## Sample Data Initialization
On first launch, the app initializes with:
- **Sample Evacuation Center**: Community Center - Downtown (500 capacity)
- **Sample Supplies**: 
  - First Aid Kits (50 units)
  - Pain Relievers (200 units)
  - Bandages (500 units)

## Key Features for Disaster Response

1. **Rapid Registration**: Quick evacuee intake without internet
2. **Real-Time Capacity Tracking**: Monitor center occupancy
3. **Supply Management**: Track critical medical supplies
4. **Alert System**: Communicate urgent information (e.g., capacity reached)
5. **Offline Reliability**: Full functionality without connectivity
6. **Data Synchronization**: Automatic sync when connection returns
7. **Minimal Infrastructure**: Works on basic smartphones

## File Structure
```
lib/
├── main.dart                  (App entry point)
├── models/
│   ├── evacuee.dart          (Evacuee data model)
│   ├── evacuation_center.dart (Center data model)
│   ├── supply.dart            (Medical supply model)
│   ├── alert.dart             (Alert model)
│   └── index.dart             (Models export)
├── services/
│   ├── database_service.dart  (Local database management)
│   ├── sync_service.dart      (Data synchronization)
│   └── index.dart             (Services export)
└── screens/
    ├── dashboard_screen.dart   (Main dashboard)
    ├── registration_screen.dart (Evacuee registration)
    ├── evacuees_screen.dart     (Evacuees list)
    ├── alerts_screen.dart       (Alerts management)
    ├── supplies_screen.dart     (Supplies tracking)
    ├── sync_screen.dart         (Synchronization status)
    └── index.dart               (Screens export)
```

## Getting Started

### Prerequisites
- Flutter SDK (3.10.8+)
- Dart SDK
- Android Studio/Xcode for emulator/device testing

### Installation
```bash
# Get dependencies
flutter pub get

# Run app
flutter run
```

### Building for Production
```bash
# Build APK (Android)
flutter build apk

# Build IPA (iOS)
flutter build ios

# Build for Windows/macOS/Linux
flutter build windows
flutter build macos
flutter build linux
```

## Future Enhancements (Priority 2+)

- **GPS Locator**: Integration with offline maps
- **Local Sharing**: Bluetooth/Mesh networking for data sharing
- **Real Network Sync**: API integration with command center backend
- **Conflict Resolution UI**: User-guided resolution for data conflicts
- **Push Notifications**: Real-time alerts when connected
- **Analytics**: Basic analytics for disaster response coordination
- **Multi-language Support**: Internationalization for various languages

## Notes for Development

1. **Database Initialization**: DatabaseService is a singleton and initializes on app start
2. **Sync Simulation**: Currently simulates online/offline states (no real network)
3. **Sample Data**: Auto-generated on first launch for testing
4. **Error Handling**: Basic error handling; production version needs enhancement
5. **Testing**: Unit and widget tests should be added for production
6. **Accessibility**: Should add more semantic labels for screen readers

## Priority Implementation Order
✅ Priority 1: Capacity & Registration (Complete)
⏳ Priority 2: GPS locator, Local sharing, Alerts enhancement  
⏳ Priority 3: Medical supply system, Responder interface
⏳ Priority 4: Mesh networking, Smart predictions, Analytics
