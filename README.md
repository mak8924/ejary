# EJARY – Property Management System

EJARY is a Flutter-based property and rental management application designed to help property owners and managers organize properties, departments, units, tenants, rental contracts, services, dues, and payments through a centralized application.

The project uses a local SQLite database and follows a feature-based architecture with clear separation between application layers. It supports Arabic and English interfaces, as well as light and dark themes.

The application is being developed in stages, with a focus on maintaining existing functionality, data integrity, and a consistent user experience.

---

## 1. Overview

**Project Name:** EJARY  
**Platform:** Flutter  
**Application Type:** Property and Rental Management System  
**Database:** SQLite  
**Architecture:** Feature-based Clean Architecture  
**State Management:** GetX  
**Supported Languages:** Arabic and English  

EJARY aims to simplify everyday property management operations by providing tools to manage property information, rental units, tenant records, contracts, services, financial dues, and payment records.

The application is designed for local use with a SQLite database, without requiring a remote server for its current core functionality.

---

## 2. Key Features & Implemented Modules

The following modules form the application's core functionality.

### 2.1 Properties Management

- Create and manage property records.
- Store property names, types, addresses, and descriptions.
- Organize properties and their related departments and units.
- View and manage property information.

### 2.2 Departments Management

- Create departments within properties.
- Associate departments with their parent properties.
- Manage department information.
- Organize units by property and department.

### 2.3 Units Management

- Create and manage rental units.
- Associate units with properties and departments.
- Store unit details, including unit number, type, floor, area, and monthly rent.
- Track unit availability and occupancy status.
- Preserve the existing unit maintenance status field.

### 2.4 Tenants & Contracts Management

- Manage tenant information.
- Store tenant names, contact information, and related details.
- Create and manage rental contracts.
- Associate contracts with tenants and units.
- Record contract numbers, start dates, end dates, rent amounts, deposits, and contract status.
- Maintain relationships between tenants, contracts, and rental units.

### 2.5 Services Management

- Manage the service catalog.
- Define service names, descriptions, billing periods, and default amounts.
- Enable or disable services.
- Assign services to rental contracts.

**Important pricing behavior:**

The default amount in the service catalog is separate from the amount assigned to an existing contract service. Updating a service's default amount affects future assignments only. Existing contract service amounts remain unchanged unless explicitly edited.

### 2.6 Dues & Payments Management

- Manage financial dues associated with rental contracts.
- Record payment transactions.
- Associate payments with tenants and contracts.
- Allocate payments to individual dues.
- Track unpaid, partially paid, and paid dues.
- Calculate outstanding balances.
- Identify overdue dues based on their due dates.
- Maintain payment allocation records.

Overdue balances are calculated from outstanding dues whose due dates have passed. They are not stored as a separate database status.

### 2.7 Home & Navigation

- Provide a centralized entry point to the application's modules.
- Navigate between the main management screens.
- Access application settings.
- Support theme and language preferences.
- Provide access to the existing PIN-related navigation and security screens.

### 2.8 Audit Logs & Reports — Stage 9

Stage 9 introduces audit logging and reporting functionality.

Implemented work includes:

- An Audit Logs screen.
- Searching and filtering audit records.
- Viewing audit record details.
- Recording supported operations across implemented modules.
- A Reports screen displaying property, contract, and financial summaries.
- Report calculations based on existing SQLite records.
- PDF report generation and printing functionality.

Audit logging covers implemented operations such as supported record creation, updates, deletions, activation or deactivation, payments, allocations, and service assignments.

The final behavior and coverage of these features remain subject to application-level verification.

### 2.9 Dashboard & Final Refinement — Stage 10

Stage 10 focuses on improving the Home experience and completing the application's final refinement.

Work includes:

- Dashboard-style summary metrics.
- Property, unit, tenant, and active contract statistics.
- Financial summary information.
- Quick Access navigation to important application modules.
- Access to Audit Logs and Reports.
- Theme and language settings.
- Navigation to the existing PIN change screen.
- User interface and usability improvements.

Stage 10 is in progress and should not be considered fully completed until its remaining implementation and manual verification are finished.

---

## 3. Deferred Stages & Scope Notes

The project is being developed according to a defined scope and implementation plan.

### Stage 7 — Maintenance Management

Maintenance Management is deferred.

The existing SQLite table is retained:

- `maintenance_requests`

The existing unit maintenance status field is also preserved.

Deferring this stage does not mean removing its database structures or changing existing unit data.

### Stage 8 — Attachments Management

Attachments Management is deferred.

The existing SQLite table is retained:

- `attachments`

The table remains available in the database schema for possible future implementation.

### Database Preservation

Stages 7 and 8 are deferred without introducing database schema or version changes.

The existing database structure and stored records must remain intact. Deferred functionality should not be represented as fully implemented application functionality.

---

## 4. Architecture & Tech Stack

### 4.1 Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Application programming language |
| GetX | State management, dependency injection, and navigation |
| SQLite | Local relational database |
| sqflite | SQLite database integration |
| shared_preferences | Local application preferences |
| flutter_secure_storage | Secure local storage support |
| cryptography | Cryptographic functionality |
| pdf | PDF document generation |
| printing | PDF preview and printing |
| flutter_localizations | Flutter localization support |

### 4.2 Architecture

The project follows a feature-based Clean Architecture approach.

The application separates functionality into features and organizes responsibilities into distinct layers.

A typical feature structure includes:

```text
lib/
├── core/
│   ├── database/
│   ├── services/
│   ├── theme/
│   ├── translations/
│   └── ...
├── features/
│   ├── properties/
│   │   ├── data/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── bindings/
│   │       ├── controllers/
│   │       └── screens/
│   ├── tenants_contracts/
│   ├── services/
│   ├── dues_payments/
│   ├── audit_reports/
│   └── ...
├── app/
│   ├── routes/
│   └── ...
└── main.dart
```

This is a representative architectural overview. Feature folders and files may differ depending on the requirements of each module.

### 4.3 Architectural Responsibilities

**Data Layer**
- Handles local database operations.
- Implements repository functionality.
- Retrieves and stores application records.

**Domain Layer**
- Defines business entities.
- Defines repository contracts.
- Separates business requirements from implementation details.

**Presentation Layer**
- Contains application screens and user interfaces.
- Uses GetX controllers to manage screen state.
- Handles navigation and user interactions.

### 4.4 Database

EJARY uses SQLite for local data persistence.

The database includes the following main tables:

| Table | Purpose |
|---|---|
| `properties` | Property information |
| `departments` | Property departments |
| `units` | Rental units |
| `tenants` | Tenant information |
| `contracts` | Rental contracts |
| `services` | Service catalog |
| `contract_services` | Services assigned to contracts |
| `dues` | Contract financial dues |
| `payments` | Payment transactions |
| `payment_allocations` | Payment-to-due allocations |
| `maintenance_requests` | Reserved maintenance data |
| `attachments` | Reserved attachment data |
| `audit_logs` | Audit records |

The database uses foreign-key relationships to maintain data integrity.

**Database version:** 1

No database schema or version changes are intended as part of the deferred Maintenance and Attachments stages.

---

## 5. Assets & Localization

### 5.1 Localization

EJARY supports two interface languages:

- Arabic (`ar`)
- English (`en`)

The application uses Flutter localization support and GetX translations to display translated interface text.

The selected language is stored in application preferences.

### 5.2 Themes

The application supports:

- Light theme
- Dark theme
- System theme

The selected theme is managed through application preferences.

### 5.3 Font Assets

The project includes bundled Arial font assets for PDF report generation.

Expected asset structure:

```text
assets/
└── fonts/
    ├── arial.ttf
    └── arialbd.ttf
```

These assets are declared in `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/fonts/arial.ttf
    - assets/fonts/arialbd.ttf
```

The font files must exist at the specified paths and contain valid font data.

---

## 6. Project Status

EJARY is under active development.

The following table summarizes the current implementation scope.

| Stage | Module | Status |
|---|---|---|
| Core | Properties Management | Implemented and stabilized |
| Core | Departments Management | Implemented and stabilized |
| Core | Units Management | Implemented and stabilized |
| Core | Tenants & Contracts | Implemented and stabilized |
| Core | Services Management | Implemented and stabilized |
| Core | Dues & Payments | Implemented and stabilized |
| Core | Home & Navigation | Implemented |
| Stage 7 | Maintenance Management | Deferred |
| Stage 8 | Attachments Management | Deferred |
| Stage 9 | Audit Logs & Reports | Implemented; verification ongoing |
| Stage 10 | Dashboard & Final Refinement | In progress |

### Current Development Priorities

- Complete Stage 9 verification.
- Verify audit records and entity identifiers.
- Verify report calculations against actual database records.
- Test PDF generation and printing on supported platforms.
- Complete Stage 10 dashboard refinements.
- Verify navigation, localization, and theme behavior.
- Run static analysis and automated tests.
- Perform final manual testing across the main application modules.

The status of individual features may change as development and verification continue.

---

## 7. Setup & Running Instructions

### 7.1 Prerequisites

Before running the project, install:

- Flutter SDK
- Dart SDK (included with Flutter)
- Android Studio or Visual Studio Code
- Android SDK and an Android emulator, or a connected Android device
- Git (optional, for version control)

Verify the Flutter installation:

```bash
flutter doctor
```

### 7.2 Clone the Repository

If the project is hosted on GitHub, clone it using:

```bash
git clone https://github.com/mak8924/ejary.git
```

Navigate into the project directory:

```bash
cd ejary
```

Replace `<repository-url>` with the actual repository URL.

### 7.3 Install Dependencies

Run:

```bash
flutter pub get
```

This command downloads the dependencies specified in `pubspec.yaml`.

### 7.4 Verify Font Assets

Ensure that the following files exist:

```text
assets/fonts/arial.ttf
assets/fonts/arialbd.ttf
```

If the font files are missing, PDF report generation may fail when the application attempts to load them.

### 7.5 Check Connected Devices

List available devices:

```bash
flutter devices
```

### 7.6 Run the Application

Run on the default available device:

```bash
flutter run
```

To select a specific device:

```bash
flutter run -d <device-id>
```

Replace `<device-id>` with an ID returned by `flutter devices`.

### 7.7 Run on Android

To run the application on an Android emulator or connected Android device:

```bash
flutter run
```

Ensure that the Android device or emulator is available and recognized by Flutter.

---

## 8. Testing & Verification

Testing is an important part of the EJARY development process.

The project uses Flutter's standard testing and analysis commands.

### 8.1 Static Code Analysis

Run:

```bash
flutter analyze
```

This checks the project for errors, warnings, and lint issues.

The expected result is:

```text
No issues found!
```

### 8.2 Automated Tests

Run:

```bash
flutter test
```

This executes the project's automated tests.

All tests should pass before considering a code change verified.

### 8.3 Formatting

Format the Dart source code:

```bash
dart format .
```

### 8.4 Manual Testing

In addition to automated checks, manually verify the following:

**Core Management**
- Create, view, update, and delete supported records.
- Verify relationships between properties, departments, units, tenants, and contracts.
- Verify service assignments and pricing behavior.
- Verify dues, payments, and payment allocations.
- Verify outstanding and overdue calculations.

**Audit Logs**
- Verify that supported operations create the expected audit records.
- Check action types, entity types, entity IDs, and descriptions.
- Verify searching, filtering, and record details.

**Reports**
- Compare displayed report values with actual database records.
- Verify property, contract, and financial summaries.
- Test PDF generation and printing.
- Verify Arabic and English report output.

**Dashboard & Navigation**
- Verify dashboard metrics.
- Test Quick Access navigation.
- Verify access to Audit Logs and Reports.
- Test theme switching and language switching.
- Verify PIN-related navigation.

**Application Stability**
- Confirm that existing data remains available after restarting the application.
- Check that deferred modules have not caused unintended changes.
- Verify that no database schema or version changes have been introduced unintentionally.

### 8.5 Recommended Verification Sequence

Run the following commands before submitting changes:

```bash
dart format .
flutter analyze
flutter test
```

Then run the application:

```bash
flutter run
```

Finally, perform manual testing on the relevant screens and workflows.

---

## 9. Development Scope & Data Integrity Notes

The following rules guide ongoing development:

- Preserve existing database records and relationships.
- Avoid unnecessary database schema and version changes.
- Keep deferred functionality separate from completed functionality.
- Maintain the distinction between service catalog default prices and existing contract service prices.
- Preserve paid, allocated, and historical dues when synchronizing contract services.
- Calculate overdue balances using due dates and outstanding amounts.
- Ensure audit records reference the correct affected entity.
- Avoid unrelated changes when fixing individual features.
- Verify changes with formatting, static analysis, automated tests, and manual testing.

---

## 10. Future Work

Potential future development includes:

- Completing the Dashboard and final refinement stage.
- Completing verification of Audit Logs and Reports.
- Further improving report presentation and printing.
- Implementing Maintenance Management when the project scope is reopened.
- Implementing Attachments Management when the project scope is reopened.
- Additional usability and performance improvements.

These items should not be interpreted as completed features unless they are implemented and verified.

---

## License

No open-source license has been specified for this project yet.

Until a license is added to the repository, all rights remain with the project owner.

---

**EJARY – Property Management System**  
*Organizing properties, managing rentals, and simplifying daily operations.*
